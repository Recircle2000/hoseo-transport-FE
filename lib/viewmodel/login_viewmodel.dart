// lib/viewmodel/login_viewmodel.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../view/home_view.dart';
import '../view/auth/login_view.dart';

class LoginViewModel extends GetxController {
  final email = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;
  final errorMessage = RxString('');
  final currentUser = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    checkAutoLogin();
  }

  void setEmail(String value) => email.value = value;

  void setPassword(String value) => password.value = value;

  Future<void> login() async {
    if (!_validateInputs()) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _performLogin();
      await _handleLoginResponse(response);
    } catch (e) {
      _handleError('서버 연결 오류가 발생했습니다.');
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    if (email.value.isEmpty || password.value.isEmpty) {
      _handleError('이메일과 비밀번호를 입력해주세요.');
      return false;
    }
    if (!GetUtils.isEmail(email.value)) {
      _handleError('유효한 이메일 주소를 입력해주세요.');
      return false;
    }
    return true;
  }

  Future<http.Response> _performLogin() async {
    final url = Uri.parse(_getloginUrl());
    //10.0.2.2
    return await http.post(
      url,
      body: jsonEncode({
        'email': email.value,
        'password': password.value,
      }),
      headers: {"Content-Type": "application/json"},
    );
  }

  Future<void> _handleLoginResponse(http.Response response) async {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access_token'];

      currentUser.value = UserModel(
        email: email.value,
        password: '', // 보안을 위해 비밀번호는 저장하지 않음
      );

      await _saveLoginData(token);
      Get.back(); // 로그인 화면으로 돌아가기
    } else {
      _handleError('로그인에 실패했습니다.');
    }
  }

  Future<void> _saveLoginData(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('email', email.value);
  }

  Future<void> checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('isLoggedIn') ?? false) {
        final token = prefs.getString('access_token');
        final savedEmail = prefs.getString('email');

        if (token != null && savedEmail != null) {
          currentUser.value = UserModel(
            email: savedEmail,
            password: '',
          );
        }
      }
    } catch (e) {
      _handleError('자동 로그인 중 오류가 발생했습니다.');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      currentUser.value = null;
      email.value = '';
      password.value = '';
      Get.offAll(() => LoginView());
    } catch (e) {
      _handleError('로그아웃 중 오류가 발생했습니다.');
    }
  }

  void _handleError(String message) {
    errorMessage.value = message;
    Get.snackbar('오류', message);
  }
}

String _getloginUrl() {
  if (GetPlatform.isAndroid) {
    return "http://192.168.45.138:8000/login";
  } else if (GetPlatform.isIOS) {
    return "http://192.168.45.138:8000/login";
  }
  else {
    return "http://127.0.0.1:8000/login";
  }
}
