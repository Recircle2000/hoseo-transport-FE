// lib/view/login_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/login_viewmodel.dart';
import 'register_view.dart';

class LoginView extends StatelessWidget {
  final LoginViewModel _loginViewModel = Get.put(LoginViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'example@email.com',
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: _loginViewModel.setEmail,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: '비밀번호',
              ),
              obscureText: true,
              onChanged: _loginViewModel.setPassword,
            ),
            const SizedBox(height: 24),
            Obx(() {
              if (_loginViewModel.isLoading.value) {
                return const CircularProgressIndicator();
              }
              return ElevatedButton(
                onPressed: _loginViewModel.login,
                child: const Text('로그인'),
              );
            }),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.to(() => RegisterView()),
              child: const Text('회원가입'),
            ),
            Obx(() {
              final error = _loginViewModel.errorMessage.value;
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
