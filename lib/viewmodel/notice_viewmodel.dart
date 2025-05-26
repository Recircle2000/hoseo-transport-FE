import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/notice_model.dart';
import '../utils/env_config.dart';
import 'package:flutter/painting.dart';

class NoticeViewModel extends GetxController {
  final notice = Rxn<Notice>();
  final isLoading = false.obs;
  final error = ''.obs;
  final allNotices = <Notice>[].obs;
  final filteredNotices = <Notice>[].obs;
  final selectedFilter = '전체'.obs;

  // 필터 옵션
  final filterOptions = ['전체', '앱', '업데이트', '셔틀버스', '시내버스'];

  @override
  void onInit() {
    super.onInit();
    fetchLatestNotice();
    fetchAllNotices();
  }

  // 필터 변경
  void changeFilter(String filter) {
    selectedFilter.value = filter;
    _applyFilter();
  }

  // 필터 적용
  void _applyFilter() {
    if (selectedFilter.value == '전체') {
      filteredNotices.value = List.from(allNotices);
    } else {
      String noticeType = _getNoticeTypeFromFilter(selectedFilter.value);
      filteredNotices.value = allNotices.where((notice) => notice.noticeType == noticeType).toList();
    }
  }

  // 필터명을 API의 notice_type으로 변환
  String _getNoticeTypeFromFilter(String filter) {
    switch (filter) {
      case '앱':
        return 'App';
      case '업데이트':
        return 'update';
      case '셔틀버스':
        return 'shuttle';
      case '시내버스':
        return 'citybus';
      default:
        return 'App';
    }
  }

  // notice_type을 한글로 변환
  String getNoticeTypeDisplayName(String noticeType) {
    switch (noticeType) {
      case 'App':
        return '앱';
      case 'update':
        return '업데이트';
      case 'shuttle':
        return '셔틀버스';
      case 'citybus':
        return '시내버스';
      default:
        return '앱';
    }
  }

  // notice_type에 따른 배경색 반환
  Color getNoticeTypeColor(String noticeType) {
    switch (noticeType) {
      case 'App':
        return const Color(0xFF9E9E9E); // 회색
      case 'update':
        return const Color(0xFFFF9800); // 주황색
      case 'shuttle':
        return const Color(0xFFB83227); // 메인메뉴 셔틀버스 붉은색
      case 'citybus':
        return const Color(0xFF2196F3); // 메인메뉴 시내버스 파란색
      default:
        return const Color(0xFF9E9E9E);
    }
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
        _applyFilter(); // 데이터 로드 후 필터 적용
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
    return EnvConfig.baseUrl;
  }
}
