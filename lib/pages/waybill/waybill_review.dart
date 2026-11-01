import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/waybill_draft.dart';
import '../../providers/waybill_draft_provider.dart';
import 'dispatch_fees_card.dart';
import 'waybill_review_details.dart';

class WaybillReview extends ConsumerWidget {
  const WaybillReview({super.key, required this.draft});
  final WaybillDraft draft;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(waybillDraftScopeProvider);
    final weight = draft.value('weightMax').isEmpty
        ? '${draft.value('weightMin')} kg'
        : '${draft.value('weightMin')}–${draft.value('weightMax')} kg';
    final when = draft.value('timeMode') == 'now'
        ? '立即出发'
        : draft.value('scheduledAt').replaceAll('T', ' ');
    List<(String, String)> siteFields(String prefix) => [
      if (draft.value('$prefix.place').isNotEmpty)
        ('地点名称', draft.value('$prefix.place')),
      if (draft.value('$prefix.placeAddress').isNotEmpty)
        ('地点地址', draft.value('$prefix.placeAddress')),
      ('场地类型', draft.value('$prefix.site')),
      ('经纬度', '${draft.value('$prefix.lat')}, ${draft.value('$prefix.lng')}'),
      (
        '交付方式',
        draft.value('$prefix.landing') == 'yes'
            ? '落地放货'
            : '绞盘吊放 ${draft.value('$prefix.winchMin')}–${draft.value('$prefix.winchMax')} m',
      ),
      ('现场联系人', draft.value('$prefix.contact')),
      ('联系电话', draft.value('$prefix.phone')),
      if (draft.value('$prefix.notes').isNotEmpty)
        ('现场备注', draft.value('$prefix.notes')),
    ];
    Widget row(
      String title,
      String summary,
      IconData icon,
      Color tint,
      Color accent,
      List<(String, String)> fields,
    ) => InkWell(
      key: ValueKey('review-$title'),
      onTap: () => showWaybillReviewDetails(
        context,
        title: '$title详情',
        scope: scope,
        fields: fields,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2329),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
    const divider = Divider(
      height: 1,
      thickness: 0.5,
      indent: 56,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const DispatchFeesCard(),
        const SizedBox(height: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              row(
                '货物',
                '${draft.value('category')} · $weight · ${draft.value('count')} 件',
                Icons.inventory_2_outlined,
                const Color(0xFFE8F3FF),
                const Color(0xFF1D6FE9),
                [
                  ('货物类别', draft.value('category')),
                  ('重量与件数', '$weight · ${draft.value('count')} 件'),
                  (
                    '尺寸规格',
                    '${draft.value('length')} × ${draft.value('width')} × ${draft.value('height')} cm',
                  ),
                  ('包装方式', draft.value('packaging')),
                  ('吊点信息', draft.value('lifting')),
                  if (draft.value('declaredValue').isNotEmpty)
                    ('申报货值', '${draft.value('declaredValue')} 元'),
                ],
              ),
              divider,
              row(
                '起点',
                '${draft.value('start.place').isEmpty ? draft.value('start.site') : draft.value('start.place')} · ${draft.value('start.contact')} · ${draft.value('start.phone')}',
                Icons.my_location_outlined,
                const Color(0xFFE6F8F0),
                const Color(0xFF00B578),
                siteFields('start'),
              ),
              divider,
              row(
                '终点',
                '${draft.value('end.place').isEmpty ? draft.value('end.site') : draft.value('end.place')} · ${draft.value('end.contact')} · ${draft.value('end.phone')}',
                Icons.location_on_outlined,
                const Color(0xFFFFF0E6),
                const Color(0xFFFF6B00),
                siteFields('end'),
              ),
              divider,
              row(
                '时间',
                when,
                Icons.access_time,
                const Color(0xFFF3E8FF),
                const Color(0xFF7C3AED),
                [
                  ('出发时间', when),
                  if (draft.value('urgent') == 'yes') ('时效要求', '加急'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
