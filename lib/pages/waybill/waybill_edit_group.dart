import '../../models/waybill_draft.dart';

class WaybillEditGroup {
  const WaybillEditGroup(
    this.id,
    this.title,
    this.stage,
    this.section,
    this.keys, {
    this.prefix,
    this.photos,
  });
  final String id, title;
  final int stage, section;
  final Set<String> keys;
  final String? prefix, photos;

  static const cargo = [
    WaybillEditGroup('category', '货物类别', 0, 0, {'category'}),
    WaybillEditGroup('specification', '重量、尺寸与包装', 0, 1, {
      'weightMin',
      'weightMax',
      'length',
      'width',
      'height',
      'count',
      'packaging',
    }),
    WaybillEditGroup('lifting', '吊点与货值', 0, 2, {'lifting', 'declaredValue'}),
    WaybillEditGroup('cargo.photos', '货物照片', 0, 0, {}, photos: 'cargo'),
  ];
  static List<WaybillEditGroup> site(String prefix) {
    final title = prefix == 'start' ? '起点' : '终点';
    final stage = prefix == 'start' ? 1 : 2;
    return [
      WaybillEditGroup('$prefix.location', '$title位置', stage, 0, {
        '$prefix.lat',
        '$prefix.lng',
        '$prefix.point',
        '$prefix.place',
        '$prefix.placeAddress',
      }, prefix: prefix),
      WaybillEditGroup('$prefix.conditions', '$title场地与作业条件', stage, 1, {
        '$prefix.site',
        '$prefix.landing',
        '$prefix.winchMin',
        '$prefix.winchMax',
        '$prefix.notes',
      }, prefix: prefix),
      WaybillEditGroup('$prefix.contact', '$title联系人', stage, 2, {
        '$prefix.contact',
        '$prefix.phone',
      }, prefix: prefix),
      WaybillEditGroup(
        '$prefix.photos',
        '$title照片',
        stage,
        0,
        {},
        photos: prefix,
      ),
    ];
  }

  static const time = WaybillEditGroup('time', '出发时间', 3, 0, {
    'timeMode',
    'scheduledAt',
    'urgent',
  });
  static List<WaybillEditGroup> get all => [
    ...cargo,
    ...site('start'),
    ...site('end'),
    time,
  ];

  Map<String, String> errors(WaybillDraft draft) => Map.fromEntries(
    draft.errorsFor(stage).entries.where((e) => keys.contains(e.key)),
  );

  String summary(WaybillDraft draft) {
    String join(Iterable<String> values) =>
        values.where((v) => v.trim().isNotEmpty).join(' · ');
    String value(String key, [String unit = '']) =>
        draft.value(key).isEmpty ? '' : '${draft.value(key)}$unit';
    if (photos != null) {
      final count = draft.fields.entries
          .where(
            (e) => e.key.startsWith('$photos.photo.') && e.value.isNotEmpty,
          )
          .length;
      return count == 0 ? '添加照片（选填）' : '$count 张照片';
    }
    if (id == 'category') return draft.value('category');
    if (id == 'specification') {
      return join([
        draft.value('weightMin').isEmpty
            ? ''
            : '${draft.value('weightMin')}${draft.value('weightMax').isEmpty ? '' : '–${draft.value('weightMax')}'} kg',
        if ([
          'length',
          'width',
          'height',
        ].every((k) => draft.value(k).isNotEmpty))
          '${draft.value('length')} × ${draft.value('width')} × ${draft.value('height')} cm',
        value('count', ' 件'),
        value('packaging'),
      ]);
    }
    if (id == 'lifting') {
      return join([value('lifting'), value('declaredValue', ' 元')]);
    }
    if (id == 'time') {
      return join([
        if (draft.value('timeMode') == 'now') '立即出发',
        if (draft.value('timeMode') == 'scheduled')
          draft.value('scheduledAt').replaceAll('T', ' '),
        if (draft.value('urgent') == 'yes') '加急',
      ]);
    }
    if (section == 0) {
      return draft.value('$prefix.lat').isEmpty ||
              draft.value('$prefix.lng').isEmpty
          ? ''
          : '${draft.value('$prefix.lat')}, ${draft.value('$prefix.lng')}';
    }
    if (section == 2) {
      return join([value('$prefix.contact'), value('$prefix.phone')]);
    }
    return join([
      value('$prefix.site'),
      if (draft.value('$prefix.landing') == 'yes') '落地放货',
      if (draft.value('$prefix.landing') == 'no') '绞盘吊放',
      value('$prefix.notes'),
    ]);
  }
}
