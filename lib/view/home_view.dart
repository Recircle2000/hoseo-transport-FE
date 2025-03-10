import 'package:flutter/material.dart';
          import 'package:get/get.dart';
          import 'bus_map_view.dart';
          import 'settings_view.dart';

          class HomeView extends StatelessWidget {
            @override
            Widget build(BuildContext context) {
              return Scaffold(
                appBar: AppBar(
                  title: Text('교통 서비스 앱'),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: () {
                        Get.to(() => SettingsView());
                      },
                    ),
                  ],
                ),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => BusMapView());
                    },
                    child: Text('시내버스 위치 보기'),
                  ),
                ),
              );
            }
          }