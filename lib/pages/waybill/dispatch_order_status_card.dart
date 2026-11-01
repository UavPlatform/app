import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/dispatch_order.dart';
import '../../widgets/flow_ui.dart';
import '../../widgets/dispatch_stage_progress.dart';

class DispatchOrderStatusCard extends StatelessWidget {
  const DispatchOrderStatusCard({
    super.key,
    required this.order,
    required this.title,
    this.step,
  });
  final DispatchOrder order;
  final String title;
  final int? step;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEEF5FF), Colors.white],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF1D6FE9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  order.waiting
                      ? Icons.radar_rounded
                      : Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '运单 ${shortReference(order.id)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '复制运单号',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.copy_outlined,
                            size: 14,
                            color: Color(0xFF888888),
                          ),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: order.id),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('运单号已复制')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (step != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: Color(0xFFEDF0F5)),
            const SizedBox(height: 8),
            DispatchStageProgress(current: step!),
          ],
        ],
      ),
    ),
  );
}
