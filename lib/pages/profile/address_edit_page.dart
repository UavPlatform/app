import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/address_vo.dart';
import '../../providers/address_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';

class AddressEditPage extends ConsumerStatefulWidget {
  const AddressEditPage({super.key});

  @override
  ConsumerState<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends ConsumerState<AddressEditPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _detailController = TextEditingController();
  final _locationService = LocationService();

  String _selectedLabel = '家';
  bool _isDefault = false;
  bool _locating = false;
  bool _saving = false;
  double? _latitude;
  double? _longitude;
  int? _editId;

  bool get _isEditing => _editId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingOrLocate());
  }

  void _loadExistingOrLocate() {
    final address = GoRouterState.of(context).extra as AddressVo?;
    if (address != null) {
      _editId = address.id;
      _nameController.text = address.contactName;
      _phoneController.text = address.contactPhone;
      _provinceController.text = address.province;
      _cityController.text = address.city;
      _districtController.text = address.district;
      _detailController.text = address.detail;
      _latitude = address.latitude;
      _longitude = address.longitude;
      _selectedLabel = address.label ?? '家';
      _isDefault = address.isDefault;
      setState(() {});
    } else {
      _autoFillLocation();
    }
  }

  /// 新增时自动定位，高德逆地理编码自动填充省市区（MethodChannel，见 MainActivity.kt）
  Future<void> _autoFillLocation() async {
    setState(() => _locating = true);

    final gpsOn = await Geolocator.isLocationServiceEnabled();
    if (!gpsOn) {
      setState(() => _locating = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => _locating = false);
      return;
    }

    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    if (result != null) {
      final province = result.province ?? '';
      final city = result.city ?? '';
      final district = result.district ?? '';
      final street = result.address ?? '';
      _provinceController.text = province;
      _cityController.text = city;
      _districtController.text = district;
      if (street.isNotEmpty) {
        _detailController.text = street;
      }
      _latitude = result.latitude;
      _longitude = result.longitude;
    }
    setState(() => _locating = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  AddressVo _buildVo({required int id}) {
    return AddressVo(
      id: id,
      userId: 0,
      contactName: _nameController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      province: _provinceController.text.trim(),
      city: _cityController.text.trim(),
      district: _districtController.text.trim(),
      detail: _detailController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      label: _selectedLabel,
      isDefault: _isDefault,
    );
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('请输入联系人');
      return;
    }
    if (!RegExp(r'^1\d{10}$').hasMatch(_phoneController.text.trim())) {
      _showError('请输入正确的手机号');
      return;
    }
    if (_detailController.text.trim().isEmpty) {
      _showError('请输入详细地址');
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(addressProvider.notifier);
    final saved = _isEditing
        ? await notifier.updateAddress(_buildVo(id: _editId!))
        : await notifier.createAddress(_buildVo(id: 0));
    if (!mounted) return;
    setState(() => _saving = false);

    if (saved != null) {
      context.pop(true);
    } else {
      _showError('保存失败，请检查网络后重试');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑地址' : '新增地址'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTextField(
            controller: _nameController,
            label: '联系人',
            hint: '请输入姓名',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: '手机号',
            hint: '请输入手机号',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTextField(controller: _provinceController, label: '省', hint: '自动获取')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(controller: _cityController, label: '市', hint: '自动获取')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(controller: _districtController, label: '区', hint: '自动获取')),
            ],
          ),
          if (_locating)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('正在定位...', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
            ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _detailController,
            label: '详细地址',
            hint: '请输入详细地址（街道、楼栋、门牌号）',
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          const Text('标签', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _buildLabelChip('家', Icons.home),
              _buildLabelChip('公司', Icons.business),
              _buildLabelChip('学校', Icons.school),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('设为默认地址', style: TextStyle(fontSize: 16)),
              Switch(
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _buildLabelChip(String label, IconData icon) {
    final isSelected = _selectedLabel == label;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedLabel = label);
      },
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.onSurface,
      ),
    );
  }
}
