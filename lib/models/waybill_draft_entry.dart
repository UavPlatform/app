import 'waybill_draft.dart';

/// REQ-SHIP-ACCT-002: one local draft in an account/server scoped draft box.
class WaybillDraftEntry {
  const WaybillDraftEntry({
    required this.id,
    required this.draft,
    required this.updatedAt,
  });
  final String id;
  final WaybillDraft draft;
  final int updatedAt;

  String get title {
    String place(String prefix) =>
        draft.value('$prefix.place').trim().isNotEmpty
        ? draft.value('$prefix.place')
        : draft.value('$prefix.site');
    final start = place('start'), end = place('end');
    if (start.isNotEmpty || end.isNotEmpty) {
      return '${start.isEmpty ? '待选起点' : start} → ${end.isEmpty ? '待选终点' : end}';
    }
    return draft.value('category').isEmpty
        ? '未命名运单'
        : '${draft.value('category')}货物运单';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'updatedAt': updatedAt,
    'draft': draft.toJson(),
  };
  factory WaybillDraftEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'], updated = json['updatedAt'];
    if (id is! String ||
        id.isEmpty ||
        updated is! int ||
        updated < 0 ||
        json['draft'] is! Map) {
      throw const FormatException('草稿记录无效');
    }
    return WaybillDraftEntry(
      id: id,
      updatedAt: updated,
      draft: WaybillDraft.fromJson(
        Map<String, dynamic>.from(json['draft'] as Map),
      ),
    );
  }
}
