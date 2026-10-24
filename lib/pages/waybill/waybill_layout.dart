import 'package:flutter/material.dart';
import '../../models/waybill_draft.dart';

const waybillBlue = Color(0xFF165DFF);

class WaybillSection extends StatelessWidget {
  const WaybillSection({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: children,
    ),
  );
}

class WaybillStepIndicator extends StatelessWidget {
  const WaybillStepIndicator({super.key, required this.step});
  final int step;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned(
            left: constraints.maxWidth / 10,
            right: constraints.maxWidth / 10,
            top: 7,
            child: LinearProgressIndicator(
              value: step / (WaybillDraft.steps.length - 1),
              color: waybillBlue,
              backgroundColor: const Color(0xFFDCE2EC),
              minHeight: 2,
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < WaybillDraft.steps.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == step,
                    child: Column(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= step
                                ? waybillBlue
                                : const Color(0xFFCCD3DF),
                            border: Border.all(
                              color: const Color(0xFFF5F7FA),
                              width: 2,
                            ),
                          ),
                          child: i < step
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 10,
                                )
                              : null,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          WaybillDraft.steps[i],
                          style: TextStyle(
                            fontSize: 12,
                            color: i <= step
                                ? waybillBlue
                                : const Color(0xFF86909C),
                            fontWeight: i == step
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class WaybillGuide extends StatelessWidget {
  const WaybillGuide({super.key, required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      gradient: const LinearGradient(
        colors: [Color(0xFFE6F0FF), Color(0xFFF0F6FF)],
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.flight_takeoff_rounded, color: waybillBlue, size: 25),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 3,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1D3659),
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF667D99),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DashedCategoryBorder extends CustomPainter {
  const DashedCategoryBorder();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    final paint = Paint()
      ..color = const Color(0xFFC9CDD4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      for (var offset = 0.0; offset < metric.length; offset += 7) {
        canvas.drawPath(metric.extractPath(offset, offset + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedCategoryBorder oldDelegate) => false;
}
