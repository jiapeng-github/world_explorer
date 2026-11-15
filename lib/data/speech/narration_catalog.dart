import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../../domain/atlas_content.dart';

/// Only reviewed, bundled recordings whose source still matches are playable.
class NarrationCatalog {
  NarrationCatalog(this.tracks);
  final List<Map<String, dynamic>> tracks;

  static Future<NarrationCatalog> load() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/audio/narrations.json'),
    ) as Map<String, dynamic>;
    return NarrationCatalog(
      (json['tracks'] as List).cast<Map<String, dynamic>>(),
    );
  }

  static String fingerprint(ArticleBlock block) =>
      sha256.convert(utf8.encode('${block.title}\n${block.text}')).toString();

  String? scriptFor(AtlasArticle article, int index) {
    final block = article.blocks[index];
    for (final track in tracks) {
      if (track['articleId'] == article.id &&
          track['revision'] == article.revision &&
          track['blockId'] == block.id &&
          track['sourceHash'] == fingerprint(block) &&
          track['scriptReviewed'] == true &&
          track['script'] is String &&
          (track['script'] as String).trim().isNotEmpty) {
        return track['script'] as String;
      }
    }
    return null;
  }

  String? assetFor(AtlasArticle article, int index) {
    if (index < 0 || index >= article.blocks.length) return null;
    final block = article.blocks[index];
    for (final track in tracks) {
      final asset = track['asset'];
      if (track['articleId'] == article.id &&
          track['revision'] == article.revision &&
          track['blockId'] == block.id &&
          track['sourceHash'] == fingerprint(block) &&
          track['reviewStatus'] == 'approved' &&
          asset is String &&
          RegExp(r'^assets/audio/[a-zA-Z0-9_-]+\.mp3$').hasMatch(asset)) {
        return asset;
      }
    }
    return null;
  }

  /// Avoid switching voices halfway through an article.
  bool covers(AtlasArticle article) =>
      article.blocks.isNotEmpty &&
      List.generate(
        article.blocks.length,
        (i) => assetFor(article, i),
      ).every((asset) => asset != null);
}
