// lib/view/register_view.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../viewmodel/register_viewmodel.dart';

class RegisterView extends StatelessWidget {
  final RegisterViewModel _registerViewModel = Get.put(RegisterViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        elevation: 0,
        backgroundColor: Platform.isIOS 
            ? CupertinoTheme.of(context).barBackgroundColor 
            : Theme.of(context).primaryColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 스크롤 가능한 메인 콘텐츠
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      // 회원가입 아이콘
                      Center(
                        child: Icon(
                          Icons.person_add_outlined,
                          size: 70,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '새 계정 만들기',
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // 플랫폼별 입력 필드
                      if (Platform.isIOS) 
                        _buildIOSInputFields()
                      else 
                        _buildAndroidInputFields(),
                      const SizedBox(height: 32),
                      // 회원가입 버튼
                      Obx(() {
                        if (_registerViewModel.isLoading.value) {
                          return Center(
                            child: Platform.isIOS 
                                ? const CupertinoActivityIndicator() 
                                : const CircularProgressIndicator(),
                          );
                        }
                        return Platform.isIOS 
                            ? CupertinoButton(
                                color: Theme.of(context).primaryColor,
                                onPressed: _registerViewModel.register,
                                child: const Text('회원가입'),
                              )
                            : ElevatedButton(
                                onPressed: _registerViewModel.register,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  '회원가입',
                                  style: TextStyle(fontSize: 16),
                                ),
                              );
                      }),
                      // 에러 메시지
                      Obx(() {
                        final error = _registerViewModel.errorMessage.value;
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
                      const SizedBox(height: 20),
                      // 로그인 링크 - 간단한 텍스트 버튼으로 추가
                      Center(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            '이미 계정이 있으신가요? 로그인',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          onChanged: _registerViewModel.setEmail,
        ),
        const SizedBox(height: 16),
        CupertinoTextField(
          prefix: const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Icon(CupertinoIcons.padlock),
          ),
          placeholder: '비밀번호 (6자 이상)',
          obscureText: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemGrey4),
            borderRadius: BorderRadius.circular(8),
          ),
          onChanged: _registerViewModel.setPassword,
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
          onChanged: _registerViewModel.setEmail,
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: '비밀번호',
            hintText: '6자 이상 입력해주세요',
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          obscureText: true,
          onChanged: _registerViewModel.setPassword,
        ),
      ],
    );
  }
}
