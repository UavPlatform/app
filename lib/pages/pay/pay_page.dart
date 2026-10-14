// 用户收银台：发起支付后查询服务端订单状态确认结果。
// 模拟支付是否启用由服务器决定；预支付返回本身不表示已支付。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/order_api.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/data_refresh.dart';

class PayPage extends ConsumerStatefulWidget {
  final String orderNum;
  final double? quotedAmount;

  const PayPage({super.key, required this.orderNum, this.quotedAmount});

  @override
  ConsumerState<PayPage> createState() => _PayPageState();
}

class _PayPageState extends ConsumerState<PayPage> {
  OrderVo? _order;
  bool _loading = true;
  String? _error;
  bool _submitting = false;
  bool _awaitingConfirmation = false;

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
        if (widget.quotedAmount != null &&
            result.data!.totalAmount != widget.quotedAmount) {
          setState(() {
            _loading = false;
            _error = '订单金额与选定飞手的系统报价不一致，已阻止支付';
          });
          return;
        }
        setState(() {
          _order = result.data;
          _loading = false;
        });
        if (_awaitingConfirmation && result.data!.isPaymentConfirmed) {
          await _showPaymentConfirmed();
        }
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
    if (_awaitingConfirmation) {
      await _load();
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await _orderApi.payOrder(widget.orderNum);
      if (!mounted) return;
      if (result.success && result.data != null) {
        // ADR-0003: prepayId only means an order was initiated, not settled.
        _awaitingConfirmation = true;
        final verified = await _orderApi.getOrderDetail(widget.orderNum);
        if (!mounted) return;
        if (verified.success && verified.data?.isPaymentConfirmed == true) {
          await _showPaymentConfirmed();
        } else {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('尚未确认支付成功，请查询支付结果；不要重复付款')),
          );
        }
      } else {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message?.contains('openid') == true
                  ? '当前服务未启用模拟支付，且尚未完成微信身份授权，请联系平台管理员'
                  : result.message ?? '支付失败，请稍后重试',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('支付失败，请检查网络后重试')));
    }
  }

  Future<void> _showPaymentConfirmed() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('支付成功'),
        content: Text('订单 ${widget.orderNum} 已完成支付。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('好的'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收银台')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? DataRefresh(onRefresh: _load, child: _buildError())
          : DataRefresh(
              onRefresh: _load,
              scrollable: true,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _load, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final order = _order!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
              const Text(
                '应付金额',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
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
              Icon(
                Icons.info_outline,
                size: 18,
                color: AppColors.onSurfaceVariant,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '支付成功后等待飞手确认作业时间；支付结果以订单状态为准',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      order.totalAmount != null
                          ? (_awaitingConfirmation
                                ? '查询支付结果'
                                : '确认支付 ¥${order.totalAmount!.toStringAsFixed(2)}')
                          : (_awaitingConfirmation ? '查询支付结果' : '确认支付'),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
