// 飞手资料（「我的」→ 飞手资料）：查看并编辑实名信息、所在地/自我介绍与驾驶资质。
// 数据走 GET/PATCH /rider/info；身份证号只展示脱敏值，修改时才需重新填写完整号码。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/generated/openapi_models.dart';
import '../../api/rider_info_api.dart';
import '../../providers/aircraft_provider.dart';
import '../../providers/rider_info_provider.dart';
import '../../theme/app_colors.dart';

class PilotInfoPage extends ConsumerWidget {
  const PilotInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(riderInfoProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('飞手资料'),
        actions: [
          if (info.hasValue)
            TextButton(
              onPressed: () => _openEdit(context, ref, info.value!),
              child: const Text('编辑'),
            ),
        ],
      ),
      body: info.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$e', style: const TextStyle(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(riderInfoProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (vo) => RefreshIndicator(
          onRefresh: () => ref.refresh(riderInfoProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section('实名信息', [
                _row('身份证号', vo.idNumberMasked ?? '未填写'),
                _row(
                  '证件有效期',
                  vo.idExpiryDate ?? '未填写',
                  trailing: vo.idExpired == true
                      ? const _Tag('已过期', AppColors.error)
                      : null,
                ),
                _row('年龄', vo.age != null ? '${vo.age} 岁' : '未填写'),
              ]),
              const SizedBox(height: 12),
              _section('个人介绍', [
                _row('所在地', _orDash(vo.location)),
                _row('自我介绍', _orDash(vo.selfIntroduction)),
              ]),
              const SizedBox(height: 12),
              _section('驾驶资质', [
                if ((vo.qualifications ?? const []).isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('还没有登记资质，点右上角「编辑」添加机型与执照等级',
                        style: TextStyle(color: AppColors.onSurfaceVariant)),
                  ),
                ...(vo.qualifications ?? const []).map(
                  (q) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.verified_outlined, color: AppColors.success),
                    title: Text(q.modelName ?? q.modelCode ?? '机型 ${q.aircraftModelId}'),
                    subtitle: q.modelCode != null ? Text(q.modelCode!) : null,
                    trailing: _Tag(
                      q.licenseGradeLabel ?? kLicenseGradeLabels[q.licenseGrade] ?? q.licenseGrade ?? '',
                      AppColors.primary,
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  static String _orDash(String? v) => (v == null || v.trim().isEmpty) ? '未填写' : v;

  Future<void> _openEdit(BuildContext context, WidgetRef ref, ApiRiderInfoVO vo) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PilotInfoEditPage(initial: vo)),
    );
    if (saved == true) ref.invalidate(riderInfoProvider);
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
          ?trailing,
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }
}

/// 编辑页：只提交改动过的字段（PATCH 局部更新）；资质整组提交（按机型集合差异）。
class PilotInfoEditPage extends ConsumerStatefulWidget {
  final ApiRiderInfoVO initial;
  const PilotInfoEditPage({super.key, required this.initial});

