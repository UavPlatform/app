// 模拟收银台（t29，走 t21 mock 支付通道：POST /pay/{orderNum}）。
// 开发/测试环境（wechat.pay.mock-enabled=true）下由服务端同步完成
// 订单 PENDING→PAID 状态流转；真实微信链路行为不变。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/order_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class PayPage extends ConsumerStatefulWidget {
  final String orderNum;

  const PayPage({super.key, required this.orderNum});

  @override
  ConsumerState<PayPage> createState() => _PayPageState();
}

class _PayPageState extends ConsumerState<PayPage> {
  OrderVo? _order;
  bool _loading = true;
  String? _error;
  bool _submitting = false;

  OrderApi get _orderApi => OrderApi(ref.read(httpClientProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _orderApi.getOrderDetail(widget.orderNum);
      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() {
          _order = result.data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result.message ?? '订单加载失败';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '订单加载失败';
        _loading = false;
      });
    }
  }

  Future<void> _pay() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await _orderApi.payOrder(widget.orderNum);
      if (!mounted) return;
      if (result.success && result.data != null) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('支付成功'),
            content: Text(
              '订单 ${result.data!.orderNum} 已完成支付。\n'
              '支付流水号：${result.data!.prepayId ?? '-'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('好的'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? '支付失败，请稍后重试')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支付失败，请检查网络后重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收银台')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final order = _order!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text('应付金额', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(
                order.totalAmount != null
                    ? '¥${order.totalAmount!.toStringAsFixed(2)}'
                    : '金额待定',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              _row('订单编号', order.orderNum),
              if (order.taskName != null && order.taskName!.isNotEmpty)
                _row('任务名称', order.taskName!),
              _row('订单状态', order.statusLabel),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: AppColors.onSurfaceVariant),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '开发环境模拟收银台：点击下方按钮即完成支付（mock 通道，仅 dev/test 生效）',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (order.isPending)
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _pay,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      order.totalAmount != null
                          ? '模拟支付 ¥${order.totalAmount!.toStringAsFixed(2)}'
                          : '模拟支付',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            alignment: Alignment.center,
            child: Text(
              '当前订单状态：${order.statusLabel}，无需支付',
              style: const TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
