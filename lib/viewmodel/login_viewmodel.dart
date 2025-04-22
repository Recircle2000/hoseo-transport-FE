// lib/viewmodel/login_viewmodel.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../view/home_view.dart';
import '../utils/env_config.dart';
import '../view/auth/login_view.dart';

class LoginViewModel extends GetxController {
  final studentId = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;
  final errorMessage = RxString('');
  final currentUser = Rxn<UserModel>();
  final String baseUrl = '${EnvConfig.baseUrl}/login'; // 환경 변수에서 가져옴
  
  // 이메일 도메인
  static const String EMAIL_DOMAIN = 'vision.hoseo.edu';
  
  // 유효성 검사 상태
  final isStudentIdValid = false.obs;

  // 이메일 생성을 위한 getter
  String get email => studentId.value.isEmpty ? '' : '$studentId@$EMAIL_DOMAIN';

  @override
  void onInit() {
    super.onInit();
    checkAutoLogin();
  }

  void setStudentId(String value) {
    studentId.value = value;
    validateStudentId();
  }

  void setPassword(String value) => password.value = value;
  
  void validateStudentId() {
    // 학번 유효성 검증 (8자리 숫자)
    final RegExp numericOnly = RegExp(r'^[0-9]{8}$');
    isStudentIdValid.value = numericOnly.hasMatch(studentId.value);
  }

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
    if (studentId.value.isEmpty || password.value.isEmpty) {
      _handleError('학번과 비밀번호를 입력해주세요.');
      return false;
    }
    if (!isStudentIdValid.value) {
      _handleError('유효한 학번을 입력해주세요 (8자리 숫자).');
      return false;
    }
    return true;
  }

  Future<http.Response> _performLogin() async {
    final url = Uri.parse(baseUrl);
    print(url);
    //10.0.2.2
    return await http.post(
      url,
      body: jsonEncode({
        'email': email,
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
        email: email,
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
    await prefs.setString('email', email);
    await prefs.setString('studentId', studentId.value);
  }

  Future<void> checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('isLoggedIn') ?? false) {
        final token = prefs.getString('access_token');
        final savedEmail = prefs.getString('email');
        final savedStudentId = prefs.getString('studentId');

        if (token != null && savedEmail != null && savedStudentId != null) {
          studentId.value = savedStudentId;
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
      studentId.value = '';
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
