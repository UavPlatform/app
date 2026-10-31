import '../../widgets/flow_ui.dart';
import '../../providers/waybill_draft_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../models/waybill_draft.dart';
import 'dispatch_fees_card.dart';
import 'dispatch_checkout_card.dart';

class WaybillReview extends ConsumerWidget {
  const WaybillReview({super.key, required this.draft});
  final WaybillDraft draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String weight() => draft.value('weightMax').isEmpty
        ? '${draft.value('weightMin')} kg'
        : '${draft.value('weightMin')}–${draft.value('weightMax')} kg';
    final scope = ref.watch(waybillDraftScopeProvider);
    Widget card(String title, List<String> lines) => FlowDetailsLink(
      title: title,
      summary: lines
          .where((line) => line.trim().isNotEmpty)
          .take(2)
          .join(' · '),
      builder: (_) => FlowDetailPage(
        title: '$title详情',
        scope: scope,
        builder: (_) => FlowList(
          children: [
            for (final line in lines.where((line) => line.trim().isNotEmpty))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SelectableText(line),
                ),
              ),
          ],
        ),
      ),
    );
    Widget site(String prefix, String title) => card(title, [
      if (draft.value('$prefix.place').isNotEmpty) draft.value('$prefix.place'),
      draft.value('$prefix.site'),
      '${draft.value('$prefix.contact')} · ${draft.value('$prefix.phone')}',
      '${draft.value('$prefix.lat')}, ${draft.value('$prefix.lng')}',
      draft.value('$prefix.landing') == 'yes'
          ? '落地放货'
          : '绞盘吊放 ${draft.value('$prefix.winchMin')}–${draft.value('$prefix.winchMax')} m',
      '${draft.value('$prefix.contact')} · ${draft.value('$prefix.phone')}',
      if (draft.value('$prefix.notes').isNotEmpty) draft.value('$prefix.notes'),
    ]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        const DispatchFeesCard(),
        card('货物', [
          '${draft.value('category')} · ${weight()} · ${draft.value('count')} 件',
          '${draft.value('length')} × ${draft.value('width')} × ${draft.value('height')} cm',
          '包装：${draft.value('packaging')}',
          '吊点：${draft.value('lifting')}',
          if (draft.value('declaredValue').isNotEmpty)
            '货值：${draft.value('declaredValue')} 元',
        ]),
        site('start', '起点'),
        site('end', '终点'),
        card('时间', [
          draft.value('timeMode') == 'now'
              ? '立即出发'
              : draft.value('scheduledAt').replaceAll('T', ' '),
          if (draft.value('urgent') == 'yes') '加急',
        ]),
        DispatchCheckoutCard(draft: draft),
      ],
    );
  }
}
