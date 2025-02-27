class UserModel {
  final String email;
  final String password;

  UserModel({required this.email, required this.password});

  // 사용자 데이터를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}