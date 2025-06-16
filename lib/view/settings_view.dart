// lib/view/settings_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'auth/login_view.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
            // 버전 정보
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Center(
                    child: Text(
                      '버전 ${snapshot.data!.version}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 8),
            // 개인정보처리방침/지원 링크
            Center(
              child: TextButton(
                onPressed: () async {
                  final Uri url = Uri.parse('https://www.notion.so/1eda668f263380ff92aae3ac8b74b157?pvs=4');
                  try {
                    if (await canLaunchUrl(url)) {
                      // 브라우저에서 열기 위한 옵션 추가
                      final bool launched = await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                        webViewConfiguration: const WebViewConfiguration(
                          enableJavaScript: true,
                          enableDomStorage: true,
                        ),
                      );

                      if (!launched) {
                        throw Exception('URL 실행 실패');
                      }
                    } else {
                      throw Exception('URL을 실행할 수 없음');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('링크를 열 수 없습니다'))
                      );
                    }
                  }
                },
                child: Text(
                  '개인정보처리방침 / 지원',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // 오픈소스 라이선스
            Center(
              child: TextButton(
                onPressed: () async {
                  final packageInfo = await PackageInfo.fromPlatform();
                  if (context.mounted) {
                    showLicensePage(
                      context: context,
                      applicationName: '호통',
                      applicationVersion: packageInfo.version,
                      applicationLegalese: '© 2025 호통\n\n이 앱은 다음 오픈소스 라이브러리들을 사용합니다:',
                    );
                  }
                },
                child: Text(
                  '오픈소스 라이선스',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
