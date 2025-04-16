// lib/view/login_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../viewmodel/login_viewmodel.dart';
import 'register_view.dart';

class LoginView extends StatelessWidget {
  final LoginViewModel _loginViewModel = Get.put(LoginViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        elevation: 0,
        backgroundColor: Platform.isIOS 
            ? CupertinoTheme.of(context).barBackgroundColor 
            : Theme.of(context).primaryColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // 로고 또는 앱 이름
                Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '환영합니다',
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // 플랫폼별 입력 필드
                if (Platform.isIOS) 
                  _buildIOSInputFields()
                else 
                  _buildAndroidInputFields(),
                const SizedBox(height: 32),
                // 로그인 버튼
                Obx(() {
                  if (_loginViewModel.isLoading.value) {
                    return Center(
                      child: Platform.isIOS 
                          ? const CupertinoActivityIndicator() 
                          : const CircularProgressIndicator(),
                    );
                  }
                  return Platform.isIOS 
                      ? CupertinoButton(
                          color: Theme.of(context).primaryColor,
                          onPressed: _loginViewModel.login,
                          child: const Text('로그인'),
                        )
                      : ElevatedButton(
                          onPressed: _loginViewModel.login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '로그인',
                            style: TextStyle(fontSize: 16),
                          ),
                        );
                }),
                
                // 회원가입 링크 - 간단한 텍스트 버튼으로 추가
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Get.to(() => RegisterView()),
                    child: Text(
                      '계정이 없으신가요? 회원가입',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                
                // 에러 메시지
                Obx(() {
                  final error = _loginViewModel.errorMessage.value;
                  if (error.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        error,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // iOS 스타일 입력 필드
  Widget _buildIOSInputFields() {
    return Column(
      children: [
        CupertinoTextField(
          prefix: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(CupertinoIcons.mail),
          ),
          placeholder: '이메일',
          keyboardType: TextInputType.emailAddress,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
          onChanged: _loginViewModel.setEmail,
        ),
        const SizedBox(height: 16),
        CupertinoTextField(
          prefix: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(CupertinoIcons.padlock),
          ),
          placeholder: '비밀번호',
          obscureText: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
          onChanged: _loginViewModel.setPassword,
        ),
      ],
    );
  }

  // 안드로이드 스타일 입력 필드
  Widget _buildAndroidInputFields() {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: '이메일',
            hintText: 'example@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: _loginViewModel.setEmail,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: '비밀번호',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          obscureText: true,
          onChanged: _loginViewModel.setPassword,
        ),
      ],
    );
  }
}
