import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../services/mock_data_service.dart';
import '../../models/service_type_model.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key});

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  int _currentStep = 0;
  ServiceType? _selectedService;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择服务类型')),
      );
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
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
          // 步骤指示器
          _buildStepIndicator(),

          // 内容区
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

          // 底部按钮
          if (_currentStep < 3)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _nextStep,
                child: Text(_currentStep == 2 ? '提交任务' : '下一步'),
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
    final isCurrent = _currentStep == step;
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primary : AppColors.outline,
            border: isCurrent
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
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

  // 步骤1：选择服务类型
  Widget _buildStep1() {
    final serviceTypes = MockDataService.serviceTypes;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '选择您需要的服务类型',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ...serviceTypes.map((type) => _buildServiceTypeCard(type)),
      ],
    );
  }

  Widget _buildServiceTypeCard(ServiceType type) {
    final isSelected = _selectedService?.id == type.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() => _selectedService = type);
        },
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
                    Text(
                      type.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
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

  // 步骤2：填写详情
  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '填写任务详情',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // 服务类型（只读）
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

        // 任务时间
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
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.month}-${_selectedDate!.day}'
                            : '请选择日期',
                      ),
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
                      Text(
                        _selectedTime != null
                            ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                            : '请选择时间',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 任务地点
        const Text('任务地点 *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _locationController,
          decoration: const InputDecoration(
            hintText: '请选择地点',
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
        const SizedBox(height: 20),

        // 任务描述
        const Text('任务描述 *', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: '请详细描述您的需求...',
          ),
        ),
        const SizedBox(height: 20),

        // 预算范围
        const Text('预算范围（选填）', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _budgetMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '最低 ¥',
                  prefixText: '¥ ',
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('~'),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _budgetMaxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '最高 ¥',
                  prefixText: '¥ ',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 快捷预算标签
        Wrap(
          spacing: 8,
          children: [
            _buildBudgetChip('¥200以下'),
            _buildBudgetChip('¥200-500'),
            _buildBudgetChip('¥500-1000'),
            _buildBudgetChip('¥1000以上'),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        // 解析并填入预算
        final text = label.replaceAll('¥', '').replaceAll('以下', '').replaceAll('以上', '');
        if (text.contains('-')) {
          final parts = text.split('-');
          _budgetMinController.text = parts[0];
          _budgetMaxController.text = parts[1];
        }
      },
    );
  }

  // 步骤3：确认信息
  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '确认订单信息',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        // 订单信息卡片
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
                _selectedDate != null
                    ? '${_selectedDate!.month}-${_selectedDate!.day} ${_selectedTime?.hour}:${_selectedTime?.minute.toString().padLeft(2, '0')}'
                    : '',
              ),
              _buildConfirmRow('任务地点', _locationController.text),
              _buildConfirmRow('任务描述', _descriptionController.text),
              _buildConfirmRow(
                '预算范围',
                _budgetMinController.text.isNotEmpty
                    ? '¥${_budgetMinController.text}-${_budgetMaxController.text}'
                    : '面议',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 服务条款
        Row(
          children: [
            Checkbox(
              value: true,
              onChanged: (value) {},
              activeColor: AppColors.primary,
            ),
            const Text('同意'),
            GestureDetector(
              onTap: () {},
              child: const Text(
                '《服务条款》',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // 步骤4：提交成功
  Widget _buildStep4() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            '任务发布成功！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '请等待飞手接单',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '预计15分钟内会有飞手响应',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.outline,
            ),
          ),
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
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() => _currentStep = 0);
                    _selectedService = null;
                    _selectedDate = null;
                    _selectedTime = null;
                    _locationController.clear();
                    _descriptionController.clear();
                    _budgetMinController.clear();
                    _budgetMaxController.clear();
                  },
                  child: const Text('继续发布任务'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
