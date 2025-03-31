// lib/view/settings_view.dart
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
        builder: (controller) => ListView(
          padding: const EdgeInsets.all(16.0),
          children: [


            // 계정 섹션
            Text(
              '계정 정보',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                          '이메일: ${controller.email.value}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        )),
                    const SizedBox(height: 16),
                    Obx(() => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.isLoggedIn.value
                                ? controller.logout
                                : () => Get.to(() => LoginView()),
                            child: Text(
                              controller.isLoggedIn.value ? '로그아웃' : '로그인',
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 캠퍼스 선택 섹션
            Text(
              '캠퍼스 선택',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  Obx(() => RadioListTile<String>(
                    title: const Text('아산캠퍼스'),
                    value: '아산',
                    groupValue: controller.selectedCampus.value,
                    onChanged: (value) => controller.setCampus(value!),
                  )),
                  Obx(() => RadioListTile<String>(
                    title: const Text('천안캠퍼스'),
                    value: '천안',
                    groupValue: controller.selectedCampus.value,
                    onChanged: (value) => controller.setCampus(value!),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
