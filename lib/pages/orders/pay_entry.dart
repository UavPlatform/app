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
/// 一旦有锁定价，订单金额缺失或不等（误差 > 0.005 元）都视为不一致。
bool payAmountMatches({
  required double? totalAmount,
  required double? quotedAmount,
}) {
  if (quotedAmount == null) return true;
  if (totalAmount == null) return false;
  return (totalAmount - quotedAmount).abs() <= 0.005;
}

String _amountText(double? value) =>
    value == null ? '-' : '¥${value.toStringAsFixed(2)}';

/// 支付入口：刷新详情 → 锁价校验 → 收银台支付 → 成功后刷新详情。
///
/// 返回 true 表示支付成功（订单已流转），供调用方决定后续提示/跳转。
///
/// 入口一开始就抓取 [NavigatorState] / [ScaffoldMessengerState] /
/// [ProviderContainer]：调用方往往是列表里的某张卡片（如应征卡片），刷新数据时
/// 卡片可能被重建卸载；之后仍用卡片自己的 context 判断 `mounted` 会把导航静默吞掉。
/// 页面级导航器与容器在整个流程中稳定存在。
Future<bool> openPayEntry(
  BuildContext context,
  WidgetRef ref, {
  required String taskNum,
  double? quotedAmount,
}) {
  return openPayEntryWith(
    navigator: Navigator.of(context),
    messenger: ScaffoldMessenger.of(context),
    container: ProviderScope.containerOf(context, listen: false),
    taskNum: taskNum,
    quotedAmount: quotedAmount,
  );
}

/// [openPayEntry] 的稳定句柄版本：调用方在任何 await 之前抓好句柄后传入。
Future<bool> openPayEntryWith({
  required NavigatorState navigator,
  required ScaffoldMessengerState messenger,
  required ProviderContainer container,
  required String taskNum,
  double? quotedAmount,
}) async {
  final notifier = container.read(taskDetailProvider(taskNum).notifier);
  await notifier.loadDetail(taskNum);
  final task = container.read(taskDetailProvider(taskNum)).task;
  if (!navigator.mounted) return false;

  if (task == null || task.orderNum == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('订单尚未生成，请稍后重试')),
    );
    return false;
  }

  final quoted = quotedAmount ?? task.quotedAmount;
  if (!payAmountMatches(totalAmount: task.totalAmount, quotedAmount: quoted)) {
    messenger.showSnackBar(
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

  final paid = await navigator.push<bool>(
    MaterialPageRoute(
      builder: (_) => PayPage(orderNum: task.orderNum!),
    ),
  );
  if (paid == true) {
    if (messenger.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('支付成功')),
      );
    }
    await notifier.loadDetail(taskNum);
    return true;
  }
  // 未支付返回也刷新一次，保证详情页状态与服务端一致（如已选定待支付）。
  await notifier.loadDetail(taskNum);
  return false;
}
