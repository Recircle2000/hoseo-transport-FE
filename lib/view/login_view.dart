import 'package:flutter/material.dart';
            import 'package:get/get.dart';
            import '../viewmodel/login_viewmodel.dart';
            import 'register_view.dart';

            class LoginView extends StatelessWidget {
              final LoginController _loginController = Get.put(LoginController()); // Controller 등록

              @override
              Widget build(BuildContext context) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text('Login'),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 이메일 입력 필드
                        TextField(
                          decoration: InputDecoration(labelText: 'Email'),
                          onChanged: (value) => _loginController.email.value = value,
                        ),
                        // 비밀번호 입력 필드
                        TextField(
                          decoration: InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          onChanged: (value) => _loginController.password.value = value,
                        ),
                        SizedBox(height: 20),
                        // 로그인 버튼
                        Obx(() => _loginController.isLoading.value
                            ? CircularProgressIndicator() // 로딩 중일 때 스피너 표시
                            : ElevatedButton(
                          onPressed: _loginController.login,
                          child: Text('Login'),
                        )),
                        SizedBox(height: 20),
                        // 회원가입 버튼
                        TextButton(
                          onPressed: () {
                            Get.to(() => RegisterView());
                          },
                          child: Text('Register'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }