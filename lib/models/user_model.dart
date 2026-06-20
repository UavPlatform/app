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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'nickname': nickname,
        'avatar': avatar,
        'balance': balance,
        'createdAt': createdAt.toIso8601String(),
      };
}
