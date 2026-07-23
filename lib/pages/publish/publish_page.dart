import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../models/service_type_model.dart';
import '../../models/create_task_request.dart';
import '../../providers/task_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/scroll_pickers.dart';

class PublishPage extends ConsumerStatefulWidget {
  final String? serviceType;
  const PublishPage({super.key, this.serviceType});

  @override
  ConsumerState<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends ConsumerState<PublishPage> {
  int _currentStep = 0;
  ServiceType? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String? _waypointsStr;
  bool _submitting = false;
  bool _autoCalcPrice = false;

  static final _serviceTypes = [
    ServiceType(id: 'aerial_photo', name: '航拍摄影', icon: Icons.videocam, description: '活动跟拍/婚礼航拍/宣传片'),
    ServiceType(id: 'survey', name: '测绘建模', icon: Icons.map, description: '地形测绘/3D建模'),
    ServiceType(id: 'logistics', name: '物流吊运', icon: Icons.local_shipping, description: '物资吊运/设备转运'),
    ServiceType(id: 'monitoring', name: '环境监测', icon: Icons.eco, description: '空气质量/水质监测'),
  ];

  @override
  void initState() {
    super.initState();
    final typeName = widget.serviceType;
    if (typeName != null) {
      _selectedService = _serviceTypes.cast<ServiceType?>().firstWhere(
        (t) => t!.name == typeName,
        orElse: () => _serviceTypes.first,
      );
    } else {
      _selectedService = _serviceTypes.first;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_waypointsStr == null || _waypointsStr!.isEmpty) { _showError('请点击地图选择航点'); return; }
      if (_selectedDate == null || _selectedTime == null) { _showError('请选择任务时间'); return; }
      if (_descriptionController.text.isEmpty) { _showError('请输入任务描述'); return; }
      if (!_autoCalcPrice && _priceController.text.isEmpty) { _showError('请输入酬劳金额'); return; }
    }
    if (_currentStep == 1) { _submitTask(); return; }
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitTask() async {
    setState(() => _submitting = true);
    final request = CreateTaskRequest(
      taskName: _selectedService!.name,
      type: _typeId(_selectedService!.id),
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : _selectedService!.description,
      waypoints: _buildWaypoints(),
      reward: _autoCalcPrice ? null : double.tryParse(_priceController.text),
      taskTime: _selectedDate != null && _selectedTime != null
          ? '${_selectedDate!.toIso8601String().split('T')[0]} ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
    );
    final ok = await ref.read(taskProvider.notifier).createTask(request);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) { setState(() => _currentStep = 2); } else {
      _showError(ref.read(taskProvider).error ?? '创建失败');
    }
  }

  String _typeId(String id) {
    switch (id) {
      case 'aerial_photo': return 'AERIAL_PHOTO';
      case 'survey': return 'SURVEY';
      case 'logistics': return 'TRANSPORT';
      case 'monitoring': return 'MONITORING';
      default: return 'AERIAL_PHOTO';
    }
  }

  List<WaypointRequest> _buildWaypoints() {
    if (_waypointsStr != null) {
      final parts = _waypointsStr!.split(';');
      return List.generate(parts.length, (i) {
        final c = parts[i].split(',');
        return WaypointRequest(orderIndex: i, longitude: double.tryParse(c[1]) ?? 112.9193, latitude: double.tryParse(c[0]) ?? 27.8981, altitude: 100);
      });
    }
    final loc = ref.read(locationProvider);
    return [WaypointRequest(orderIndex: 0, longitude: loc.longitude ?? 112.9193, latitude: loc.latitude ?? 27.8981, altitude: 100)];
  }

  void _prevStep() {
    if (_currentStep > 0) { setState(() => _currentStep--); } else { context.pop(); }
  }

