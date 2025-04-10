// lib/view/register_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodel/register_viewmodel.dart';

class RegisterView extends StatelessWidget {
  final RegisterViewModel _registerViewModel = Get.put(RegisterViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              onChanged: _registerViewModel.setEmail,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'example@email.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: _registerViewModel.setPassword,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                hintText: '6자 이상 입력해주세요',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            Obx(() {
              if (_registerViewModel.isLoading.value) {
                return const CircularProgressIndicator();
              }
              return ElevatedButton(
                onPressed: _registerViewModel.register,
                child: const Text('회원가입'),
              );
            }),
            Obx(() {
              final error = _registerViewModel.errorMessage.value;
              if (error.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
