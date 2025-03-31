import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'login_view.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
      ),
      body: GetBuilder<SettingsViewModel>(
        init: SettingsViewModel(),
        builder: (controller) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('계정 정보:', style: TextStyle(fontSize: 18)),
              SizedBox(height: 10),
              Obx(() => Text('이메일: ${controller.email.value}', style: TextStyle(fontSize: 16))),
              SizedBox(height: 20),
              Obx(() => controller.isLoggedIn.value
                ? ElevatedButton(
                    onPressed: controller.logout,
                    child: Text('로그아웃'),
                  )
                : ElevatedButton(
                    onPressed: () => Get.to(() => LoginView()),
                    child: Text('로그인'),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}