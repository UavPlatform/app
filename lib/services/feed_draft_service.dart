import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FeedDraft {
  String content;
  List<String> mediaPaths;
  DateTime savedAt;

  FeedDraft({this.content = '', this.mediaPaths = const [], DateTime? savedAt}) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {'content': content, 'mediaPaths': mediaPaths, 'savedAt': savedAt.toIso8601String()};

  factory FeedDraft.fromJson(Map<String, dynamic> json) {
    return FeedDraft(
      content: json['content'] as String? ?? '',
      mediaPaths: (json['mediaPaths'] as List<dynamic>?)?.cast<String>() ?? [],
      savedAt: json['savedAt'] != null ? DateTime.parse(json['savedAt']) : DateTime.now(),
    );
  }

  bool get isEmpty => content.isEmpty && mediaPaths.isEmpty;
}

class FeedDraftService {
  static const _key = 'feed_draft';
  final SharedPreferences _prefs;
  FeedDraftService(this._prefs);

  FeedDraft load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return FeedDraft();
    try {
      return FeedDraft.fromJson(json.decode(raw));
    } catch (_) {
      return FeedDraft();
    }
  }

  Future<void> save(FeedDraft draft) async {
    if (draft.isEmpty) { await _prefs.remove(_key); } else { await _prefs.setString(_key, json.encode(draft.toJson())); }
  }

  Future<void> clear() => _prefs.remove(_key);
}
