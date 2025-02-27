import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'view/login_view.dart';  // 로그인 화면 import

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,  // 디버그 배너 숨김
      title: 'University Transport App',
      theme: ThemeData(
        primarySwatch: Colors.blue,  // 기본 테마 색상 설정
      ),
      home: LoginView(),  // 첫 화면으로 LoginView 설정
    );
  }
}