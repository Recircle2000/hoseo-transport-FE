// lib/view/settings_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'auth/login_view.dart';

class SettingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '설정',
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: GetBuilder<SettingsViewModel>(
        init: SettingsViewModel(),
        builder: (controller) => ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const SizedBox(height: 8),
            Text(
              '기준 캠퍼스 선택',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.surfaceVariant),
              ),
              child: Column(
                children: [
                  Obx(() => RadioListTile<String>(
                        title: Text(
                          '아산캠퍼스',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: controller.selectedCampus.value == '아산'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        value: '아산',
                        groupValue: controller.selectedCampus.value,
                        onChanged: (value) => controller.setCampus(value!),
                        activeColor: colorScheme.primary,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                      )),
                  Divider(height: 1, color: colorScheme.surfaceVariant),
                  Obx(() => RadioListTile<String>(
                        title: Text(
                          '천안캠퍼스',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: controller.selectedCampus.value == '천안'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        value: '천안',
                        groupValue: controller.selectedCampus.value,
                        onChanged: (value) => controller.setCampus(value!),
                        activeColor: colorScheme.primary,
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
