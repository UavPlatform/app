// 发布完成页支付规则提示（t30①：Q1=A 托管式支付，支付后才进大厅）。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/pages/publish/publish_page.dart';

void main() {
  testWidgets('发布完成页支付规则提示清晰可见', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PublishPaymentHint())),
    );

    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('支付后任务才会进入飞手大厅'), findsOneWidget);
  });
}
