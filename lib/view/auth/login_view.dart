// lib/view/login_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodel/login_viewmodel.dart';
import 'register_view.dart';

class LoginView extends StatelessWidget {
  final LoginViewModel _loginViewModel = Get.put(LoginViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  '환영합니다!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '학번과 비밀번호로 로그인하세요.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 60),
                // 학번 입력 필드
                TextField(
                  onChanged: (value) {
                    _loginViewModel.setStudentId(value);
                    if (value.length == 8) {
                      // 8자리 입력 완료 시 키보드 닫기
                      FocusScope.of(context).unfocus();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: '학번',
                    hintText: '8자리 숫자',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: Obx(() => _loginViewModel.isStudentIdValid.value
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const SizedBox.shrink()),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                ),
                const SizedBox(height: 8),
                // 자동 생성된 이메일 표시
                Obx(() {
                  if (_loginViewModel.studentId.value.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이메일:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.email_outlined, color: Colors.blue.shade300, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                _loginViewModel.email,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(height: 24),
                // 비밀번호 입력 필드
                _PasswordTextField(
                  onChanged: _loginViewModel.setPassword,
                  labelText: '비밀번호',
                ),
                const SizedBox(height: 40),
                // 오류 메시지 표시
                Obx(() {
                  final error = _loginViewModel.errorMessage.value;
                  if (error.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 40),
                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Obx(() {
                    if (_loginViewModel.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton(
                      onPressed: _loginViewModel.login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '로그인',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                // 회원가입 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('계정이 없으신가요?'),
                    TextButton(
                      onPressed: () => Get.to(() => RegisterView()),
                      child: const Text('회원가입'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordTextField extends StatefulWidget {
  final Function(String) onChanged;
  final String labelText;

  const _PasswordTextField({
    required this.onChanged,
    required this.labelText,
  });

  @override
  State<_PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<_PasswordTextField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: widget.onChanged,
      obscureText: !_isVisible,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isVisible ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _isVisible = !_isVisible;
            });
          },
        ),
      ),
    );
  }
}
