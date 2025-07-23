import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 환경 변수 사용을 위한 패키지 추가
import 'settings_viewmodel.dart';
import 'notice_viewmodel.dart';
import 'package:hsro/utils/bus_times_loader.dart';

class BusDeparture {
  final String routeName;
  final String destination;
  final DateTime departureTime;
  final int minutesLeft;
  final int? scheduleId; // scheduleId 추가

  BusDeparture({
    required this.routeName,
    required this.destination,
    required this.departureTime,
    required this.minutesLeft,
    this.scheduleId, // 옵셔널 파라미터로 추가
  });
}

class UpcomingDepartureViewModel extends GetxController with WidgetsBindingObserver {
  // 환경 변수에서 BASE_URL 가져오기
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://default.url';
  final settingsViewModel = Get.find<SettingsViewModel>();

  // NoticeViewModel 참조 (지연 초기화)
  NoticeViewModel? get noticeViewModel {
    try {
      return Get.find<NoticeViewModel>();
    } catch (e) {
      return null; // NoticeViewModel이 아직 초기화되지 않은 경우
    }
  }

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

  // 활성 상태 추적
  final isActive = true.obs;
  final isOnHomePage = true.obs;

  // 셔틀 데이터 캐시를 위한 변수들
  Map<String, dynamic>? _cachedShuttleData;
  Map<int, String>? _cachedRouteNames; // 노선 정보 캐시 추가
  int? _previousStationId;

  // 셔틀 노선 상세 페이지 이동을 위한 변수들
  final RxInt selectedScheduleId = (-1).obs; // 선택된 스케줄 ID
  final RxString scheduleTypeName = ''
      .obs; // 현재 스케줄 타입 이름 (Weekday, Saturday, Holiday)

  // 오늘 시내버스 운행 종료 여부 플래그
  final isCityBusServiceEnded = false.obs;

  // 오늘 셔틀버스 운행 종료 여부 플래그
  final isShuttleServiceEnded = false.obs;
  // 오늘 셔틀버스 운행 없음 플래그 (schedules가 아예 비어있을 때)
  final isShuttleServiceNotOperated = false.obs;

  void setRefreshCallback(Function callback) {
    _onRefreshCallback = callback;
  }

