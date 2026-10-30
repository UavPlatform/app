import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/waybill_draft_provider.dart';

/// Shared rhythm for task pages: one block of information per card.
class FlowList extends StatelessWidget {
  const FlowList({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.controller,
    this.physics,
    this.spacing = 16,
  });
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double spacing;
  @override
  Widget build(BuildContext context) => ListView.separated(
    controller: controller,
    physics: physics,
    padding: padding,
    itemCount: children.length,
    separatorBuilder: (_, _) => SizedBox(height: spacing),
    itemBuilder: (_, index) => children[index],
  );
}

class FlowHeader extends StatelessWidget {
  const FlowHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.flight_takeoff_rounded,
    this.trailing,
  });
  final String title, subtitle;
  final IconData icon;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: scheme.onPrimary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: scheme.onPrimaryContainer,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(height: 12),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FlowNotice extends StatelessWidget {
  const FlowNotice(this.message, {super.key, this.warning = false});
  final String message;
  final bool warning;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final color = warning ? const Color(0xFFB15A12) : scheme.secondary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark
            ? scheme.surfaceContainerHigh
            : warning
            ? const Color(0xFFFFEFDB)
            : const Color(0xFFE7F3EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning
                ? Icons.info_outline_rounded
                : Icons.tips_and_updates_outlined,
            size: 19,
            color: dark ? scheme.primary : color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                height: 1.5,
                fontSize: 13,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FlowDetailsLink extends StatelessWidget {
  const FlowDetailsLink({
    super.key,
    required this.title,
    required this.summary,
    required this.builder,
    this.icon = Icons.article_outlined,
  });
  final String title, summary;
  final WidgetBuilder builder;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
        child: Icon(icon),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute<void>(builder: builder)),
    ),
  );
}

/// Detail routes must not keep another account's data visible on account switch.
class FlowDetailPage extends ConsumerWidget {
  const FlowDetailPage({
    super.key,
    required this.title,
    required this.scope,
    required this.builder,
  });
  final String title;
  final String? scope;
  final WidgetBuilder builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: scope != ref.watch(waybillDraftScopeProvider)
        ? const Center(child: Text('账号或服务器已切换，请返回重新打开'))
        : builder(context),
  );
}

String shortReference(String value) => value.length <= 12
    ? value
    : '${value.substring(0, 6)}…${value.substring(value.length - 4)}';

class FlowValue extends StatelessWidget {
  const FlowValue(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 6),
      SelectableText(
        value.isEmpty ? '未填写' : value,
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
    ],
  );
}
