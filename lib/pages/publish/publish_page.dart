import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import '../../models/service_type_model.dart';
import '../../models/create_task_request.dart';
import '../../providers/task_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/time_picker.dart';

class PublishPage extends ConsumerStatefulWidget {
  const PublishPage({super.key});

  @override
  ConsumerState<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends ConsumerState<PublishPage> {
  int _currentStep = 0;
  ServiceType? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  double? _pickedLat;
  double? _pickedLng;
  String? _waypointsStr;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final types = MockDataService.serviceTypes;
    if (types.isNotEmpty) {
      _selectedService = types.first;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_waypointsStr == null || _waypointsStr!.isEmpty) {
        _showError('请点击地图选择航点');
        return;
      }
      if (_selectedDate == null || _selectedTime == null) {
        _showError('请选择任务时间');
        return;
      }
      if (_descriptionController.text.isEmpty) {
        _showError('请输入任务描述');
        return;
      }
      if (_priceController.text.isEmpty) {
        _showError('请输入酬劳金额');
        return;
      }
    }
    if (_currentStep == 1) {
      _submitTask();
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitTask() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入酬劳金额')),
      );
      return;
    }

    setState(() => _submitting = true);

    final serviceName = _selectedService?.name ?? '物流吊运';
    final serviceDesc = _selectedService?.description ?? '物资吊运/设备转运';

    final request = CreateTaskRequest(
      taskName: serviceName,
      type: 'TRANSPORT',
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : serviceDesc,
      waypoints: _buildWaypoints(),
      reward: double.tryParse(_priceController.text),
      taskTime: _selectedDate != null && _selectedTime != null
          ? '${_selectedDate!.toIso8601String().split('T')[0]} ${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
    );

    final success = await ref.read(taskProvider.notifier).createTask(request);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      setState(() => _currentStep = 2);
    } else {
      final error = ref.read(taskProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? '创建失败')),
      );
    }
  }

  List<WaypointRequest> _buildWaypoints() {
    if (_waypointsStr != null) {
      final parts = _waypointsStr!.split(';');
      return List.generate(parts.length, (i) {
        final coords = parts[i].split(',');
        return WaypointRequest(
          orderIndex: i,
          longitude: double.tryParse(coords[1]) ?? 112.9193,
          latitude: double.tryParse(coords[0]) ?? 27.8981,
          altitude: 100,
        );
      });
    }
    final loc = ref.read(locationProvider);
    return [
      WaypointRequest(
        orderIndex: 0,
        longitude: loc.longitude ?? 112.9193,
        latitude: loc.latitude ?? 27.8981,
        altitude: 100,
      ),
    ];
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发布物流吊运任务'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevStep,
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildStepDetail(),
                _buildStepConfirm(),
                _buildStepDone(),
              ],
            ),
          ),
          if (_currentStep < 2)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _currentStep == 1
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _prevStep,
                            child: const Text('上一步'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _nextStep,
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('提交任务'),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: _nextStep,
                      child: const Text('下一步'),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const steps = ['任务详情', '确认信息', '发布完成'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isEven) {
            final step = i ~/ 2;
            return _buildStepDot(step, steps[step]);
          }
          return _buildStepLine(i ~/ 2);
        }),
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.outline,
          ),
          child: isActive
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : AppColors.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    return Expanded(
      child: Container(
        height: 2,
        color: _currentStep > step ? AppColors.primary : AppColors.outline,
      ),
    );
  }

  Widget _buildStepDetail() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('填写任务详情', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        if (_selectedService != null) ...[
          const Text('服务类型', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(_selectedService!.icon, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(_selectedService!.name),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        const Text('任务时间 *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    locale: const Locale('zh'),
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        dialogTheme: const DialogThemeData(insetPadding: EdgeInsets.symmetric(horizontal: 24)),
                      ),
                      child: SizedBox(height: 360, child: child),
                    ),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(_selectedDate != null
                          ? '${_selectedDate!.month}-${_selectedDate!.day}'
                          : '请选择日期'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showScrollTimePicker(
                    context,
                    initial: _selectedTime ?? TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _selectedTime = time);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(_selectedTime != null
                          ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : '请选择时间'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('航点设置 *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await context.push<String>('/publish/map');
            if (result != null && mounted) {
              setState(() => _waypointsStr = result);
              final parts = result.split(';');
              if (parts.isNotEmpty) {
                final first = parts.first.split(',');
                if (first.length == 2) {
                  _pickedLat = double.tryParse(first[0]);
                  _pickedLng = double.tryParse(first[1]);
                }
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _waypointsStr != null
                        ? '已选 ${_waypointsStr!.split(";").length} 个航点'
                        : '点击打开地图选择航点',
                    style: TextStyle(
                      color: _waypointsStr != null
                          ? AppColors.onSurface
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.outline),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('任务描述 *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(hintText: '请详细描述您的需求...'),
        ),
        const SizedBox(height: 20),
        const Text('酬劳 *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: '请输入金额', prefixText: '¥ '),
        ),
      ],
    );
  }

  Widget _buildStepConfirm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('确认订单信息', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildConfirmRow('服务类型', _selectedService?.name ?? '物流吊运'),
              _buildConfirmRow('任务时间', _selectedDate != null
                  ? '${_selectedDate!.month}-${_selectedDate!.day} ${_selectedTime?.hour}:${_selectedTime?.minute.toString().padLeft(2, '0')}'
                  : ''),
              _buildConfirmRow('航点数量',
                _waypointsStr != null ? '${_waypointsStr!.split(";").length}个' : '1个'),
              _buildConfirmRow('任务描述', _descriptionController.text),
              _buildConfirmRow('酬劳', '¥${_priceController.text}'),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildStepDone() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('任务发布成功！', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('请等待飞手接单', style: TextStyle(fontSize: 16, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () => context.go('/orders'),
                  child: const Text('查看订单详情'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('返回首页'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
