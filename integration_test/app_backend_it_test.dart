// 对接真实 backend（profile=it）的集成测试。
// 不跑 TRTC；通过生产 API 客户端验证登录 / 借还机 / 派单主路径。
//
// 前置：backend `bash tools/it/up.sh` 已就绪；或 CI 工作流拉起 it 栈。
//
//   flutter test integration_test/app_backend_it_test.dart \
//     --dart-define=IT_BASE_URL=http://127.0.0.1:8082 \
//     --dart-define=SKIP_TRTC=true

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uav_pilot_app/api/generated/openapi_models.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';
import 'package:uuid/uuid.dart';

import 'it_client.dart';
import 'it_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late ItClient client;

  setUpAll(() async {
    client = await ItClient.create();
  });

  test('种子账号 it-customer / it-pilot 可登录', () async {
    await client.clearSession();
    await client.loginUser(ItConfig.customerUser, ItConfig.password);
    expect(client.storage.getToken(), isNotEmpty);

    await client.clearSession();
    await client.loginUser(ItConfig.pilotUser, ItConfig.password);
    expect(client.storage.getToken(), isNotEmpty);
  });

  test('随机后缀注册新用户并可登录', () async {
    final suffix =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 20)}';
    final name = 'it-user-$suffix';
    await client.clearSession();
    await client.registerCustomer(name, ItConfig.password);
    await client.loginUser(name, ItConfig.password);
    expect(client.storage.getToken(), isNotEmpty);
  });

  test('飞手借机 → 还机（IT-DRONE-001）', () async {
    await client.clearSession();
    await client.loginUser(ItConfig.pilotUser, ItConfig.password);

    final catalog = await client.equipment.catalog(0);
    ApiProviderDroneVO? target;
    for (final d in catalog.items ?? const <ApiProviderDroneVO>[]) {
      if (d.serialNumber == ItConfig.droneSerial && d.borrowed == false) {
        target = d;
        break;
      }
    }
    // 若已被占用：先看本人借用记录并还机
    if (target == null) {
      final mine = await client.equipment.mine(0);
      for (final b in mine.items ?? const []) {
        if (b.drone?.serialNumber == ItConfig.droneSerial &&
            b.returnedAt == null &&
            b.borrowId != null) {
          await client.equipment.giveBack(b.borrowId!);
        }
      }
      final again = await client.equipment.catalog(0);
      for (final d in again.items ?? const <ApiProviderDroneVO>[]) {
        if (d.serialNumber == ItConfig.droneSerial && d.borrowed == false) {
          target = d;
          break;
        }
      }
    }
    expect(target?.droneId, isNotNull, reason: '应能借到 ${ItConfig.droneSerial}');

    final borrow = await client.equipment.borrow(
      target!.droneId!,
      const Uuid().v4(),
    );
    expect(borrow.borrowId, isNotEmpty);
    expect(borrow.returnedAt, isNull);

    final returned = await client.equipment.giveBack(borrow.borrowId!);
    expect(returned.returnedAt, isNotNull);
  });

  test('需求方估价→下单→模拟付定金；飞手接单到场', () async {
    await client.clearSession();
    await client.loginUser(ItConfig.customerUser, ItConfig.password);

    final draft = WaybillDraft(
      step: 4,
      fields: {
        'category': '普通',
        'weightMin': '2',
        'length': '30',
        'width': '20',
        'height': '10',
        'count': '1',
        'packaging': '纸箱',
        'lifting': '绑带',
        'timeMode': 'now',
        'start.lat': '28.2',
        'start.lng': '113.0',
        'start.site': '空地',
        'start.landing': 'yes',
        'start.contact': 'IT联系人',
        'start.phone': '13800000000',
        'end.lat': '28.2',
        'end.lng': '113.1',
        'end.site': '空地',
        'end.landing': 'yes',
        'end.contact': 'IT联系人',
        'end.phone': '13800000000',
      },
    );

    final readiness = await client.orders.readiness();
    expect(readiness.enabled, isTrue);

    final assessment = await client.orders.assess(draft);
    expect(assessment.id, isNotEmpty);
    expect(assessment.allowed, isTrue);

    final order = await client.orders.create(
      draft,
      assessment.id,
      const Uuid().v4(),
    );
    expect(order.id, isNotEmpty);

    final paid = await client.orders.pay(order.id);
    expect(paid.waiting, isTrue);

    await client.clearSession();
    await client.loginUser(ItConfig.pilotUser, ItConfig.password);

    // 确保有可用借机（接单后执行用）
    final catalog = await client.equipment.catalog(0);
    final free = (catalog.items ?? const <ApiProviderDroneVO>[])
        .where((d) => d.borrowed == false && d.droneId != null)
        .toList();
    if (free.isNotEmpty) {
      await client.equipment.borrow(free.first.droneId!, const Uuid().v4());
    }

    int? offerRevision;
    for (var page = 0; page < 10; page++) {
      final hall = await client.orders.pilotHall(page);
      for (final item in hall.items) {
        if (item.id == order.id) {
          offerRevision = item.data.offerRevision;
          break;
        }
      }
      if (offerRevision != null) break;
      if (!hall.hasNext) break;
    }
    expect(offerRevision, isNotNull, reason: '订单应出现在飞手大厅');

    final claimed = await client.orders.claim(order.id, offerRevision!);
    expect(claimed.data.assignmentVersion, isNotNull);

    final arrived = await client.orders.arrive(
      order.id,
      claimed.data.assignmentVersion!,
    );
    expect(
      arrived.arrived || arrived.preparing || arrived.transporting,
      isTrue,
    );
  });
}
