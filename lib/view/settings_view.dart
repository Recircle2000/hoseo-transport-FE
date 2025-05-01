// lib/view/settings_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'auth/login_view.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
      ),
      body: GetBuilder<SettingsViewModel>(
        init: SettingsViewModel(),
        builder: (controller) => ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const SizedBox(height: 8),
            Text(
              '기준 캠퍼스 선택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Obx(() => RadioListTile<String>(
                        title: Text(
                          '아산캠퍼스',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            fontWeight: controller.selectedCampus.value == '아산'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        value: '아산',
                        groupValue: controller.selectedCampus.value,
                        onChanged: (value) => controller.setCampus(value!),
                        activeColor: Colors.blue[700],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                      )),
                  Divider(height: 1, color: Colors.grey[200]),
                  Obx(() => RadioListTile<String>(
                        title: Text(
                          '천안캠퍼스',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            fontWeight: controller.selectedCampus.value == '천안'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        value: '천안',
                        groupValue: controller.selectedCampus.value,
                        onChanged: (value) => controller.setCampus(value!),
                        activeColor: Colors.blue[700],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
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
