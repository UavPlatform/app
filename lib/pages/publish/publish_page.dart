import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/order_api.dart';
import '../../theme/app_colors.dart';
import '../../models/service_type_model.dart';
import '../../models/create_task_request.dart';
import '../../models/price_detail.dart';
import '../../services/task_draft_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/location_provider.dart';
import '../pay/pay_page.dart';

class PublishPage extends ConsumerStatefulWidget {
  const PublishPage({super.key});

  @override
  ConsumerState<PublishPage> createState() => _PublishPageState();
}

/// 组装提交给后端的 taskTime（t15 契约："yyyy-MM-dd HH:mm:ss"，空格分隔）。
/// 确认步展示与实际提交共用此函数，保证「所见即所发」。
String? buildTaskTimeString(DateTime? date, TimeOfDay? time) {
  if (date == null || time == null) return null;
  final yyyy = date.year.toString().padLeft(4, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final hh = time.hour.toString().padLeft(2, '0');
  final mi = time.minute.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd $hh:$mi:00';
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
  String? _pendingOrderNum;

  // ---- 计费（bill_config 阶梯计价）----
  /// 货物重量；仅「按重量计费的类型」才展示输入框（由 /task/publish/config 决定）
  final _weightController = TextEditingController();
  List<String> _weightTypes = const [];
  double? _minNegotiatedRate;
  bool _showWeightField = false;

  /// 实时参考价（/task/price/estimate，输入变更后防抖 500ms 拉取）
  PriceDetail? _estimate;
  Timer? _estimateDebounce;

  // ---- 草稿（离开自动保存，回来恢复）----
  final _draftService = TaskDraftService();
  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();
    _loadPublishConfig();
    _loadDraft();
  }

  @override
  void dispose() {
    _estimateDebounce?.cancel();
    // 离开页面兜底保存一次草稿（防抖 pending 中的状态）
    if (_draftDebounce?.isActive ?? false) {
      _draftDebounce!.cancel();
      _saveDraft();
    }
    _weightController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ---------------- 计费 ----------------

  /// 拉发布配置：哪些任务类型按重量计费 + 协商价下限系数
  Future<void> _loadPublishConfig() async {
    final result = await ref.read(taskApiProvider).getPublishConfig();
    if (!mounted || result.data == null) return;
    setState(() {
      _weightTypes = result.data!.weightTypes;
      _minNegotiatedRate = result.data!.minNegotiatedRate;
      _showWeightField = _isWeightType(_selectedService?.id);
    });
  }

  bool _isWeightType(String? serviceId) {
    if (serviceId == null) return false;
    return _weightTypes.contains(_serviceIdToTaskType(serviceId));
  }

  /// 刷新参考价预览（航点/重量/时间变化时调用）
  void _refreshEstimate() {
    _estimateDebounce?.cancel();
    _estimateDebounce = Timer(const Duration(milliseconds: 500), () async {
      final waypoints = _buildWaypoints();
      if (waypoints.isEmpty) return;
      final result = await ref.read(taskApiProvider).estimatePrice(
            PriceEstimateRequest(
              taskType: _selectedService != null
                  ? _serviceIdToTaskType(_selectedService!.id)
                  : null,
              waypoints: waypoints,
              weight: double.tryParse(_weightController.text),
              taskTime: buildTaskTimeString(_selectedDate, _selectedTime),
            ),
          );
      if (!mounted) return;
      setState(() => _estimate = result.data);
    });
  }

  void _onWeightChanged(String _) {
    _scheduleDraftSave();
    _refreshEstimate();
  }

  // ---------------- 草稿 ----------------

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  void _saveDraft() {
    _draftService.save(TaskDraft(
      serviceTypeName: _selectedService?.name,
      waypointsStr: _waypointsStr,
      description: _descriptionController.text,
      weight: _weightController.text,
      price: _priceController.text,
    ));
  }

  Future<void> _loadDraft() async {
    final draft = await _draftService.load();
    if (!mounted || draft == null) return;
    setState(() {
      if (draft.description != null) _descriptionController.text = draft.description!;
      if (draft.weight != null) _weightController.text = draft.weight!;
      if (draft.price != null) _priceController.text = draft.price!;
      if (draft.waypointsStr != null) _waypointsStr = draft.waypointsStr;
    });
    _refreshEstimate();
  }

  void _nextStep() {
    // 步骤0→1：必须选服务类型
    if (_currentStep == 0 && _selectedService == null) {
      _showError('请选择服务类型');
      return;
    }
    // 步骤1→2：必填项校验
    if (_currentStep == 1) {
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
    // 步骤2→3：提交
    if (_currentStep == 2) {
      _submitTask();
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// t29④：发布成功后查询最新订单，待支付则提供「去支付」直达入口。
  Future<void> _loadLatestPendingOrder() async {
    try {
      final api = OrderApi(ref.read(httpClientProvider));
      final result = await api.listOrders(page: 0, size: 1);
      if (!mounted) return;
      final orders = result.data?.orders ?? const [];
      if (orders.isNotEmpty && orders.first.isPending) {
        setState(() => _pendingOrderNum = orders.first.orderNum);
      }
    } catch (_) {
      // 查询失败不影响发布完成页，用户仍可从订单页进入支付
    }
  }

  Future<void> _goPayLatestOrder() async {
    final orderNum = _pendingOrderNum;
    if (orderNum == null) return;
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PayPage(orderNum: orderNum)),
    );
    if (!mounted) return;
    if (paid == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('支付成功')),
      );
    }
    setState(() => _pendingOrderNum = null);
  }

  Future<void> _submitTask() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入酬劳金额')),
      );
      return;
    }

    setState(() => _submitting = true);

    final request = CreateTaskRequest(
      taskName: _selectedService!.name,
      type: _serviceIdToTaskType(_selectedService!.id),
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : _selectedService!.description,
      waypoints: _buildWaypoints(),
      reward: double.tryParse(_priceController.text),
      // 重量仅对「按重量计费的类型」生效（后端 WEIGHT_TYPES 决定是否计入重量费）
      weight: _showWeightField ? double.tryParse(_weightController.text) : null,
      taskTime: buildTaskTimeString(_selectedDate, _selectedTime),
    );

    final success = await ref.read(taskProvider.notifier).createTask(request);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      // 发布成功，清除草稿
      _draftService.clear();
      setState(() => _currentStep = 3);
      // t29：发布即生成待支付订单，完成页提供支付直达入口
      unawaited(_loadLatestPendingOrder());
    } else {
      final error = ref.read(taskProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? '创建失败')),
      );
    }
  }

  String _serviceIdToTaskType(String id) {
    switch (id) {
      case 'aerial_photo':
        return 'AERIAL_PHOTO';
      case 'survey':
        return 'SURVEY';
      case 'logistics':
        return 'TRANSPORT';
      case 'monitoring':
        return 'MONITORING';
      default:
        return 'AERIAL_PHOTO';
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
    // 兜底：用定位坐标
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
        title: const Text('发布任务'),
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
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
          if (_currentStep < 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _currentStep == 2
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: Row(
        children: [
          _buildStepDot(0, '服务'),
          _buildStepLine(0),
          _buildStepDot(1, '详情'),
          _buildStepLine(1),
          _buildStepDot(2, '确认'),
          _buildStepLine(2),
          _buildStepDot(3, '完成'),
        ],
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

  // 服务类型本地常量，对应后端 TaskType 枚举
  static final _serviceTypes = [
    ServiceType(id: 'aerial_photo', name: '航拍摄影', icon: Icons.videocam, description: '活动跟拍/婚礼航拍/宣传片'),
    ServiceType(id: 'survey', name: '测绘建模', icon: Icons.map, description: '地形测绘/3D建模'),
    ServiceType(id: 'logistics', name: '物流吊运', icon: Icons.local_shipping, description: '物资吊运/设备转运'),
    ServiceType(id: 'monitoring', name: '环境监测', icon: Icons.eco, description: '空气质量/水质监测'),
  ];

  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '选择您需要的服务类型',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ..._serviceTypes.map((type) => _buildServiceTypeCard(type)),
      ],
    );
  }

  Widget _buildServiceTypeCard(ServiceType type) {
    final isSelected = _selectedService?.id == type.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() {
          _selectedService = type;
          // 换类型可能改变「是否按重量计费」，重量框随之显隐
          _showWeightField = _isWeightType(type.id);
          _refreshEstimate();
          _scheduleDraftSave();
        }),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  type.icon,
                  color: isSelected ? Colors.white : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(type.description, style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
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
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                    // 任务时间影响夜间附加费，重算参考价
                    _refreshEstimate();
                    _scheduleDraftSave();
                  }
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
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() => _selectedTime = time);
                    _refreshEstimate();
                    _scheduleDraftSave();
                  }
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
              _refreshEstimate();
              _scheduleDraftSave();
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
          onChanged: (_) => _scheduleDraftSave(),
          decoration: InputDecoration(
            hintText: '请输入金额',
            prefixText: '¥ ',
            helperText: _minNegotiatedRate != null
                ? '不得低于平台参考价的 ${(_minNegotiatedRate! * 100).toStringAsFixed(0)}%'
                : null,
          ),
        ),
        // 货物重量：仅「按重量计费的类型」展示（后端 WEIGHT_TYPES 决定）
        if (_showWeightField) ...[
          const SizedBox(height: 20),
          const Text('货物重量（kg）', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _onWeightChanged,
            decoration: const InputDecoration(hintText: '请输入货物重量'),
          ),
        ],
        // 参考价预览（/task/price/estimate，防抖 500ms）
        if (_estimate != null) ...[
          const SizedBox(height: 20),
          _buildEstimateCard(_estimate!),
        ],
      ],
    );
  }

  /// 参考价预览卡：总距离 + 参考价 + 计费明细 + 超重提示
  Widget _buildEstimateCard(PriceDetail estimate) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            const Text('平台参考价',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('¥${(estimate.total ?? 0).toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ]),
          if (estimate.distanceKm != null) ...[
            const SizedBox(height: 4),
            Text('航线总距离 ${estimate.distanceKm!.toStringAsFixed(2)} km',
                style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
          if (estimate.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...estimate.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Expanded(
                      child: Text(item.name,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant)),
                    ),
                    Text('¥${item.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12)),
                  ]),
                )),
          ],
          if (estimate.needManualQuote == true) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
              const SizedBox(width: 4),
              const Expanded(
                child: Text('该重量需平台人工报价，提交后由平台协商定价',
                    style: TextStyle(fontSize: 12, color: AppColors.warning)),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3() {
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
              _buildConfirmRow('服务类型', _selectedService?.name ?? ''),
              _buildConfirmRow(
                '任务时间',
                buildTaskTimeString(_selectedDate, _selectedTime) ?? '',
              ),
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

  Widget _buildStep4() {
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
          const SizedBox(height: 16),
          // t30：Q1=A 托管式支付规则提示——支付后才进入飞手大厅
          const PublishPaymentHint(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                if (_pendingOrderNum != null)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _goPayLatestOrder,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      icon: const Icon(Icons.payment, size: 18),
                      label: const Text('去支付', style: TextStyle(fontSize: 16)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/orders'),
                      child: const Text('查看订单详情'),
                    ),
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

/// 发布完成页支付规则提示（t30，Q1=A 托管式支付）：
/// 任务支付完成后才会进入飞手大厅，供飞手接单。
class PublishPaymentHint extends StatelessWidget {
  const PublishPaymentHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 48),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.onSurfaceVariant),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '支付后任务才会进入飞手大厅',
              style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
