import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalog.dart';

abstract interface class ProgressStorage {
  Future<Map<String, dynamic>> read();
  Future<void> write(Map<String, dynamic> value);
}

class LocalProgressStorage implements ProgressStorage {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static const key = 'world_explorer.progress.v1';
  @override
  Future<Map<String, dynamic>> read() async {
    final value = await _preferences.getString(key);
    if (value == null) return {};
    return jsonDecode(value) as Map<String, dynamic>;
  }

  @override
  Future<void> write(Map<String, dynamic> value) =>
      _preferences.setString(key, jsonEncode(value));
}

class MemoryProgressStorage implements ProgressStorage {
  Map<String, dynamic> data = {};
  @override
  Future<Map<String, dynamic>> read() async => Map<String, dynamic>.from(data);
  @override
  Future<void> write(Map<String, dynamic> value) async {
    data = jsonDecode(jsonEncode(value));
  }
}

class Curiosity {
  const Curiosity({
    required this.id,
    required this.countryId,
    required this.text,
    required this.createdAt,
  });
  final String id, countryId, text, createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'countryId': countryId,
    'text': text,
    'createdAt': createdAt,
  };
  factory Curiosity.fromJson(Map<String, dynamic> j) => Curiosity(
    id: j['id'],
    countryId: j['countryId'],
    text: j['text'],
    createdAt: j['createdAt'],
  );
}

class ExplorerStore extends ChangeNotifier {
  ExplorerStore({required this.catalog, required this.storage});
  final Catalog catalog;
  final ProgressStorage storage;
  String nickname = '小小探险家', avatar = '🦊';
  bool onboarded = false, voiceEnabled = true;
  double textScale = 1.0, speechRate = 0.45;
  int breakMinutes = 20;
  String? lastCountryId, storageError;
  int activeTab = 0;
  final Set<String> visited = {}, favorites = {}, completed = {};
  final Set<String> readTopics = {};
  final Map<String, int> readingPositions = {}, quizPositions = {};
  final List<Curiosity> questions = [];
  DateTime sessionStarted = DateTime.now();
  Future<void> _pendingSave = Future.value();
  Future<void> load() async {
    try {
      final j = await storage.read();
      nickname = j['nickname'] as String? ?? nickname;
      avatar = j['avatar'] as String? ?? avatar;
      onboarded = j['onboarded'] as bool? ?? false;
      voiceEnabled = j['voiceEnabled'] as bool? ?? true;
      textScale = ((j['textScale'] as num?)?.toDouble() ?? 1).clamp(0.9, 1.35);
      speechRate = ((j['speechRate'] as num?)?.toDouble() ?? .45).clamp(
        .25,
        .65,
      );
      breakMinutes = (j['breakMinutes'] as int? ?? 20).clamp(5, 60);
      lastCountryId = j['lastCountryId'] as String?;
      final validTopics = catalog.countries
          .expand((c) => c.topics.map((t) => '${c.id}/${t.id}'))
          .toSet();
      readTopics.addAll(
        List<String>.from(j['readTopics'] ?? []).where(validTopics.contains),
      );
      for (final pair in [
        (visited, 'visited'),
        (favorites, 'favorites'),
        (completed, 'completed'),
      ]) {
        pair.$1.addAll(
          List<String>.from(j[pair.$2] ?? [])
              .where((id) => catalog.countries.any((c) => c.id == id)),
        );
      }
      for (final pair in [
        (readingPositions, 'readingPositions'),
        (quizPositions, 'quizPositions'),
      ]) {
        (j[pair.$2] as Map<String, dynamic>? ?? {}).forEach((key, value) {
          if (value is int) pair.$1[key] = value;
        });
      }
      questions.addAll(
        (j['questions'] as List? ?? []).map((e) => Curiosity.fromJson(e)),
      );
    } catch (_) {
      storageError = '本地记录暂时无法读取。当前可以继续探索，新记录将在下次保存时重试。';
    }
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'readTopics': readTopics.toList(),
    'nickname': nickname,
    'avatar': avatar,
    'onboarded': onboarded,
    'voiceEnabled': voiceEnabled,
    'textScale': textScale,
    'speechRate': speechRate,
    'breakMinutes': breakMinutes,
    'lastCountryId': lastCountryId,
    'visited': visited.toList(),
    'favorites': favorites.toList(),
    'completed': completed.toList(),
    'readingPositions': readingPositions,
    'quizPositions': quizPositions,
    'questions': questions.map((q) => q.toJson()).toList(),
  };
  Future<void> _save() {
    notifyListeners();
    final snapshot = jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>;
    _pendingSave = _pendingSave.then((_) async {
      try {
        await storage.write(snapshot);
        if (storageError != null) {
          storageError = null;
          notifyListeners();
        }
      } catch (_) {
        storageError = '暂时无法保存记录，请检查设备存储后重试。';
        notifyListeners();
      }
    });
    return _pendingSave;
  }

