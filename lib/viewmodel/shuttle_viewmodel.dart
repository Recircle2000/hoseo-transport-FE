import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/shuttle_models.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../utils/env_config.dart';

class ShuttleViewModel extends GetxController {
  final RxList<ShuttleRoute> routes = <ShuttleRoute>[].obs;
  final RxList<Schedule> schedules = <Schedule>[].obs;
  final RxList<ScheduleStop> scheduleStops = <ScheduleStop>[].obs;
  final RxList<ShuttleStation> stations = <ShuttleStation>[].obs;
  
  // 선택된 아이템 관리
  final RxInt selectedRouteId = (-1).obs;
  final RxString selectedScheduleType = ''.obs;
  final RxInt selectedScheduleId = (-1).obs;
  
  // 로딩 상태 관리
  final RxBool isLoadingRoutes = false.obs;
  final RxBool isLoadingSchedules = false.obs;
  final RxBool isLoadingStops = false.obs;
  final RxBool isLoadingStations = false.obs;
  
  // API 기본 URL
  final String baseUrl = '${EnvConfig.baseUrl}/shuttle'; // 환경 변수에서 가져옴

  // 운행 일자 타입 목록
  final List<String> scheduleTypes = ['Weekday', 'Saturday', 'Holiday'];
  
  // 운행 일자 타입 한글 매핑
  final Map<String, String> scheduleTypeNames = {
    'Weekday': '평일',
    'Saturday': '토요일',
    'Holiday': '일요일/공휴일'
  };
  
