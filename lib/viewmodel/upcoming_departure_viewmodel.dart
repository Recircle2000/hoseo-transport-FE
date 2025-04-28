import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'settings_viewmodel.dart';

class BusDeparture {
  final String routeName;
  final String destination;
  final DateTime departureTime;
  final int minutesLeft;

  BusDeparture({
    required this.routeName,
    required this.destination,
    required this.departureTime,
    required this.minutesLeft,
  });
}

class UpcomingDepartureViewModel extends GetxController {
  final settingsViewModel = Get.find<SettingsViewModel>();
  
  // 데이터 관련 변수들
  var isLoading = true.obs;
  var error = ''.obs;
  
  // 곧 출발 데이터
  final upcomingCityBuses = <BusDeparture>[].obs;
  final upcomingShuttles = <BusDeparture>[].obs;
  
  // 로딩 타이머
  Timer? _refreshTimer;
  
  // 새로고침 콜백 - UI와 동기화하기 위함
  Function? _onRefreshCallback;
  
  void setRefreshCallback(Function callback) {
    _onRefreshCallback = callback;
  }
  
  @override
  void onInit() {
    super.onInit();
    loadData();
    
    // 30초마다 자동 업데이트
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      print('자동 새로고침');
      loadData();
      // 콜백 호출로 UI의 카운트다운도 초기화
      _onRefreshCallback?.call();
    });
    
    // 캠퍼스 설정이 변경되면 데이터 다시 로드
    ever(settingsViewModel.selectedCampus, (_) => loadData());
  }
  
  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
  
  Future<void> loadData() async {
    isLoading.value = true;
    error.value = '';
    
    try {
      // 시내버스 데이터 로드
      await loadCityBusData();
      
      // 셔틀버스 데이터 로드
      await loadShuttleData();
    } catch (e) {
      error.value = '데이터 로드 중 오류가 발생했습니다: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> loadCityBusData() async {
    try {
      // 현재 캠퍼스 확인
      final currentCampus = settingsViewModel.selectedCampus.value;
      
      // bus_times.json 파일 읽기
      final String jsonData = await rootBundle.loadString('assets/bus_times/bus_times.json');
      final Map<String, dynamic> busData = json.decode(jsonData);
      
      // 현재 시간 가져오기
      final now = DateTime.now();
      
      // 곧 출발하는 버스 리스트
      final upcomingBuses = <BusDeparture>[];
      
      // 캠퍼스에 따라 다른 출발지 설정
      final String departurePlace = currentCampus == '천안' ? '호서대학교 천안캠퍼스' : '호서대학교 기점';
      
      // 천안캠퍼스인 경우는 아직 실제 데이터가 없으므로 빈 배열 반환
      if (currentCampus == '천안') {
        upcomingCityBuses.value = [];
        return;
      }
      
      // 아산캠퍼스인 경우 기존 로직 사용
      // 데이터 순회하며 호서대학교 기점인 버스 찾기
      busData.forEach((routeKey, routeData) {
        if (routeData['출발지'] == departurePlace) {
          final List<dynamic> timeList = routeData['시간표'];
          final String destination = routeData['종점'];
          
          for (final timeStr in timeList) {
            final parts = timeStr.split(':');
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            final second = 0; // 시내버스는 초 정보가 없으므로 0으로 설정
            
            // 오늘 날짜에 시간 더해서 출발 시간 생성
            final departureTime = DateTime(
              now.year, now.month, now.day, hour, minute, second
            );
            
            // 현재시간과 출발시간 사이의 차이 계산
            final difference = departureTime.difference(now);
            
            // 차이를 분으로 계산 (올림)
            final minutesLeft = (difference.inSeconds / 60).ceil();
            
            // 앞으로 60분 내에 출발하고, 이미 출발한 시간이 아닌 경우만 포함
            if (difference.inSeconds > 0 && difference.inMinutes <= 60) {
              upcomingBuses.add(BusDeparture(
                routeName: routeKey.split('_')[0], // 노선 이름 (예: 순환5)
                destination: destination,
                departureTime: departureTime,
                minutesLeft: minutesLeft == 0 ? 1 : minutesLeft, // 1분 미만은 1분으로 표시
              ));
            }
          }
        }
      });
      
      // 출발시간 기준으로 정렬
      upcomingBuses.sort((a, b) => a.minutesLeft.compareTo(b.minutesLeft));
      
      // 최대 3개만 표시
      upcomingCityBuses.value = upcomingBuses.take(3).toList();
    } catch (e) {
      print('시내버스 데이터 로드 중 오류: $e');
      upcomingCityBuses.clear();
    }
  }

  Future<void> loadShuttleData() async {
    try {
      // 현재 캠퍼스 확인
      final currentCampus = settingsViewModel.selectedCampus.value;
      
      // 캠퍼스에 따라 정류장 ID 설정
      final int stationId = (currentCampus == '천안') ? 14 : 1;
      
      // 캠퍼스에 따라 정류장 이름 설정
      final String stationName = (currentCampus == '천안') ? '천안캠퍼스(출발)' : '아산캠퍼스(출발)';
      
      // 스케줄 타입 확인 (평일/토요일/공휴일)
      final scheduleType = await _getScheduleType();
      print(scheduleType);
      
      // API 요청
      final response = await http.get(
        Uri.parse('http://52.78.121.35:8000/shuttle/stations/$stationId/schedules'),
        headers: {'Accept-Charset': 'UTF-8'}
      );
      
      if (response.statusCode == 200) {
        // UTF-8로 응답 데이터 디코딩
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> schedulesData = json.decode(decodedBody);
        print(schedulesData);
        
        // 현재 시간 가져오기
        final now = DateTime.now();
        
        // 노선 정보와 스케줄 매핑 위한 맵
        final Map<int, String> routeNames = {};
        
        // 곧 출발하는 셔틀 리스트
        final upcomingShuttleList = <BusDeparture>[];
        
        // 스케줄 타입에 맞는 스케줄 필터링
        final filteredSchedules = schedulesData.where((schedule) => 
            schedule['schedule_type'] == scheduleType && 
            schedule['station_name'] == stationName).toList();
        
        // 각 스케줄에 대해 출발 시간 계산
        for (final schedule in filteredSchedules) {
          final int routeId = schedule['route_id'];
          
          // 아직 해당 노선 정보가 없는 경우, API 호출로 가져오기
          if (!routeNames.containsKey(routeId)) {
            try {
              final routeResponse = await http.get(
                Uri.parse('http://52.78.121.35:8000/shuttle/routes?route_id=$routeId'),
                headers: {'Accept-Charset': 'UTF-8'}
              );
              
              if (routeResponse.statusCode == 200) {
                // UTF-8로 응답 데이터 디코딩
                final String decodedRouteBody = utf8.decode(routeResponse.bodyBytes);
                final List<dynamic> routeData = json.decode(decodedRouteBody);
                print(routeData);
                if (routeData.isNotEmpty) {
                  routeNames[routeId] = routeData[0]['route_name'];
                }
              }
            } catch (e) {
              print('노선 정보 로드 중 오류: $e');
              routeNames[routeId] = '노선 $routeId';
            }
          }
          
          // 도착 시간 파싱
          final arrivalTimeStr = schedule['arrival_time'];
          final timeParts = arrivalTimeStr.split(':');
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
          
          // 오늘 날짜에 시간 더해서 출발 시간 생성
          final departureTime = DateTime(
            now.year, now.month, now.day, hour, minute, second
          );
          
          // 현재시간과 출발시간 사이의 차이 계산
          final difference = departureTime.difference(now);
          
          // 차이를 분으로 계산 (올림)
          final minutesLeft = (difference.inSeconds / 60).ceil();
          
          // 앞으로 60분 내에 출발하고, 이미 출발한 시간이 아닌 경우만 포함
          // 같은 분(예: 3시 59분 → 4시 00분)이라도 초가 남아있으면 표시
          if (difference.inSeconds > 0 && difference.inMinutes <= 60) {
            upcomingShuttleList.add(BusDeparture(
              routeName: '셔틀',
              destination: routeNames[routeId] ?? '알 수 없음',
              departureTime: departureTime,
              minutesLeft: minutesLeft == 0 ? 1 : minutesLeft, // 1분 미만은 1분으로 표시
            ));
          }
        }
        
        // 출발시간 기준으로 정렬
        upcomingShuttleList.sort((a, b) => a.minutesLeft.compareTo(b.minutesLeft));
        
        // 최대 3개만 표시
        upcomingShuttles.value = upcomingShuttleList.take(3).toList();
      } else {
        print('API 오류: ${response.statusCode}');
        upcomingShuttles.clear();
      }
    } catch (e) {
      print('셔틀버스 데이터 로드 중 오류: $e');
      upcomingShuttles.clear();
    }
  }
  
  Future<String> _getScheduleType() async {
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1-월요일, 7-일요일
    
    // 일요일
    if (dayOfWeek == 7) {
      print('일요일');
      return 'Holiday';
    }
    
    // 토요일
    if (dayOfWeek == 6) {
      print('토요일');
      return 'Saturday';
    }
    
    // 공휴일 확인
    try {
      final isHoliday = await _checkIfHoliday(now);
      if (isHoliday) {
        print('공휴일');
        return 'Holiday';
      }
    } catch (e) {
      print('공휴일 확인 중 오류: $e');
    }
    
    // 기본값은 평일
    return 'Weekday';
  }
  
  Future<bool> _checkIfHoliday(DateTime date) async {
    try {
      // 공휴일 JSON 파일 로드
      final String holidayJson = await rootBundle.loadString('assets/Holiday/2025Holiday.json');
      final List<dynamic> holidays = json.decode(holidayJson);
      
      // 날짜 포맷 설정 (YYYYMMDD)
      final dateStr = DateFormat('yyyyMMdd').format(date);
      
      // 공휴일 목록에서 오늘 날짜 찾기
      return holidays.any((holiday) => holiday['date'] == dateStr);
    } catch (e) {
      print('공휴일 확인 중 오류: $e');
      // 파일 로드에 실패해도 기능은 계속 동작하도록 함
      return false;
    }
  }
} 