  @override
  ConsumerState<PilotInfoEditPage> createState() => _PilotInfoEditPageState();
}

class _PilotInfoEditPageState extends ConsumerState<PilotInfoEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _age;
  late final TextEditingController _location;
  late final TextEditingController _intro;
  final _idNumber = TextEditingController();
  String? _idExpiry;
  late List<ApiRiderQualificationDto> _quals;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final vo = widget.initial;
    _age = TextEditingController(text: vo.age?.toString() ?? '');
    _location = TextEditingController(text: vo.location ?? '');
    _intro = TextEditingController(text: vo.selfIntroduction ?? '');
    _idExpiry = vo.idExpiryDate;
    _quals = (vo.qualifications ?? const [])
        .where((q) => q.aircraftModelId != null && q.licenseGrade != null)
        .map((q) => ApiRiderQualificationDto(
            aircraftModelId: q.aircraftModelId!, licenseGrade: q.licenseGrade!))
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(aircraftModelsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _age.dispose();
    _location.dispose();
    _intro.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final models = ref.watch(aircraftModelsProvider).models;
    String modelName(int id) {
      for (final m in models) {
        if (m.id == id) return m.displayName ?? m.modelCode ?? '机型 $id';
      }
      for (final q in widget.initial.qualifications ?? const <ApiRiderQualificationVO>[]) {
        if (q.aircraftModelId == id) return q.modelName ?? '机型 $id';
      }
      return '机型 $id';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('编辑飞手资料')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _age,
              decoration: const InputDecoration(labelText: '年龄'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                if (n == null || n < 18 || n > 80) return '请输入 18~80 之间的年龄';
                return null;
              },
            ),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: '所在地'),
              maxLength: 255,
            ),
            TextFormField(
              controller: _intro,
              decoration: const InputDecoration(labelText: '自我介绍', hintText: '飞行经验、擅长场景等'),
              maxLength: 255,
              maxLines: 3,
            ),
            TextFormField(
              controller: _idNumber,
              decoration: InputDecoration(
                labelText: '身份证号',
                hintText: widget.initial.idNumberMasked != null
                    ? '已登记 ${widget.initial.idNumberMasked}，不修改请留空'
                    : '18 位身份证号',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return RegExp(r'^\d{17}[\dXx]$').hasMatch(v.trim()) ? null : '身份证号格式不正确';
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('证件有效期'),
              subtitle: Text(_idExpiry ?? '未填写'),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickExpiry,
            ),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Text('驾驶资质', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                TextButton.icon(
                  onPressed: models.isEmpty ? null : () => _addQualification(models),
                  icon: const Icon(Icons.add),
                  label: const Text('添加'),
                ),
              ],
            ),
            if (_quals.isEmpty)
              const Text('暂无资质', style: TextStyle(color: AppColors.onSurfaceVariant)),
            ..._quals.asMap().entries.map((e) {
              final q = e.value;
              return ListTile(
                key: ValueKey('qual-${q.aircraftModelId}'),
                contentPadding: EdgeInsets.zero,
                title: Text(modelName(q.aircraftModelId)),
                subtitle: DropdownButton<String>(
                  value: q.licenseGrade,
                  isDense: true,
                  items: kLicenseGradeLabels.entries
                      .map((g) => DropdownMenuItem(value: g.key, child: Text(g.value)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _quals[e.key] = ApiRiderQualificationDto(
                        aircraftModelId: q.aircraftModelId, licenseGrade: v));
                  },
                ),
                trailing: IconButton(
                  tooltip: '移除',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _quals.removeAt(e.key)),
                ),
              );
            }),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中…' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_idExpiry ?? '') ?? now.add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) {
      setState(() => _idExpiry =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _addQualification(List<ApiAircraftModelVO> models) async {
    final held = _quals.map((q) => q.aircraftModelId).toSet();
    final candidates = models.where((m) => m.id != null && !held.contains(m.id)).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有机型都已登记')),
      );
      return;
    }
    final picked = await showModalBottomSheet<ApiAircraftModelVO>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: candidates
              .map((m) => ListTile(
                    title: Text(m.displayName ?? m.modelCode ?? ''),
                    subtitle: m.modelCode != null ? Text(m.modelCode!) : null,
                    onTap: () => Navigator.of(ctx).pop(m),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _quals.add(ApiRiderQualificationDto(aircraftModelId: picked.id!, licenseGrade: 'VLOS')));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final init = widget.initial;
    String? changed(String now, String? before) =>
        now.trim() == (before ?? '').trim() ? null : now.trim();
    final ageText = _age.text.trim();
    final dto = ApiRiderInfoDto(
      age: ageText.isEmpty || int.tryParse(ageText) == init.age ? null : int.parse(ageText),
      location: changed(_location.text, init.location),
      selfIntroduction: changed(_intro.text, init.selfIntroduction),
      idNumber: _idNumber.text.trim().isEmpty ? null : _idNumber.text.trim().toUpperCase(),
      idExpiryDate: _idExpiry == init.idExpiryDate ? null : _idExpiry,
      qualifications: _quals,
    );
    setState(() => _saving = true);
    final result = await ref.read(riderInfoApiProvider).editInfo(dto);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '保存失败')),
      );
    }
  }
}
