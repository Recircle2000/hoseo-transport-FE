import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodel/register_viewmodel.dart';

class RegisterView extends StatelessWidget {
  final RegisterViewModel _registerViewModel = Get.put(RegisterViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Obx(() => _buildCurrentStep(context)),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_registerViewModel.currentStep.value) {
      case 0:
        return _StudentIdStep();
      case 1:
        return _PasswordStep();
      default:
        return _StudentIdStep();
    }
  }
}

class _StudentIdStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final RegisterViewModel viewModel = Get.find<RegisterViewModel>();
    final screenSize = MediaQuery.of(context).size;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Get.back(),
            ),
            const SizedBox(height: 24),
            _buildStepIndicator(0),
            const SizedBox(height: 32),
            const Text(
              '학번을 \n입력해주세요',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '학교 이메일은 자동으로 생성됩니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              onChanged: (value) {
                viewModel.setStudentId(value);
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
                suffixIcon: Obx(() => viewModel.isStudentIdValid.value
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const SizedBox.shrink()),
              ),
              keyboardType: TextInputType.number,
              maxLength: 8,
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (viewModel.studentId.value.isNotEmpty) {
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
                            viewModel.email,
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
            const SizedBox(height: 8),
            Obx(() {
              if (!viewModel.isStudentIdValid.value && viewModel.studentId.value.isNotEmpty) {
                return const Text(
                  '학번은 8자리 숫자여야 합니다',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                );
              }
              return const SizedBox.shrink();
            }),
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(() => ElevatedButton(
                    onPressed: viewModel.isStudentIdValid.value
                        ? viewModel.nextStep
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '다음',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  )),
            ),
            const SizedBox(height: 24), // 키보드와의 간격을 위한 여백
          ],
        ),
      ),
    );
  }
}

class _PasswordStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final RegisterViewModel viewModel = Get.find<RegisterViewModel>();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: viewModel.previousStep,
            ),
            const SizedBox(height: 24),
            _buildStepIndicator(1),
            const SizedBox(height: 32),
            const Text(
              '비밀번호를 \n설정해주세요',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '8자 이상, 특수문자를 포함해야 합니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            Obx(() => _PasswordTextField(
                  onChanged: viewModel.setPassword,
                  labelText: '비밀번호',
                  isValid: viewModel.isPasswordValid.value,
                  password: viewModel.password.value,
                )),
            const SizedBox(height: 24),
            Obx(() => _PasswordTextField(
                  onChanged: viewModel.setConfirmPassword,
                  labelText: '비밀번호 확인',
                  isValid: viewModel.isPasswordMatch.value && viewModel.confirmPassword.value.isNotEmpty,
                  password: viewModel.confirmPassword.value,
                )),
            const SizedBox(height: 16),
            Obx(() {
              if (!viewModel.isPasswordValid.value && viewModel.password.value.isNotEmpty) {
                return const Text(
                  '비밀번호는 8자 이상, 특수문자를 포함해야 합니다.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                );
              }
              if (!viewModel.isPasswordMatch.value && viewModel.confirmPassword.value.isNotEmpty) {
                return const Text(
                  '비밀번호가 일치하지 않습니다.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 16),
            // 이메일 정보 표시
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: Colors.blue.shade300),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '이메일',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Obx(() => Text(
                            viewModel.email,
                            style: const TextStyle(fontSize: 16),
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Obx(() {
              final error = viewModel.errorMessage.value;
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
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Obx(() {
                if (viewModel.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ElevatedButton(
                  onPressed: (viewModel.isPasswordValid.value && viewModel.isPasswordMatch.value)
                      ? viewModel.register
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '회원가입 완료',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24), // 키보드와의 간격을 위한 여백
          ],
        ),
      ),
    );
  }
}

class _PasswordTextField extends StatefulWidget {
  final Function(String) onChanged;
  final String labelText;
  final bool isValid;
  final String password;

  const _PasswordTextField({
    required this.onChanged,
    required this.labelText,
    required this.isValid,
    required this.password,
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
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.password.isNotEmpty)
              Icon(
                widget.isValid ? Icons.check_circle : Icons.error,
                color: widget.isValid ? Colors.green : Colors.red,
                size: 20,
              ),
            IconButton(
              icon: Icon(
                _isVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _isVisible = !_isVisible;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildStepIndicator(int currentStep) {
  return Row(
    children: [
      _StepDot(isActive: currentStep >= 0, text: "1"),
      _StepLine(isActive: currentStep >= 1),
      _StepDot(isActive: currentStep >= 1, text: "2"),
    ],
  );
}

class _StepDot extends StatelessWidget {
  final bool isActive;
  final String text;

  const _StepDot({required this.isActive, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.blue : Colors.grey.shade300,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;

  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 2,
      color: isActive ? Colors.blue : Colors.grey.shade300,
    );
  }
}