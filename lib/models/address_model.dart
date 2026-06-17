class Address {
  final String id;
  final String label;  // 家、公司、学校等
  final String name;
  final String phone;
  final String province;
  final String city;
  final String district;
  final String detail;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.province,
    required this.city,
    required this.district,
    required this.detail,
    this.isDefault = false,
  });

  String get fullAddress => '$province$city$district$detail';
}
