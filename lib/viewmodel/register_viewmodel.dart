// lib/viewmodel/register_viewmodel.dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../view/home_view.dart';

class RegisterViewModel extends GetxController {
  final studentId = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final isLoading = false.obs;
  final errorMessage = RxString('');
  final currentStep = 0.obs;
  
  // 이메일 도메인
  static const String EMAIL_DOMAIN = 'vision.hoseo.edu';
  
  // 유효성 검사 상태
  final isStudentIdValid = false.obs;
  final isPasswordValid = false.obs;
  final isPasswordMatch = false.obs;

  // 이메일 생성을 위한 getter
  String get email => studentId.value.isEmpty ? '' : '$studentId@$EMAIL_DOMAIN';

  void setStudentId(String value) {
    studentId.value = value;
    validateStudentId();
  }

  void setPassword(String value) {
    password.value = value;
    validatePassword();
    validatePasswordMatch();
  }
  
  void setConfirmPassword(String value) {
    confirmPassword.value = value;
    validatePasswordMatch();
  }
  
  void nextStep() {
    if (currentStep.value < 1) {
      currentStep.value++;
    }
  }
  
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }
  
  void validateStudentId() {
    // 학번 유효성 검증 (8자리 숫자)
    final RegExp numericOnly = RegExp(r'^[0-9]{8}$');
    isStudentIdValid.value = numericOnly.hasMatch(studentId.value);
  }
  
  void validatePassword() {
    // 8자 이상, 특수문자 포함 검증
    final RegExp specialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    
    if (password.value.length >= 8 && specialChar.hasMatch(password.value)) {
      isPasswordValid.value = true;
    } else {
      isPasswordValid.value = false;
    }
  }
  
  void validatePasswordMatch() {
    isPasswordMatch.value = password.value == confirmPassword.value && password.value.isNotEmpty;
  }
  
  bool canProceedToNextStep() {
    if (currentStep.value == 0) {
      return isStudentIdValid.value;
    } else if (currentStep.value == 1) {
      return isPasswordValid.value && isPasswordMatch.value;
    }
    return true;
  }

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
    if (studentId.value.isEmpty || password.value.isEmpty || confirmPassword.value.isEmpty) {
      errorMessage.value = '모든 필드를 입력해주세요.';
      return false;
    }
    
    if (!isStudentIdValid.value) {
      errorMessage.value = '유효한 학번을 입력해주세요 (8자리 숫자).';
      return false;
    }
    
    if (!isPasswordValid.value) {
      errorMessage.value = '비밀번호는 최소 8자 이상이며 특수문자를 포함해야 합니다.';
      return false;
    }
    
    if (!isPasswordMatch.value) {
      errorMessage.value = '비밀번호가 일치하지 않습니다.';
      return false;
    }
    
    return true;
  }

  Future<http.Response> _performRegistration() async {
    final url = Uri.parse('${EnvConfig.baseUrl}/register');
    final user = UserModel(
      email: email,
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
      final error = jsonDecode(response.body)['message'] ?? '이미 존재하는 학번입니다.';
      errorMessage.value = error;
      Get.snackbar('이미 존재하는 학번입니다.', error);
    }
    else{
      final error = jsonDecode(response.body)['message'] ?? '회원가입에 실패했습니다.';
      errorMessage.value = error;
      Get.snackbar('실패', error);
    }
  }
}