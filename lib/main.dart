import 'package:flutter/material.dart';
          import 'package:get/get.dart';
          import 'view/home_view.dart';

          void main() async {
            WidgetsFlutterBinding.ensureInitialized();
            runApp(MyApp());
          }

          class MyApp extends StatelessWidget {
            @override
            Widget build(BuildContext context) {
              return GetMaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'University Transport App',
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
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.white,
                    background: Colors.white,
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
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.grey[900]!,
                    background: Colors.grey[900]!,
                    brightness: Brightness.dark,
                  ),
                  textTheme: Typography.whiteMountainView,
                  useMaterial3: true,
                ),
                themeMode: ThemeMode.system, // 시스템 설정에 따라 테마 변경
                home: HomeView(),
              );
            }
          }