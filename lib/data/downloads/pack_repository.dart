import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/atlas_content.dart';
import '../database/atlas_database.dart';

enum PackPhase { available, downloading, verifying, installed, failed }

class PackStatus {
  const PackStatus(this.phase, {this.received = 0, this.total = 0, this.error});
  final PackPhase phase;
  final int received, total;
  final String? error;
}

class PackRepository extends ChangeNotifier {
  PackRepository(this.database, {this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();
  final AtlasDatabase database;
  final Uri? baseUrl;
  final http.Client _client;
  final Map<String, PackStatus> states = {};
  final Map<String, int> _requests = {};
  final Map<String, PackStatus> _installed = {};
  Future<void> Function()? onContentChanged;
  final Set<String> bundled = {'egypt', 'china', 'brazil'};
  bool installed(String id) =>
      bundled.contains(id) || states[id]?.phase == PackPhase.installed;
  Future<void> load() async {
    for (final row in await database.rows(
      'SELECT pack_id, length(payload) AS bytes FROM pack_content',
    )) {
      states[row['pack_id'] as String] = PackStatus(
        PackPhase.installed,
        received: row['bytes'] as int,
        total: row['bytes'] as int,
      );
      _installed[row['pack_id'] as String] = states[row['pack_id']]!;
    }
    notifyListeners();
  }

  void cancel(String id) {
    _requests[id] = (_requests[id] ?? 0) + 1;
    states[id] = _installed[id] ?? const PackStatus(PackPhase.available);
    notifyListeners();
  }

  static void validatePath(String path) {
    final uri = Uri.parse(path);
    if (uri.hasScheme ||
        uri.hasAuthority ||
        path.startsWith('/') ||
        path.contains('\\') ||
        uri.pathSegments.any((p) => p == '..' || p == '.') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('内容包包含无效资源路径');
    }
  }

  Future<void> install(String id) async {
    if (baseUrl == null) throw StateError('尚未设置内容更新地址，内置内容仍可离线阅读');
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
      throw const FormatException('内容包编号无效');
    }
    final request = (_requests[id] ?? 0) + 1;
    _requests[id] = request;
    final previous = _installed[id];
    bool cancelled() => _requests[id] != request;
    states[id] = const PackStatus(PackPhase.downloading);
    notifyListeners();
    try {
      final manifestUri = baseUrl!.resolve('$id/manifest.json');
      final response = await _client
          .get(manifestUri)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw StateError('暂时无法读取内容包目录');
      final manifest = jsonDecode(utf8.decode(response.bodyBytes)) as Json;
      if (manifest['schemaVersion'] != 1 ||
          manifest['packId'] != id ||
          manifest['contentVersion'] is! String ||
          manifest['files'] is! List) {
        throw const FormatException('内容包版本或格式不兼容');
      }
      final files = List<Json>.from(manifest['files']);
      if (files.isEmpty ||
          files.any(
            (f) =>
                f['bytes'] is! int ||
                (f['bytes'] as int) < 0 ||
                f['path'] is! String ||
                f['sha256'] is! String,
          )) {
        throw const FormatException('内容包资源目录无效');
      }
      final total = files.fold<int>(0, (sum, f) => sum + (f['bytes'] as int));
      if (total > 150 * 1024 * 1024 || files.length > 500) {
        throw const FormatException('内容包超出可用范围');
      }
      var received = 0;
      final data = <String, Uint8List>{};
      for (final file in files) {
        final path = file['path'] as String;
        validatePath(path);
        if (data.containsKey(path)) throw const FormatException('内容包资源重复');
        if (cancelled()) return;
        final stream = await _client
            .send(http.Request('GET', manifestUri.resolve(path)))
            .timeout(const Duration(seconds: 30));
        if (stream.statusCode != 200) throw StateError('资源下载失败，请重试');
        final bytes = BytesBuilder();
        await for (final chunk in stream.stream.timeout(
          const Duration(seconds: 30),
        )) {
          if (cancelled()) return;
          bytes.add(chunk);
          received += chunk.length;
          if (bytes.length > (file['bytes'] as int)) {
            throw const FormatException('资源大小与目录不一致');
          }
          states[id] = PackStatus(
            PackPhase.downloading,
            received: received,
            total: total,
          );
          notifyListeners();
        }
        final value = bytes.takeBytes();
        if (value.length != file['bytes'] ||
            sha256.convert(value).toString() != file['sha256']) {
          throw const FormatException('内容校验没有通过，请重新下载');
        }
        data[path] = value;
      }
      if (cancelled()) return;
      states[id] = PackStatus(
        PackPhase.verifying,
        received: received,
        total: total,
      );
      notifyListeners();
      final articleBytes = data['articles.json'];
      if (articleBytes == null) throw const FormatException('内容包缺少文章');
      final payload = utf8.decode(articleBytes);
      final decoded = jsonDecode(payload);
      if (decoded is! Json ||
          decoded['articles'] is! List ||
          (decoded['articles'] as List).isEmpty) {
        throw const FormatException('文章格式无效');
      }
      validateContent(id, decoded, data);
      await database.transaction(() async {
        if (cancelled()) throw StateError('下载已取消');
        await database.execute('DELETE FROM pack_files WHERE pack_id=?', [id]);
        for (final entry in data.entries) {
          await database.execute('INSERT INTO pack_files VALUES (?,?,?)', [
            id,
            entry.key,
            entry.value,
          ]);
        }
        await database.execute(
          'INSERT OR REPLACE INTO pack_content VALUES (?,?,?,?,?)',
          [
            id,
            manifest['contentVersion'],
            payload,
            sha256.convert(articleBytes).toString(),
            DateTime.now().toIso8601String(),
          ],
        );
        if (cancelled()) throw StateError('下载已取消');
      });
      if (cancelled()) return;
      states[id] = PackStatus(
        PackPhase.installed,
        received: total,
        total: total,
      );
      _installed[id] = states[id]!;
      await onContentChanged?.call();
      notifyListeners();
    } catch (e) {
      if (cancelled()) return;
      final retained = _installed[id] ?? previous;
      if (retained != null) {
        states[id] = PackStatus(
          PackPhase.installed,
          received: retained.received,
          total: retained.total,
          error: '更新未完成，原有内容可以继续阅读',
        );
      } else {
        states[id] = PackStatus(
          PackPhase.failed,
          error: e.toString().replaceFirst(RegExp(r'^[^:]+: '), ''),
        );
      }
      notifyListeners();
    }
  }

  Future<void> remove(String id) async {
    if (bundled.contains(id)) throw StateError('内置内容随应用提供');
    cancel(id);
    await database.transaction(() async {
      await database.execute('DELETE FROM pack_files WHERE pack_id=?', [id]);
      await database.execute('DELETE FROM pack_content WHERE pack_id=?', [id]);
    });
    states[id] = const PackStatus(PackPhase.available);
    _installed.remove(id);
    await onContentChanged?.call();
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  static void validateContent(
    String id,
    Json payload,
    Map<String, Uint8List> files,
  ) {
    final country = AtlasCountry.fromJson(payload['country']);
    if (country.id != id) throw const FormatException('国家与内容包不匹配');
    final articles = (payload['articles'] as List)
        .map((j) => AtlasArticle.fromJson(j))
        .toList();
    final ids = articles.map((a) => a.id).toSet();
    if (ids.length != articles.length ||
        articles.any(
          (a) =>
              a.countryId != id ||
              !a.id.startsWith('$id-') ||
              a.blocks.isEmpty ||
              a.blocks.map((b) => b.id).toSet().length != a.blocks.length ||
              a.sourceUrls.isEmpty,
        )) {
      throw const FormatException('文章索引或来源有误');
    }
    if (country.sections.values.expand((v) => v).any((a) => !ids.contains(a))) {
      throw const FormatException('国家栏目引用了不存在的文章');
    }
    for (final j in payload['places'] as List? ?? []) {
      final p = AtlasPlace.fromJson(j);
      const legacyPlaces = {
        'egypt': {'giza', 'nile-delta', 'abu-simbel'},
        'china': {'great-wall', 'jiuzhaigou', 'grand-canal'},
        'brazil': {'iguazu', 'amazon', 'brasilia'},
      };
      if (p.countryId != id ||
          (!p.id.startsWith('$id-') &&
              !(legacyPlaces[id]?.contains(p.id) ?? false))) {
        throw const FormatException('地点与内容包不匹配');
      }
    }
    for (final j in payload['media'] as List? ?? []) {
      final m = MediaItem.fromJson(j);
      validatePath(m.asset);
      if (!m.id.startsWith('$id-') ||
          !files.containsKey(m.asset) ||
          m.sourceUrl.isEmpty ||
          m.license.isEmpty) {
        throw const FormatException('图片资源或许可缺失');
      }
    }
    for (final j in payload['exercises'] as List? ?? []) {
      final e = AtlasExercise.fromJson(j);
      if (e.countryId != id ||
          !e.id.startsWith('$id-') ||
          !ids.contains(e.articleId) ||
          !e.options.any((o) => o['id'] == e.answerId)) {
        throw const FormatException('互动问题引用错误');
      }
    }
  }
}