  // 기본값 설정
  final RxBool useDefaultValues = true.obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchRoutes().then((_) {
      // 라우트 로딩이 완료된 후 기본값 설정
      if (useDefaultValues.value) {
        setDefaultValues();
      }
    });
  }
  
  // 기본값 설정 함수
  void setDefaultValues() {
    try {
      // 현재 요일에 따라 기본 스케줄 타입 설정
      setDefaultScheduleType();
      
      // 첫 번째 라우트를 기본값으로 설정 (API 호출 없이)
      if (routes.isNotEmpty && selectedRouteId.value == -1) {
        // selectRoute가 API를 호출하지 않도록 직접 값만 설정
        selectedRouteId.value = routes.first.id;
      }
    } catch (e) {
      print('기본값 설정 중 오류 발생: $e');
    }
  }
  
  // 현재 요일에 따라 기본 스케줄 타입 설정
  void setDefaultScheduleType() {
    try {
      final now = DateTime.now();
      final currentDay = DateFormat('EEEE').format(now);
      
      String defaultType;
      if (currentDay == 'Saturday') {
        defaultType = 'Saturday';
      } else if (currentDay == 'Sunday') {
        defaultType = 'Holiday';
      } else {
        defaultType = 'Weekday';
      }
      
      // 기본값 설정 (selectedScheduleType이 빈 문자열인 경우에만)
      if (selectedScheduleType.value.isEmpty) {
        selectedScheduleType.value = defaultType;
      }
    } catch (e) {
      print('기본 스케줄 타입 설정 중 오류 발생: $e');
      // 오류 발생 시 기본값으로 평일 설정
      if (selectedScheduleType.value.isEmpty) {
        selectedScheduleType.value = 'Weekday';
      }
    }
  }
  
  // 기본값 사용 여부 설정
  void setUseDefaultValues(bool value) {
    useDefaultValues.value = value;
    if (value) {
      setDefaultValues();
    }
  }
  
  // 노선 목록 조회
  Future<void> fetchRoutes() async {
    isLoadingRoutes.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/routes'));
      
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes); // UTF-8 디코딩 적용
        final List<dynamic> data = json.decode(decodedBody);
        print('API 응답 데이터: ${utf8.decode(response.bodyBytes)}');
        routes.value = data.map((item) => ShuttleRoute.fromJson(item)).toList();
      } else {
        throw Exception('노선 목록을 불러오는데 실패했습니다 (${response.statusCode})');
      }
    } catch (e) {
      print('노선 목록을 불러오는데 실패했습니다: $e');
      Get.snackbar(
        '오류',
        '노선 정보를 불러오는데 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 3),
      );
      
      // 테스트 더미 데이터
      if (routes.isEmpty) {
        routes.add(ShuttleRoute(id: 1, routeName: '테스트 노선', direction: '상행'));
        routes.add(ShuttleRoute(id: 2, routeName: '테스트 노선', direction: '하행'));
      }
    } finally {
      isLoadingRoutes.value = false;
    }
  }
  
  // 시간표 조회
  Future<bool> fetchSchedules(int routeId, String scheduleType) async {
    isLoadingSchedules.value = true;
    schedules.clear();
    selectedScheduleId.value = -1;
    scheduleStops.clear();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules?route_id=$routeId&schedule_type=$scheduleType')
      );
      
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes); // UTF-8 디코딩 적용
        final List<dynamic> data = json.decode(decodedBody);
        print('API 응답 데이터: ${utf8.decode(response.bodyBytes)}');
        
        // 데이터 시간순으로 정렬
        data.sort((a, b) {
          final aTime = a['start_time'];
          final bTime = b['start_time'];
          return aTime.compareTo(bTime);
        });
        
        // 정렬된 데이터에 회차 정보 추가 (1회차부터 시작)
        for (int i = 0; i < data.length; i++) {
          data[i]['round'] = i + 1;
        }
        
        schedules.value = data.map((item) => Schedule.fromJson(item)).toList();
        
        // 현재 시간에 가장 가까운 스케줄 자동 선택 (옵션)
        if (useDefaultValues.value && schedules.isNotEmpty) {
          selectNearestSchedule();
        }
        return true;
      } else if (response.statusCode == 404) {
        // 404 오류: 해당 노선/일자에 운행 정보가 없음
        print('해당 날짜에 운행하는 셔틀노선이 없습니다 (404)');
        return false;
      } else {
        // 기타 서버 오류
        throw Exception('시간표를 불러오는데 실패했습니다 (${response.statusCode})');
      }
    } catch (e) {
      print('시간표를 불러오는데 실패했습니다: $e');
      
      // 서버 응답 없음 - 더미 데이터 추가
      Get.snackbar(
        '서버 연결 오류',
        '서버에 연결할 수 없어 임시 데이터를 표시합니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
        duration: Duration(seconds: 3),
      );
      
      if (schedules.isEmpty) {
        final now = DateTime.now();
        // 현재 시간부터 30분 간격으로 3개의 스케줄 생성
        for (int i = 0; i < 3; i++) {
          schedules.add(Schedule(
            id: i + 1,
            routeId: routeId,
            scheduleType: scheduleType,
            startTime: now.add(Duration(minutes: 30 * i)),
            round: i + 1
          ));
        }
      }
      return true; // 더미 데이터로 대체되었으므로 성공으로 처리
    } finally {
      isLoadingSchedules.value = false;
    }
  }
  
  // 현재 시간에 가장 가까운 스케줄 선택
  void selectNearestSchedule() {
    try {
      final now = DateTime.now();
      
      // 현재 시간 이후의 가장 가까운 스케줄 찾기
      final futureSchedules = schedules.where(
        (schedule) => schedule.startTime.isAfter(now)
      ).toList();
      
      if (futureSchedules.isNotEmpty) {
        // 시간 기준으로 정렬
        futureSchedules.sort((a, b) => a.startTime.compareTo(b.startTime));
        selectSchedule(futureSchedules.first.id);
      } else if (schedules.isNotEmpty) {
        // 이후 스케줄이 없다면 마지막 스케줄 선택
        selectSchedule(schedules.last.id);
      }
    } catch (e) {
      print('가장 가까운 스케줄 선택 중 오류 발생: $e');
    }
  }
  
  // 정류장 정보 조회
  Future<bool> fetchScheduleStops(int scheduleId) async {
    isLoadingStops.value = true;
    scheduleStops.clear();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedules/$scheduleId/stops')
      );
      
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes); // UTF-8 디코딩 적용
        final List<dynamic> data = json.decode(decodedBody);
        print('API 응답 데이터(정류장 정보): ${utf8.decode(response.bodyBytes)}');
        scheduleStops.value = data.map((item) => ScheduleStop.fromJson(item)).toList();
        return true;
      } else if (response.statusCode == 404) {
        // 404 오류: 해당 스케줄의 정류장 정보가 없음
        print('해당 스케줄의 정류장 정보가 없습니다 (404)');
        return false;
      } else {
        // 기타 서버 오류
        throw Exception('정류장 정보를 불러오는데 실패했습니다 (${response.statusCode})');
      }
    } catch (e) {
      print('정류장 정보를 불러오는데 실패했습니다: $e');
      
      // 서버 응답 없음 - 더미 데이터 추가
      Get.snackbar(
        '서버 연결 오류',
        '서버에 연결할 수 없어 임시 데이터를 표시합니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
        duration: Duration(seconds: 3),
      );
      
      // 테스트를 위한 더미 데이터 추가
      if (scheduleStops.isEmpty) {
        // 가상 정류장 5개 생성
        for (int i = 0; i < 5; i++) {
          final arrivalTime = DateFormat('HH:mm').format(
            DateTime.now().add(Duration(minutes: 5 * i))
          );
          scheduleStops.add(ScheduleStop(
            stationName: '테스트 정류장 ${i + 1}',
            arrivalTime: arrivalTime,
            stopOrder: i + 1
          ));
        }
      }
      return true; // 더미 데이터로 대체되었으므로 성공으로 처리
    } finally {
      isLoadingStops.value = false;
    }
  }
  
  // 정류장 목록 조회
  Future<void> fetchStations() async {
    isLoadingStations.value = true;
    try {
      final response = await http.get(Uri.parse('$baseUrl/stations'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        stations.value = data.map((item) => ShuttleStation.fromJson(item)).toList();
      } else {
        throw Exception('정류장 목록을 불러오는데 실패했습니다 (${response.statusCode})');
      }
    } catch (e) {
      print('정류장 목록을 불러오는데 실패했습니다: $e');
      Get.snackbar(
        '오류',
        '정류장 목록을 불러오는데 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoadingStations.value = false;
    }
  }
  
  // 노선 선택 처리
  void selectRoute(int routeId) {
    if (selectedRouteId.value == routeId) return;
    
    selectedRouteId.value = routeId;
    schedules.clear();
    selectedScheduleId.value = -1;
    scheduleStops.clear();
    
    // 자동 API 호출 제거
    // if (selectedScheduleType.value.isNotEmpty) {
    //   fetchSchedules(routeId, selectedScheduleType.value);
    // }
  }
  
  // 운행 일자 선택 처리
  void selectScheduleType(String scheduleType) {
    if (selectedScheduleType.value == scheduleType) return;
    
    selectedScheduleType.value = scheduleType;
    schedules.clear();
    selectedScheduleId.value = -1;
    scheduleStops.clear();
    
    // 자동 API 호출 제거
    // if (selectedRouteId.value != -1) {
    //   fetchSchedules(selectedRouteId.value, scheduleType);
    // }
  }
  
  // 시간표 선택 처리
  void selectSchedule(int scheduleId) {
    selectedScheduleId.value = scheduleId;
    fetchScheduleStops(scheduleId);
  }
} 