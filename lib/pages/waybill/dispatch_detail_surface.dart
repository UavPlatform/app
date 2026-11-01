import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/waybill_draft_provider.dart';

ThemeData dispatchDetailTheme(ThemeData theme) => theme.copyWith(
  scaffoldBackgroundColor: const Color(0xFFF3F4F6),
  appBarTheme: theme.appBarTheme.copyWith(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF111111),
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: Color(0xFF111111),
    ),
  ),
  cardTheme: const CardThemeData(
    color: Colors.white,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1D6FE9),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFF1D6FE9)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);

Future<void> showDispatchDetailSheet(
  BuildContext context, {
  required String title,
  required String? scope,
  required WidgetBuilder builder,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) =>
      DispatchDetailSheet(title: title, scope: scope, builder: builder),
);

class DispatchDetailSheet extends ConsumerWidget {
  const DispatchDetailSheet({
    super.key,
    required this.title,
    required this.scope,
    required this.builder,
  });
  final String title;
  final String? scope;
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.75,
    ),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDCDFE6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2329),
                  ),
                ),
              ),
              IconButton(
                tooltip: '关闭',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Flexible(
          child: scope != ref.watch(waybillDraftScopeProvider)
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('账号或服务器已切换，请返回重新打开'),
                )
              : builder(context),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF2F3F5),
                  foregroundColor: const Color(0xFF333333),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('我知道了'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class DispatchDetailGroup extends StatelessWidget {
  const DispatchDetailGroup({
    super.key,
    required this.title,
    required this.values,
    this.valueColors = const {},
  });
  final String title;
  final List<(String, String)> values;
  final Map<String, Color> valueColors;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2329),
          ),
        ),
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    value.$1,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: SelectableText(
                    value.$2.isEmpty ? '未知' : value.$2,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: valueColors[value.$1] ?? const Color(0xFF1F2329),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