  Future<void> retrySave() => _save();
  Future<void> markTopicRead(String countryId, String topicId) {
    readTopics.add('$countryId/$topicId');
    return _save();
  }

  Future<void> saveProfile({
    required String name,
    required String selectedAvatar,
    bool? prefersVoice,
  }) {
    nickname = name.trim().isEmpty ? '小小探险家' : name.trim();
    avatar = selectedAvatar;
    onboarded = true;
    if (prefersVoice != null) voiceEnabled = prefersVoice;
    return _save();
  }

  Future<void> finishOnboarding() {
    onboarded = true;
    return _save();
  }

  Future<void> markVisited(String id) {
    visited.add(id);
    lastCountryId = id;
    return _save();
  }

  Future<void> toggleFavorite(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    return _save();
  }

  Future<void> saveReading(String id, int index) {
    readingPositions[id] = index;
    lastCountryId = id;
    return _save();
  }

  Future<void> saveQuiz(String id, int index) {
    quizPositions[id] = index;
    return _save();
  }

  Future<void> completeCountry(String id) {
    completed.add(id);
    visited.add(id);
    quizPositions.remove(id);
    lastCountryId = id;
    return _save();
  }

  Future<void> addQuestion(String text, {String? countryId}) {
    if (text.trim().isEmpty) return Future.value();
    final now = DateTime.now();
    questions.insert(
      0,
      Curiosity(
        id: now.microsecondsSinceEpoch.toString(),
        countryId: countryId ?? lastCountryId ?? 'egypt',
        text: text.trim(),
        createdAt: now.toIso8601String(),
      ),
    );
    return _save();
  }

  Future<void> deleteQuestion(String id) {
    questions.removeWhere((q) => q.id == id);
    return _save();
  }

  Future<void> updateSettings({
    double? textScale,
    double? speechRate,
    int? breakMinutes,
    bool? voiceEnabled,
  }) {
    if (textScale != null) this.textScale = textScale.clamp(.9, 1.35);
    if (speechRate != null) this.speechRate = speechRate.clamp(.25, .65);
    if (breakMinutes != null) this.breakMinutes = breakMinutes.clamp(5, 60);
    if (voiceEnabled != null) this.voiceEnabled = voiceEnabled;
    return _save();
  }

  bool get breakDue =>
      DateTime.now().difference(sessionStarted).inMinutes >= breakMinutes;
  void restartSession() {
    sessionStarted = DateTime.now();
    notifyListeners();
  }

  void setTab(int tab) {
    activeTab = tab.clamp(0, 2);
    notifyListeners();
  }

  Future<void> resetProgress() {
    visited.clear();
    readTopics.clear();
    favorites.clear();
    completed.clear();
    readingPositions.clear();
    quizPositions.clear();
    questions.clear();
    lastCountryId = null;
    return _save();
  }
}

class ExplorerScope extends InheritedNotifier<ExplorerStore> {
  const ExplorerScope({
    super.key,
    required ExplorerStore store,
    required super.child,
  }) : super(notifier: store);
  static ExplorerStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExplorerScope>()!.notifier!;
}
