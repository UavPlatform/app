// REQ-SHIP-PUB-002 / ADR-0007: local draft only; never a backend request DTO.
class WaybillDraft {
  static const categories = ['普通', '易碎', '液体', '冷链', '生鲜'];
  static const steps = ['货物', '起点', '终点', '时间', '确认'];
  static final cloudFieldNames = <String>{
    'category',
    'weightMin',
    'weightMax',
    'length',
    'width',
    'height',
    'count',
    'packaging',
    'lifting',
    'declaredValue',
    'timeMode',
    'scheduledAt',
    'urgent',
    for (final prefix in ['start', 'end'])
      for (final field in [
        'lat',
        'lng',
        'site',
        'landing',
        'winchMin',
        'winchMax',
        'contact',
        'phone',
        'notes',
      ])
        '$prefix.$field',
  };

  WaybillDraft({Map<String, String> fields = const {}, this.step = 0})
    : fields = Map.unmodifiable(fields);

  final Map<String, String> fields;
  final int step;
  String value(String key) => fields[key] ?? '';

  // Explicit draft wire mapping. Local photos and future price/state fields are excluded.
  Map<String, String> get cloudFields => Map.fromEntries(
    fields.entries.where((entry) => cloudFieldNames.contains(entry.key)),
  );

  WaybillDraft change(String key, String value) =>
      WaybillDraft(fields: {...fields, key: value}, step: step);

  WaybillDraft atStep(int value) => WaybillDraft(fields: fields, step: value);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'step': step,
    'fields': fields,
  };

  factory WaybillDraft.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 || json['fields'] is! Map) {
      throw const FormatException('不支持的运单草稿格式');
    }
    final fields = Map<String, String>.from(json['fields'] as Map);
    final step = json['step'];
    if (step is! int || step < 0 || step >= steps.length) {
      throw const FormatException('运单步骤无效');
    }
    return WaybillDraft(fields: fields, step: step);
  }

  Map<String, String> errorsFor(int index, {DateTime? now}) {
    final errors = <String, String>{};
    void required(String key, String label) {
      if (value(key).trim().isEmpty) errors[key] = '请填写$label';
    }

    double? number(String key, String label, {bool optional = false}) {
      if (optional && value(key).trim().isEmpty) return null;
      final n = double.tryParse(value(key));
      if (n == null || !n.isFinite || n <= 0) {
        errors[key] = '$label须为大于 0 的数字';
        return null;
      }
      return n;
    }

    void range(String minKey, String maxKey, String label) {
      final min = number(minKey, '$label下限');
      final max = number(maxKey, '$label上限', optional: true);
      if (min != null && max != null && max < min) {
        errors[maxKey] = '上限不能小于下限';
      }
    }

    if (index == 0) {
      if (!categories.contains(value('category'))) {
        errors['category'] = '请选择货物类别';
      }
      range('weightMin', 'weightMax', '重量');
      for (final key in ['length', 'width', 'height']) {
        number(key, '尺寸');
      }
      final count = int.tryParse(value('count'));
      if (count == null || count <= 0) errors['count'] = '件数须为正整数';
      required('packaging', '包装说明');
      required('lifting', '吊点说明');
      number('declaredValue', '货值', optional: true);
    } else if (index == 1 || index == 2) {
      final prefix = index == 1 ? 'start' : 'end';
      final lat = double.tryParse(value('$prefix.lat'));
      final lng = double.tryParse(value('$prefix.lng'));
      if (lat == null ||
          lng == null ||
          !lat.isFinite ||
          !lng.isFinite ||
          lat < -90 ||
          lat > 90 ||
          lng < -180 ||
          lng > 180) {
        errors['$prefix.point'] = '请在地图上选择位置';
      }
      required('$prefix.site', '场地类型');
      final landing = value('$prefix.landing');
      if (landing != 'yes' && landing != 'no') {
        errors['$prefix.landing'] = '请选择能否降落';
      } else if (landing == 'no') {
        range('$prefix.winchMin', '$prefix.winchMax', '绞盘高度');
        if (value('$prefix.winchMax').trim().isEmpty) {
          errors['$prefix.winchMax'] = '请填写绞盘高度上限';
        }
      }
      required('$prefix.contact', '联系人姓名');
      final phone = value('$prefix.phone').replaceAll(RegExp(r'[\s()-]'), '');
      if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(phone)) {
        errors['$prefix.phone'] = '请填写有效联系电话';
      }
    } else if (index == 3) {
      final mode = value('timeMode');
      if (mode != 'now' && mode != 'scheduled') {
        errors['timeMode'] = '请选择出发时间';
      } else if (mode == 'scheduled') {
        final scheduled = DateTime.tryParse(value('scheduledAt'));
        if (scheduled == null || !scheduled.isAfter(now ?? DateTime.now())) {
          errors['scheduledAt'] = '请选择未来的预约时间';
        }
      }
    }
    return errors;
  }
}
