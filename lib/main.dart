import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'view/home_view.dart';
import 'utils/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("앱 시작");
  // .env 파일 로드
  await EnvConfig.init();
  await FlutterNaverMap().init(
    clientId: EnvConfig.naverMapClientId,
      onAuthFailed: (ex) => switch (ex) {
        NQuotaExceededException(:final message) =>
            print("사용량 초과 (message: $message)"),
        NUnauthorizedClientException() ||
        NClientUnspecifiedException() ||
        NAnotherAuthFailedException() =>
            print("인증 실패: $ex"),
      }
  );
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
      home: DisclaimerManager(),
    );
  }
}

class DisclaimerManager extends StatefulWidget {
  @override
  _DisclaimerManagerState createState() => _DisclaimerManagerState();
}

class _DisclaimerManagerState extends State<DisclaimerManager> {
  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 팝업 표시 여부 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
    });
  }

  // 앱 최초 실행 여부 확인 및 팝업 표시
  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstRun = prefs.getBool('first_run') ?? true;

    if (isFirstRun) {
      // 최초 실행으로 표시를 저장
      await prefs.setBool('first_run', false);
      // 면책 사항 팝업 표시
      _showDisclaimerDialog();
    }
  }

  // 면책 사항 다이얼로그 표시
  void _showDisclaimerDialog() {
    if (Platform.isIOS) {
      _showIOSDisclaimerDialog();
    } else {
      _showAndroidDisclaimerDialog();
    }
  }

  // iOS용 면책 사항 다이얼로그
  void _showIOSDisclaimerDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Text('서비스 이용 안내'),
        content: Text(
          '이 앱은 공식 애플리케이션이 아닙니다.\n\n'
          '시내버스 정보는 실시간 데이터 갱신이 지연될 수 있으며,\n\n'
          '셔틀버스 정보는 도로 교통 상황에 따라 지연될 수 있습니다.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('확인했습니다'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  // Android용 면책 사항 다이얼로그
  void _showAndroidDisclaimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('서비스 이용 안내'),
        content: Text(
          '이 앱은 공식 애플리케이션이 아닙니다.\n\n'
          '시내버스 정보는 실시간 데이터 갱신이 지연될 수 있으며,\n\n'
          '셔틀버스 정보는 도로 교통 상황에 따라 지연될 수 있습니다.',
        ),
        actions: [
          TextButton(
            child: Text('확인했습니다'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeView();
  }
}