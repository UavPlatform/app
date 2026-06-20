class RegisterRequest {
  final String userName;
  final String password;

  RegisterRequest({required this.userName, required this.password});

  Map<String, dynamic> toJson() => {'userName': userName, 'password': password};
}
