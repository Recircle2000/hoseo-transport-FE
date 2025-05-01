import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io' show Platform;
import 'view/home_view.dart';
import 'utils/env_config.dart';
import 'utils/location_service.dart';
import 'utils/platform_utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'viewmodel/settings_viewmodel.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env 파일 먼저 로드
  await dotenv.load(fileName: 'assets/.env');
  await FlutterNaverMap().init(
      clientId: EnvConfig.naverMapClientId,
      onAuthFailed: (ex) => switch (ex) {
            NQuotaExceededException(:final message) =>
              print("사용량 초과 (message: $message)"),
            NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException() =>
              print("인증 실패: $ex"),
          });

  print("앱 시작");
  // 위치 서비스 초기화
  await LocationService().initLocationService();
  // 화면 자동 회전 비활성화 - 세로 모드만 허용
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Settings ViewModel 등록
  Get.put(SettingsViewModel(), permanent: true);
  
  // RouteObserver 등록
  Get.put(RouteObserver<PageRoute>(), permanent: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routeObserver = Get.find<RouteObserver<PageRoute>>();
    
    return GetMaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', ''), // 한국어
        Locale('en', ''), // 영어
      ],
      debugShowCheckedModeBanner: false,
      title: 'University Transport App',
      // 라우트 옵저버 등록
      navigatorObservers: [routeObserver],
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
      PlatformUtils.showPlatformDisclaimerDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeView();
  }
}