import 'dart:convert';
import 'package:flutter/services.dart';

/// 시간표 관련 기능을 모아둔 헬퍼 클래스
class TimetableHelper {
  /// 시간표 데이터 로드
  static Future<Map<String, dynamic>> loadTimetable() async {
    final String jsonString =
        await rootBundle.loadString('assets/bus_times/bus_times.json');
    return json.decode(jsonString);
  }

  /// 시간표에서 배차 간격 계산
  static String calculateInterval(List<dynamic> times) {
    if (times.length < 2) return '-';

    try {
      List<int> intervals = [];
      for (int i = 0; i < times.length - 1; i++) {
        final current = _parseTime(times[i].toString());
        final next = _parseTime(times[i + 1].toString());
        intervals.add(_minutesBetween(current, next));
      }

      // 최빈값 계산
      Map<int, int> frequency = {};
      intervals.forEach((interval) {
        frequency[interval] = (frequency[interval] ?? 0) + 1;
      });

      final mostCommon =
          frequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      return '$mostCommon분';
    } catch (e) {
      return '-';
    }
  }

  /// 시간 문자열을 DateTime으로 변환
  static DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(2024, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// 두 시간 사이의 분 차이 계산
  static int _minutesBetween(DateTime time1, DateTime time2) {
    return time2.difference(time1).inMinutes;
  }
} 