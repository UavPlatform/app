import 'package:flutter_test/flutter_test.dart';
import 'package:uav_pilot_app/models/waybill_draft.dart';

Map<String, String> validCargo() => {
  'category': '普通',
  'weightMin': '10',
  'weightMax': '20',
  'length': '100',
  'width': '50',
  'height': '30',
  'count': '2',
  'packaging': '木箱',
  'lifting': '顶部双吊点',
};

Map<String, String> validSite(String prefix) => {
  '$prefix.lat': '27.8981',
  '$prefix.lng': '112.9193',
  '$prefix.site': '平整场地',
  '$prefix.landing': 'yes',
  '$prefix.contact': '现场联系人',
  '$prefix.phone': '13800138000',
};

void main() {
  test(
    'new five-category draft round-trips with independent endpoints and photos',
    () {
      final fields = {
        ...validCargo(),
        ...validSite('start'),
        ...validSite('end'),
        'cargo.photo.local': '/private/waybill/photo.jpg',
      };
      final draft = WaybillDraft(fields: fields, step: 3);
      fields['start.contact'] = 'changed';
      final restored = WaybillDraft.fromJson(draft.toJson());
      expect(restored.fields, draft.fields);
      expect(restored.step, 3);
      expect(restored.value('start.contact'), '现场联系人');
      expect(WaybillDraft.categories, ['普通', '易碎', '液体', '冷链', '生鲜']);
    },
  );

  test('single weight and valid range accepted; reversed range rejected', () {
    final draft = WaybillDraft(fields: validCargo());
    expect(draft.errorsFor(0), isEmpty);
    expect(draft.change('weightMax', '').errorsFor(0), isEmpty);
    expect(draft.change('weightMax', '9').errorsFor(0), contains('weightMax'));
  });

  test(
    'hazardous/legacy categories and invalid numeric inputs cannot advance',
    () {
      final draft = WaybillDraft(fields: validCargo());
      for (final category in ['危险品', 'CONSTRUCTION', '']) {
        expect(
          draft.change('category', category).errorsFor(0),
          contains('category'),
        );
      }
      for (final number in ['0', '-1', 'NaN', 'Infinity', 'abc']) {
        expect(
          draft.change('weightMin', number).errorsFor(0),
          contains('weightMin'),
        );
      }
      expect(draft.change('count', '1.5').errorsFor(0), contains('count'));
    },
  );

  test('both sites require map point, landing conditions and contact', () {
    for (final (prefix, index) in [('start', 1), ('end', 2)]) {
      final draft = WaybillDraft(fields: validSite(prefix));
      expect(draft.errorsFor(index), isEmpty);
      expect(
        draft.change('$prefix.lat', 'NaN').errorsFor(index),
        contains('$prefix.point'),
      );
      expect(
        draft.change('$prefix.lng', '181').errorsFor(index),
        contains('$prefix.point'),
      );
      expect(
        draft.change('$prefix.phone', 'abc').errorsFor(index),
        contains('$prefix.phone'),
      );
      expect(
        draft.change('$prefix.site', '').errorsFor(index),
        contains('$prefix.site'),
      );
      final winch = draft.change('$prefix.landing', 'no');
      expect(winch.errorsFor(index), contains('$prefix.winchMin'));
      expect(
        winch.change('$prefix.winchMin', '10').errorsFor(index),
        contains('$prefix.winchMax'),
      );
      expect(
        winch
            .change('$prefix.winchMin', '10')
            .change('$prefix.winchMax', '20')
            .errorsFor(index),
        isEmpty,
      );
    }
  });

  test(
    'schedule is revalidated against current time, without invented timeout',
    () {
      final now = DateTime(2026, 10, 22, 12);
      final scheduled = WaybillDraft(
        fields: {'timeMode': 'scheduled', 'scheduledAt': '2026-10-22T12:30:00'},
      );
      expect(scheduled.errorsFor(3, now: now), isEmpty);
      expect(
        scheduled.errorsFor(3, now: now.add(const Duration(hours: 1))),
        contains('scheduledAt'),
      );
      expect(
        scheduled.change('timeMode', 'now').errorsFor(3, now: now),
        isEmpty,
      );
    },
  );

  test(
    'unknown versions and invalid step indexes are rejected without resetting storage',
    () {
      expect(
        () => WaybillDraft.fromJson({'version': 2, 'fields': {}, 'step': 0}),
        throwsFormatException,
      );
      expect(
        () => WaybillDraft.fromJson({'version': 1, 'fields': {}, 'step': 7}),
        throwsFormatException,
      );
    },
  );
}
