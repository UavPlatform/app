// 支付入口（TASK-APP-004 / ADR-0003 决定 2、3）：
//   1. 进入收银台前重新拉取任务详情，以服务端数据为准；
//   2. 锁价校验：订单 totalAmount 必须严格等于应征系统报价 quotedAmount，
//      不一致时不发起支付并提示（服务端同样拒绝，客户端先行拦截）；
//   3. 校验通过才跳转既有收银台 PayPage（金额只读展示，无任何价格输入控件）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/task_provider.dart';
import '../pay/pay_page.dart';

/// 锁价校验（ADR-0003：成交价恒等于应征系统报价）。
///
/// 无 quotedAmount 的旧订单（撮合改版前创建）没有锁定价基准，放行走既有支付流；
/// 一旦有锁定价，订单金额缺失或不等都视为不一致；两者均来自服务端，不做客户端计价。
bool payAmountMatches({
  required double? totalAmount,
  required double? quotedAmount,
}) {
  if (quotedAmount == null) return true;
  if (totalAmount == null) return false;
  return totalAmount == quotedAmount;
}

String _amountText(double? value) =>
    value == null ? '-' : '¥${value.toStringAsFixed(2)}';

/// 支付入口：刷新详情 → 锁价校验 → 收银台支付 → 成功后刷新详情。
///
/// 返回 true 表示支付成功（订单已流转），供调用方决定后续提示/跳转。
Future<bool> openPayEntry(
  BuildContext context,
  WidgetRef ref, {
  required String taskNum,
  double? quotedAmount,
}) async {
  final notifier = ref.read(taskDetailProvider(taskNum).notifier);
  await notifier.loadDetail(taskNum);
  final task = ref.read(taskDetailProvider(taskNum)).task;
  if (!context.mounted) return false;

  if (task == null || task.orderNum == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('订单尚未生成，请稍后重试')));
    return false;
  }

  final quoted = quotedAmount ?? task.quotedAmount;
  if (!payAmountMatches(totalAmount: task.totalAmount, quotedAmount: quoted)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '支付金额与应征报价不一致（应征报价 ${_amountText(quoted)}，'
          '订单金额 ${_amountText(task.totalAmount)}），已阻止支付，'
          '请刷新后重试或联系平台处理',
        ),
      ),
    );
    return false;
  }

  final paid = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => PayPage(orderNum: task.orderNum!, quotedAmount: quoted),
    ),
  );
  if (!context.mounted) return false;
  if (paid == true) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('支付成功')));
    await notifier.loadDetail(taskNum);
    return true;
  }
  return false;
}
