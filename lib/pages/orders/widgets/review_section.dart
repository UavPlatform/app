// 订单评价区块（用户端任务详情，订单已完成后展示）：
//   未评价 → 「评价飞手」打开评分弹窗（1~5 星 + 可选文字）→ POST /review/submit；
//   已评价 → 只读展示星级、内容与时间（后端一单一评）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/generated/openapi_models.dart';
import '../../../providers/review_provider.dart';
import '../../../theme/app_colors.dart';

class ReviewSection extends ConsumerWidget {
  final String orderNum;
  final String? riderName;

  const ReviewSection({super.key, required this.orderNum, this.riderName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderReviewProvider(orderNum));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('服务评价',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          state.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (e, _) => Row(
              children: [
                const Expanded(
                  child: Text('评价加载失败',
                      style: TextStyle(color: AppColors.onSurfaceVariant)),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(orderReviewProvider(orderNum)),
                  child: const Text('重试'),
                ),
              ],
            ),
            data: (review) => review == null
                ? _buildPending(context, ref)
                : ReviewCard(review: review),
          ),
        ],
      ),
    );
  }

  Widget _buildPending(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '订单已完成，给${riderName ?? '飞手'}的服务打个分吧',
          style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _openDialog(context, ref),
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('评价飞手'),
          ),
        ),
      ],
    );
  }

  Future<void> _openDialog(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ReviewDialog(orderNum: orderNum),
    );
    if (ok == true) {
      ref.invalidate(orderReviewProvider(orderNum));
      ref.invalidate(myReviewsProvider);
      messenger.showSnackBar(const SnackBar(content: Text('评价成功，感谢反馈')));
    }
  }
}

/// 只读评价卡片（任务详情与「我的评价」共用）。
class ReviewCard extends StatelessWidget {
  final ApiOrderReview review;
  final bool showOrderNum;

  const ReviewCard({super.key, required this.review, this.showOrderNum = false});

  @override
  Widget build(BuildContext context) {
    final rating = (review.rating ?? 0).clamp(0, 5);
    final time = (review.createTime ?? '').replaceFirst('T', ' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StarRow(rating: rating),
            const SizedBox(width: 8),
            Text('$rating 分', style: const TextStyle(fontSize: 13)),
            const Spacer(),
            if (time.length >= 16)
              Text(time.substring(0, 16),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.onSurfaceVariant)),
          ],
        ),
        if (review.content != null && review.content!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.content!, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
        if (showOrderNum && review.orderNum != null) ...[
          const SizedBox(height: 6),
          Text('订单号 ${review.orderNum}',
              style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        ],
      ],
    );
  }
}

class StarRow extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRow({super.key, required this.rating, this.size = 18, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icon = Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: const Color(0xFFFFB300),
          size: size,
        );
        if (onChanged == null) return icon;
        return InkResponse(
          key: ValueKey('review-star-${i + 1}'),
          onTap: () => onChanged!(i + 1),
          radius: size,
          child: Padding(padding: const EdgeInsets.all(2), child: icon),
        );
      }),
    );
  }
}

class _ReviewDialog extends ConsumerStatefulWidget {
  final String orderNum;
  const _ReviewDialog({required this.orderNum});

  @override
  ConsumerState<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<_ReviewDialog> {
  int _rating = 5;
  bool _submitting = false;
  String? _error;
  final _controller = TextEditingController();

  static const _ratingHints = ['', '很不满意', '不满意', '一般', '满意', '非常满意'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref.read(reviewApiProvider).submit(
          orderNum: widget.orderNum,
          rating: _rating,
          content: _controller.text,
        );
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _submitting = false;
        _error = result.message ?? '评价提交失败，请稍后重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('评价飞手'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRow(
                rating: _rating,
                size: 30,
                onChanged: _submitting ? null : (v) => setState(() => _rating = v),
              ),
              const SizedBox(width: 8),
              Text(_ratingHints[_rating],
                  style: const TextStyle(color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('review-content-field'),
            controller: _controller,
            maxLength: 200,
            maxLines: 3,
            enabled: !_submitting,
            decoration: const InputDecoration(
              hintText: '说说飞手的准时度、吊运操作和沟通（选填）',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('提交评价'),
        ),
      ],
    );
  }
}