  @override
  void onInit() {
    super.onInit();
    // 앱 상태 감지를 위한 옵저버 등록
    WidgetsBinding.instance.addObserver(this);

    // 활성 상태 추적 변수 설정
    isActive.value = true;
    isOnHomePage.value = true;

    // 캠퍼스 설정이 변경되면 데이터 다시 로드
    ever(settingsViewModel.selectedCampus, (_) => loadData());

    // 활성 상태 변경 리스너 (앱 포그라운드/백그라운드)
    ever(isActive, (active) {
      if (active && isOnHomePage.value) {
        print('앱이 활성화됨 -> 즉시 새로고침 및 타이머 시작');
        loadData();
        // 공지사항도 함께 새로고침
        noticeViewModel?.fetchLatestNotice();
        _startRefreshTimer();
        // UI 타이머도 초기화하기 위해 콜백 호출
        _onRefreshCallback?.call();
      } else {
        print('앱이 비활성화됨 -> 타이머 중지');
        _stopRefreshTimer();
      }
    });

    // 페이지 상태 변경 리스너 (홈 페이지/다른 페이지)
    ever(isOnHomePage, (onHomePage) {
      if (onHomePage && isActive.value) {
        print('홈페이지로 돌아옴 -> 즉시 새로고침 및 타이머 시작');
        loadData();
        // 공지사항도 함께 새로고침
        noticeViewModel?.fetchLatestNotice();
        _startRefreshTimer();
        // UI 타이머도 초기화하기 위해 콜백 호출
        _onRefreshCallback?.call();
      } else {
        print('다른 페이지로 이동 -> 타이머 중지');
        _stopRefreshTimer();
      }
    });

    // 초기 데이터 로드 및 타이머 시작 (프레임이 완전히 렌더링된 후 실행)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('위젯 렌더링 완료 후 초기 데이터 로드');
      loadData();
      _startRefreshTimer();
    });
  }

  // 페이지 상태 업데이트 함수
  void setHomePageState(bool isOnHome) {
    isOnHomePage.value = isOnHome;
  }

  @override
  void onClose() {
    // 앱 상태 감지 옵저버 제거
    WidgetsBinding.instance.removeObserver(this);
    _stopRefreshTimer();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // 앱이 백그라운드로 갔을 때
      isActive.value = false;
    } else if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아왔을 때
      isActive.value = true;
    }
  }

  void _startRefreshTimer() {
    // 기존 타이머 취소
    _stopRefreshTimer();

    // 30초마다 자동 업데이트
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      print('자동 새로고침');
      loadData();
      // 콜백 호출로 UI의 카운트다운도 초기화
      _onRefreshCallback?.call();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> loadData() async {
    print('데이터 로드 시작');
    isLoading.value = true;
    error.value = '';

    try {
      // 시내버스 데이터 로드
      await loadCityBusData();

      // 셔틀버스 데이터 로드
      await loadShuttleData();

      print('데이터 로드 완료');
    } catch (e) {
      print('데이터 로드 중 오류: $e');
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
      final Map<String, dynamic> busData = await BusTimesLoader.loadBusTimes();
      // 현재 시간 및 오늘 날짜
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // 곧 출발하는 버스 리스트
      final upcomingBuses = <BusDeparture>[];
      // 캠퍼스에 따라 다른 출발지 설정
      final String departurePlace = currentCampus == '천안'
          ? '각원사 회차지'
          : '호서대학교 기점';
      // 오늘 운행 종료 플래그 초기화
      bool lastBusDeparted = true;
      busData.forEach((routeKey, routeData) {
        if (routeKey == 'version') return; // version 필드는 무시
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
            // 오늘 날짜의 버스만 체크
            if (departureTime.year == today.year &&
                departureTime.month == today.month &&
                departureTime.day == today.day) {
              final difference = departureTime.difference(now);
              final minutesLeft = (difference.inSeconds / 60).ceil();
              if (difference.inSeconds > 0 && difference.inMinutes <= 90) {
                upcomingBuses.add(BusDeparture(
                  routeName: routeKey.split('_')[0],
                  destination: destination,
                  departureTime: departureTime,
                  minutesLeft: minutesLeft == 0 ? 1 : minutesLeft,
                ));
                lastBusDeparted = false;
              }
              // 오늘 날짜의 버스 중 아직 출발하지 않은 게 있으면 lastBusDeparted = false
              if (difference.inSeconds > 0) {
                lastBusDeparted = false;
              }
            }
          }
        }
      });
      // 출발시간 기준으로 정렬
      upcomingBuses.sort((a, b) => a.minutesLeft.compareTo(b.minutesLeft));
      // 최대 3개만 표시
      upcomingCityBuses.value = upcomingBuses.take(3).toList();
      // 운행 종료 플래그 업데이트
      isCityBusServiceEnded.value = lastBusDeparted;
    } catch (e) {
      print('시내버스 데이터 로드 중 오류: $e');
      upcomingCityBuses.clear();
      isCityBusServiceEnded.value = false; // 오류 시 false로 초기화
    }
  }

  Future<void> loadShuttleData() async {
    print('셔틀버스 데이터 로드 시작');
    try {
      final currentCampus = settingsViewModel.selectedCampus.value;
      final int stationId = (currentCampus == '천안') ? 14 : 1;
      if (_previousStationId != stationId) {
        _cachedShuttleData = null;
        _cachedRouteNames = null;
        _previousStationId = stationId;
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final String dateStr = DateFormat('yyyy-MM-dd').format(now);
      Map<String, dynamic> responseData;
      if (_cachedShuttleData != null) {
        if (_cachedShuttleData!['date'] != dateStr) {
          print('캐시된 데이터가 오늘 날짜가 아니므로 캐시 초기화');
          _cachedShuttleData = null;
        } else {
          print('캐시된 데이터가 오늘 날짜이므로 캐시 사용');
        }
      }
      if (_cachedShuttleData == null) {
        final response = await http.get(
            Uri.parse(
                '$baseUrl/shuttle/stations/$stationId/schedules-by-date?date=$dateStr'),
            headers: {'Accept-Charset': 'UTF-8'}
        );
        if (response.statusCode == 200) {
          final String decodedBody = utf8.decode(response.bodyBytes);
          responseData = json.decode(decodedBody);
          print(responseData);
          _cachedShuttleData = responseData;
        } else {
          throw Exception('API 오류: [200m${response.statusCode}[0m');
        }
      } else {
        responseData = _cachedShuttleData!;
      }
      scheduleTypeName.value =
          responseData['schedule_type_name'] ?? responseData['schedule_type'] ??
              '';
      final List<dynamic> schedulesData = responseData['schedules'] ?? [];
      final Map<int, String> routeNames = _cachedRouteNames ?? {};
      final upcomingShuttleList = <BusDeparture>[];
      bool lastShuttleDeparted = true;
      // schedules가 아예 비어있으면 오늘 운행 없음 플래그 true
      if (schedulesData.isEmpty) {
        isShuttleServiceEnded.value = true;
        isShuttleServiceNotOperated.value = true;
        upcomingShuttles.clear();
        return;
      } else {
        isShuttleServiceNotOperated.value = false;
      }
      for (final schedule in schedulesData) {
        final int routeId = schedule['route_id'];
        final int scheduleId = schedule['schedule_id'];
        if (!routeNames.containsKey(routeId)) {
          try {
            final routeResponse = await http.get(
                Uri.parse('$baseUrl/shuttle/routes?route_id=$routeId'),
                headers: {'Accept-Charset': 'UTF-8'}
            );
            if (routeResponse.statusCode == 200) {
              final String decodedRouteBody = utf8.decode(
                  routeResponse.bodyBytes);
              final List<dynamic> routeData = json.decode(decodedRouteBody);
              print(routeData);
              if (routeData.isNotEmpty) {
                routeNames[routeId] = routeData[0]['route_name'];
                _cachedRouteNames = routeNames;
              }
            }
          } catch (e) {
            print('노선 정보 로드 중 오류: $e');
            routeNames[routeId] = '노선 $routeId';
          }
        }
        final arrivalTimeStr = schedule['arrival_time'];
        final timeParts = arrivalTimeStr.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
        final departureTime = DateTime(
            now.year, now.month, now.day, hour, minute, second
        );
        // 오늘 날짜의 셔틀만 체크
        if (departureTime.year == today.year &&
            departureTime.month == today.month &&
            departureTime.day == today.day) {
          final difference = departureTime.difference(now);
          final minutesLeft = (difference.inSeconds / 60).ceil();
          if (difference.inSeconds > 0 && difference.inMinutes <= 90) {
            upcomingShuttleList.add(BusDeparture(
              routeName: '셔틀',
              destination: routeNames[routeId] ?? '알 수 없음',
              departureTime: departureTime,
              minutesLeft: minutesLeft == 0 ? 1 : minutesLeft,
              scheduleId: scheduleId,
            ));
            lastShuttleDeparted = false;
          }
          // 오늘 날짜의 셔틀 중 아직 출발하지 않은 게 있으면 lastShuttleDeparted = false
          if (difference.inSeconds > 0) {
            lastShuttleDeparted = false;
          }
        }
      }
      upcomingShuttleList.sort((a, b) =>
          a.minutesLeft.compareTo(b.minutesLeft));
      upcomingShuttles.value = upcomingShuttleList.take(3).toList();
      isShuttleServiceEnded.value = lastShuttleDeparted;
      if (upcomingShuttles.isNotEmpty &&
          upcomingShuttles[0].scheduleId != null) {
        selectedScheduleId.value = upcomingShuttles[0].scheduleId!;
      }
    } catch (e) {
      print('셔틀버스 데이터 로드 중 오류: $e');
      upcomingShuttles.clear();
      isShuttleServiceEnded.value = false;
    }
  }
}