  // ---- card helper ----
  Widget _card({required List<Widget> children}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_selectedService?.name ?? '发布任务'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep),
      ),
      body: _currentStep == 2 ? _buildDone() : Stack(children: [
        IndexedStack(index: _currentStep, children: [_buildDetail(), _buildConfirm()]),
        // Bottom gradient + fixed button
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomButton()),
      ]),
    );
  }

  // ==================== Stepper ====================
  Widget _buildStepper() {
    const steps = ['任务详情', '确认信息', '发布完成'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isEven) {
          final s = i ~/ 2;
          final active = _currentStep >= s;
          return Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: active ? AppColors.primary : AppColors.outline)),
            const SizedBox(width: 4),
            Text(steps[s], style: TextStyle(fontSize: 11, color: active ? AppColors.primary : AppColors.textHint)),
          ]);
        }
        return Expanded(child: Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 4), color: _currentStep > i ~/ 2 ? AppColors.primary : AppColors.outline));
      })),
    );
  }

  // ==================== Step 0: Detail form ====================
  Widget _buildDetail() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
      children: [
        _buildStepper(),
        // Service type tag
        Center(child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_selectedService?.icon ?? Icons.flight, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(_selectedService?.name ?? '', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
          ]),
        )),

        // Time card
        _card(children: [
          const Text('任务时间', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _timeTile(Icons.calendar_today_outlined, _selectedDate != null ? '${_selectedDate!.month}月${_selectedDate!.day}日' : '选择日期', onTap: () async {
              final now = DateTime.now();
              final d = await showScrollDatePicker(context, initial: _selectedDate ?? now.add(const Duration(days: 1)), firstDate: now, lastDate: now.add(const Duration(days: 90)));
              if (d != null) setState(() => _selectedDate = d);
            })),
            const SizedBox(width: 12),
            Expanded(child: _timeTile(Icons.access_time, _selectedTime != null ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' : '选择时间', onTap: () async {
              final t = await showScrollTimePicker(context, initial: _selectedTime ?? TimeOfDay.now());
              if (t != null) setState(() => _selectedTime = t);
            })),
          ]),
        ]),
        const SizedBox(height: 10),

        // Route card
        _card(children: [
          const Text('航点设置', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final r = await context.push<String>('/publish/map');
              if (r != null && mounted) setState(() => _waypointsStr = r);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 80, width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFFF0F3F8), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE0E3E8))),
              child: Stack(children: [
                Positioned.fill(child: CustomPaint(painter: _MapThumbPainter())),
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.map_outlined, size: 24, color: AppColors.primary.withAlpha(120)),
                  const SizedBox(height: 4),
                  Text(_waypointsStr != null ? '已选 ${_waypointsStr!.split(";").length} 个航点' : '点击打开地图选择航点',
                    style: TextStyle(fontSize: 12, color: _waypointsStr != null ? AppColors.primary : AppColors.textHint)),
                ])),
              ]),
            ),
          ),
          if (_waypointsStr != null) ...[
            const SizedBox(height: 6),
            Text('预计航线总距离：${(_waypointsStr!.split(";").length * 1.2).toStringAsFixed(1)} km', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          ],
        ]),
        const SizedBox(height: 10),

        // Description card
        _card(children: [
          const Text('任务描述', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController, maxLines: 4, maxLength: 500,
            decoration: const InputDecoration(hintText: '请详细描述您的需求...', counterStyle: TextStyle(fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 10),

        // Price card
        _card(children: [
          const Text('酬劳', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (!_autoCalcPrice)
            TextField(
              controller: _priceController, keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '请输入金额', prefixText: '¥ '),
            ),
          const SizedBox(height: 6),
          Row(children: [
            Switch(value: _autoCalcPrice, onChanged: (v) => setState(() => _autoCalcPrice = v), activeColor: AppColors.primary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
            const SizedBox(width: 6),
            const Text('按航线距离自动计算预估费用', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ]),
      ],
    );
  }

  Widget _timeTile(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(color: const Color(0xFFF5F6F8), borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: text.contains('选择') ? AppColors.textHint : AppColors.onSurface))),
        ]),
      ),
    );
  }

  // ==================== Bottom button ====================
  Widget _buildBottomButton() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      IgnorePointer(child: Container(height: 32, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00F5F7FA), Color(0xFFF5F7FA)])))),
      Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + MediaQuery.of(context).padding.bottom),
        child: _currentStep == 1
            ? Row(children: [
                Expanded(child: OutlinedButton(onPressed: _prevStep, child: const Text('上一步'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(onPressed: _submitting ? null : _nextStep,
                  child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('提交任务'))),
              ])
            : ElevatedButton(onPressed: _nextStep, child: const Text('下一步')),
      ),
    ]);
  }

  // ==================== Step 1: Confirm ====================
  Widget _buildConfirm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
      children: [
        _buildStepper(),
        _card(children: [
          _confirmRow('服务类型', _selectedService?.name ?? ''),
          _confirmRow('任务时间', _selectedDate != null ? '${_selectedDate!.month}月${_selectedDate!.day}日 ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}' : ''),
          _confirmRow('航点数量', _waypointsStr != null ? '${_waypointsStr!.split(";").length}个' : '1个'),
          _confirmRow('任务描述', _descriptionController.text),
          _confirmRow('酬劳', _autoCalcPrice ? '按距离自动计算' : '¥${_priceController.text}'),
        ]),
      ],
    );
  }

  Widget _confirmRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
    ]),
  );

  // ==================== Step 2: Done ====================
  Widget _buildDone() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle), child: const Icon(Icons.check, size: 48, color: Colors.white)),
      const SizedBox(height: 24),
      const Text('任务发布成功！', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      const Text('请等待服务商接单', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
      const SizedBox(height: 36),
      ElevatedButton(onPressed: () => context.go('/orders'), child: const Text('查看订单详情')),
      const SizedBox(height: 10),
      OutlinedButton(onPressed: () => context.go('/home'), child: const Text('返回首页')),
    ]));
  }
}

// ---- map thumbnail pattern ----
class _MapThumbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFE0E4EA)..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 14) { canvas.drawLine(Offset(x, 0), Offset(x + 5, size.height), p); }
    for (double y = 0; y < size.height; y += 14) { canvas.drawLine(Offset(0, y), Offset(size.width, y + 5), p); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
