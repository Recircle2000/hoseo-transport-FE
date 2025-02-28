import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../view/home_view.dart';
import '../view/login_view.dart';
import 'dart:async';

class LoginController extends GetxController {
  var email = ''.obs;
  var password = ''.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAutoLogin();  // 앱 실행 시 자동 로그인 확인
  }

  /// 로그인 함수
  Future<void> login() async {
    isLoading.value = true;
    final url = Uri.parse('http://localhost:8000/login');

    final response = await http.post(
      url,
      body: jsonEncode({
        'email': email.value,
        'password': password.value,
      }),
      headers: {"Content-Type": "application/json"},
    );

    isLoading.value = false;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];

      print('로그인 성공, 토큰: $token');

      // SharedPreferences에 로그인 정보 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email.value);

      Get.offAll(() => HomeView());  // 홈 화면으로 이동
    } else {
      print('로그인 실패');
      Get.snackbar('Login Failed', 'Invalid email or password');
    }
  }

  /// 자동 로그인 확인 함수
  Future<void> checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      String? token = prefs.getString('access_token');
      if (token != null) {
        print('자동 로그인 성공, 저장된 토큰: $token');
        Get.offAll(() => HomeView());  // 자동 로그인 후 홈 화면으로 이동
      }
    }
  }

  /// 로그아웃 함수
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();  // 저장된 로그인 정보 삭제
    Get.offAll(() => LoginView());  // 로그인 화면으로 이동
  }
}
