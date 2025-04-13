import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart'; // SystemChrome을 사용하기 위한 임포트
import 'view/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 화면 자동 회전 비활성화 - 세로 모드만 허용
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'University Transport App',
      // lib/main.dart의 theme 부분 수정
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        cardTheme: CardTheme(
          color: Colors.grey[100],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey, // 기본 색상
          background: Colors.white,
          surface: Colors.white,
          surfaceVariant: Colors.grey[100]!,
          onSurfaceVariant: Colors.grey[800]!,
          primary: Colors.grey[800]!, // 주요 액센트 색상
          onPrimary: Colors.white,
          secondary: Colors.grey[600]!, // 보조 색상
          onSecondary: Colors.white,
          tertiary: Colors.grey[400]!, // 삼차 색상
          onTertiary: Colors.black,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.black),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.grey[900],
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        cardTheme: CardTheme(
          color: Colors.grey[850],
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey[900]!, // 기본 색상
          background: Colors.grey[900]!,
          surface: Colors.grey[900]!,
          surfaceVariant: Colors.grey[850]!,
          onSurfaceVariant: Colors.grey[300]!,
          primary: Colors.grey[300]!, // 주요 액센트 색상
          onPrimary: Colors.grey[900]!,
          secondary: Colors.grey[500]!, // 보조 색상
          onSecondary: Colors.black,
          tertiary: Colors.grey[600]!, // 삼차 색상
          onTertiary: Colors.white,
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.white),
            foregroundColor: MaterialStateProperty.all(Colors.black),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        textTheme: Typography.whiteMountainView,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // 시스템 설정에 따라 테마 변경
      home: HomeView(),
    );
  }
}