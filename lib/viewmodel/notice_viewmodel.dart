import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notice_model.dart';
import '../utils/env_config.dart';

class NoticeViewModel extends GetxController {
  final notice = Rxn<Notice>();
  final isLoading = false.obs;
  final error = ''.obs;
  final allNotices = <Notice>[].obs;


  @override
  void onInit() {
    super.onInit();
    fetchLatestNotice();
  }

  Future<void> fetchAllNotices() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/notices'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = utf8.decode(response.bodyBytes);
        final jsonList = json.decode(data) as List;
        allNotices.value = jsonList.map((json) => Notice.fromJson(json)).toList();
      } else {
        error.value = '공지사항을 불러오는데 실패했습니다';
      }
    } catch (e) {
      error.value = '네트워크 오류가 발생했습니다';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchLatestNotice() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/notices/latest'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = utf8.decode(response.bodyBytes);
        final jsonData = json.decode(data);
        print(jsonData);
        notice.value = Notice.fromJson(jsonData);
      } else {
        error.value = '공지사항을 불러오는데 실패했습니다';
      }
    } catch (e) {
      error.value = '네트워크 오류가 발생했습니다';
    } finally {
      isLoading.value = false;
    }
  }

  String _getBaseUrl() {
    if (GetPlatform.isAndroid) {
      return EnvConfig.baseUrl;
    } else if (GetPlatform.isIOS) {
      return EnvConfig.baseUrl;
    }
    return "http://127.0.0.1:8000";
  }
}
