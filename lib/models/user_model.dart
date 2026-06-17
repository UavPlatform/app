class User {
  final String id;
  final String phone;
  final String nickname;
  final String? avatar;
  final double balance;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatar,
    this.balance = 0,
    required this.createdAt,
  });
}
