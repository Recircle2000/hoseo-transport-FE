// lib/viewmodel/register_viewmodel.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../view/home_view.dart';
import '../utils/env_config.dart';

class RegisterViewModel extends GetxController {
  final email = ''.obs;
  final password = ''.obs;
  final isLoading = false.obs;
  final errorMessage = RxString('');

  void setEmail(String value) => email.value = value;

  void setPassword(String value) => password.value = value;

  Future<void> register() async {
    if (!_validateInputs()) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _performRegistration();
      await _handleRegistrationResponse(response);
    } catch (e) {
      errorMessage.value = '서버 연결 오류가 발생했습니다.';
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    if (email.value.isEmpty || password.value.isEmpty) {
      errorMessage.value = '이메일과 비밀번호를 입력해주세요.';
      return false;
    }
    if (!GetUtils.isEmail(email.value)) {
      errorMessage.value = '유효한 이메일 주소를 입력해주세요.';
      return false;
    }
    if (password.value.length < 6) {
      errorMessage.value = '비밀번호는 최소 6자 이상이어야 합니다.';
      return false;
    }
    return true;
  }

  Future<http.Response> _performRegistration() async {
    final url = Uri.parse('${EnvConfig.baseUrl}/register');
    final user = UserModel(
      email: email.value,
      password: password.value,
    );

    return await http.post(
      url,
      body: jsonEncode(user.toJson()),
      headers: {"Content-Type": "application/json"},
    );
  }

  Future<void> _handleRegistrationResponse(http.Response response) async {
    if (response.statusCode == 200) {
      Get.snackbar('성공', '회원가입이 완료되었습니다.');
      Get.offAll(() => HomeView());
    } else if(response.statusCode == 400) {
      final error = jsonDecode(response.body)['message'] ?? '이미 존재하는 이메일입니다.';
      errorMessage.value = error;
      Get.snackbar('이미 존재하는 이메일입니다.', error);
    }
    else{
      final error = jsonDecode(response.body)['message'] ?? '회원가입에 실패했습니다.';
      errorMessage.value = error;
      Get.snackbar('실패', error);
    }
  }
}
