import 'package:flutter/material.dart';

class WaybillSectionSurface extends StatelessWidget {
  const WaybillSectionSurface({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.first = false,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final bool first;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(12, first ? 10 : 5, 12, 5),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF2B65D9)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 0.5,
            indent: 16,
            endIndent: 16,
            color: Color(0xFFF2F3F5),
          ),
          child,
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
}
