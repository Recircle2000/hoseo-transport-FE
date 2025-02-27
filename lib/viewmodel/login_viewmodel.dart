import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../view/home_view.dart';
import 'dart:async';

class LoginController extends GetxController {
  // 사용자 이메일과 비밀번호 입력값
  var email = ''.obs;
  var password = ''.obs;

  // 로그인 상태 관리
  var isLoading = false.obs;

  // 로그인 함수
  Future<void> login() async {
    isLoading.value = true; // 로딩 상태 시작
    final url = Uri.parse('http://localhost:8000/login'); // 서버 주소

    final response = await http.post(
      url,
      body: jsonEncode({
        'email': email.value,
        'password': password.value,
      }),
      headers: {"Content-Type": "application/json"},
    );

    isLoading.value = false; // 로딩 상태 종료

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];
      print('로그인 성공, 토큰: $token');

      // 로그인 성공 시
      if (response.statusCode == 200) {
        Get.to(() => HomeView());  // HomeView로 이동
      }
      // 토큰을 저장하거나 필요한 처리 수행
    } else {
      print('로그인 실패');
      Get.snackbar('Login Failed', 'Invalid email or password');
    }
    Timer(Duration(seconds: 3), () {
      isLoading.value = false;
      Get.snackbar('Login Failed', 'Invalid email or password');

    });
  }
}