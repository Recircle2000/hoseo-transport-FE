import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bus_city_model.dart';
import '../utils/env_config.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../utils/bus_times_loader.dart';

// 버스 위치 정보를 저장하는 클래스
class BusPosition {
  final String vehicleNo;
  final int nearestStationIndex;
  final double progressToNext; // 다음 정류장까지의 진행률 (0.0 ~ 1.0)
  final double distanceToStation; // 가장 가까운 정류장까지의 거리(미터)

  
  BusPosition({
    required this.vehicleNo,
    required this.nearestStationIndex,
    required this.progressToNext,
    required this.distanceToStation,
  });
}

class BusMapViewModel extends GetxController with WidgetsBindingObserver {
  final mapController = MapController();
  final markers = RxList<Marker>([]);
  final stationMarkers = RxList<Marker>([]);  // 🚀 정류장 마커 추가
  final polylines = RxList<Polyline>([]);
  final selectedRoute = "순환5_DOWN".obs;
  final currentPositions = RxList<int>([]); // 여러 버스의 위치를 저장하는 리스트
  final detailedBusPositions = RxList<BusPosition>([]); // 상세 버스 위치 정보
  final routePolylinePoints = RxList<LatLng>([]); // GeoJSON 폴리라인 포인트들
  final stationNames = RxList<String>([]); // 정류장 이름 목록
  final stationNumbers = RxList<String>([]); // 정류장 번호 목록
  late WebSocketChannel channel;
  
  // 현재 위치 관련 변수
  final Rx<LatLng?> currentLocation = Rx<LatLng?>(null);
  final isLocationEnabled = false.obs;
  final isLocationLoading = false.obs;
  final selectedTab = 0.obs;
  
  // 웹소켓 데이터 수신 상태 추가
  final hasReceivedWebSocketData = false.obs;

  // 다음 출발시간 저장 (노선별)
  final RxMap<String, String> nextDepartureTimes = <String, String>{}.obs;

  // 모든 노선의 버스 데이터 저장 (grouped_bus_view에서 사용)
  final RxMap<String, List<Bus>> allRoutesBusData = <String, List<Bus>>{}.obs;

  // bus_times.json 캐시
  Map<String, dynamic>? _busTimesCache;

  /// bus_times.json을 한 번만 읽어서 캐싱
  Future<Map<String, dynamic>> loadBusTimesOnce() async {
    if (_busTimesCache != null) return _busTimesCache!;
    final data = await BusTimesLoader.loadBusTimes();
    _busTimesCache = data;
    return data;
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // 앱 상태 감지 추가
    // Set selectedRoute based on campus
    final settingsViewModel = Get.find<SettingsViewModel>();
    final campus = settingsViewModel.selectedCampus.value;
    if (campus == "천안") {
      selectedRoute.value = "24_DOWN";
    } else {
      selectedRoute.value = "순환5_DOWN";
    }
    // Listen for campus changes
    ever(settingsViewModel.selectedCampus, (String newCampus) {
      if (newCampus == "천안") {
        selectedRoute.value = "24_DOWN";
      } else {
        selectedRoute.value = "순환5_DOWN";
      }
      fetchRouteData();
      fetchStationData();
    });
    _connectWebSocket();
    fetchRouteData();  // 초기 경로 데이터 로드
    fetchStationData();  // 초기 정류장 데이터 로드
    checkLocationPermission(); // 위치 권한 확인
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); // 앱 상태 감지 제거
    _disconnectWebSocket();
    super.onClose();
  }

  /// 앱 상태 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      print("백그라운드로 이동 -> 웹소켓 연결 해제");
      _disconnectWebSocket();
    } else if (state == AppLifecycleState.resumed) {
      print("앱 활성화 -> 웹소켓 재연결");
      _connectWebSocket();
    }
  }

  /// 웹소켓 연결 함수
  void _connectWebSocket() {
    _disconnectWebSocket(); // 기존 연결 초기화
    try {
      channel = WebSocketChannel.connect(Uri.parse(_getWebSocketUrl()));

      // 연결 즉시 데이터 요청 (선택적)
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          channel.sink.add(jsonEncode({"route": selectedRoute.value}));
        } catch (e) {
          print("웹소켓 데이터 요청 오류: $e");
        }
      });

      channel.stream.listen((event) {
        final data = jsonDecode(event);
        print('Current selected route: ${selectedRoute.value}');
        print('WebSocket received data: $data');

        // 웹소켓 데이터 수신 상태 업데이트
        hasReceivedWebSocketData.value = true;

        // 모든 노선의 데이터를 저장 (grouped_bus_view용)
        for (final entry in data.entries) {
          final routeKey = entry.key;
          final busDataList = entry.value as List;
          
          if (busDataList.isNotEmpty) {
            final busList = busDataList.map((e) => Bus.fromJson(e)).toList();
            allRoutesBusData[routeKey] = busList;
          } else {
            allRoutesBusData[routeKey] = [];
          }
        }

        // 선택된 루트가 json 데이터에 포함되어 있는 경우에만 마커 업데이트
        if (data.containsKey(selectedRoute.value) &&
            data[selectedRoute.value] is List &&
            (data[selectedRoute.value] as List).isNotEmpty) {
          print('Found ${(data[selectedRoute.value] as List).length} buses for route ${selectedRoute.value}');
          final busList = (data[selectedRoute.value] as List)
              .map((e) => Bus.fromJson(e))
              .toList();
          updateBusMarkers(busList);
          _updateCurrentPosition(busList);
          update(); // UI 새로 고침
        } else {
          print('No data found for route ${selectedRoute.value} - clearing markers');
          markers.clear();
          currentPositions.clear(); // 데이터가 없을 경우 버스 위치도 초기화
          update(); // UI 새로 고침
        }
      }, onError: (error) {
        print("WebSocket Error: $error");
        Fluttertoast.showToast(
          msg: "서버 연결 오류: $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }, onDone: () {
        print("WebSocket Closed");
      });
    } catch (e) {
      print("WebSocket Connection Error: $e");
    }
  }

  /// 웹소켓 연결 해제 함수
  void _disconnectWebSocket() {
    try {
      channel.sink.close();
      print("WebSocket Closed");
    } catch (e) {
      print("WebSocket Close Error: $e");
    }
  }

  /// 버스 경로 데이터 불러오기
  Future<void> fetchRouteData() async {
    try {
      final geoJsonFile = 'assets/bus_routes/${selectedRoute.value}.json';
      final geoJsonData = await rootBundle.loadString(geoJsonFile);
      final geoJson = jsonDecode(geoJsonData);

      final coordinates = geoJson['features'][0]['geometry']['coordinates'];
      final polylinePoints = coordinates
          .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
          .toList();

      // 폴리라인 데이터 저장
      routePolylinePoints.assignAll(polylinePoints);
      updatePolyline(polylinePoints);
    } catch (e) {
      print("경로 데이터를 불러오는 중 오류 발생: $e");
      Fluttertoast.showToast(
        msg: "경로 데이터를 불러올 수 없습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      // 오류 발생 시 폴리라인 초기화
      polylines.clear();
      routePolylinePoints.clear();
    }
  }

  /// 🚏 정류장 데이터 불러오기
  Future<void> fetchStationData() async {
    try {
      // 초기화
      stationMarkers.clear();
      stationNames.clear();
      stationNumbers.clear();
      currentPositions.clear();
      detailedBusPositions.clear();
      
      final jsonFile = 'assets/bus_stops/${selectedRoute.value}.json';
      final jsonData = await rootBundle.loadString(jsonFile);
      final data = jsonDecode(jsonData);

      final stations = data['response']['body']['items']['item'] as List;
      
      // 정류장 이름과 번호 목록 업데이트
      final names = stations.map<String>((station) => 
        station['nodenm']?.toString() ?? "정류장").toList();
      final numbers = stations.map<String>((station) => 
        station['nodeno']?.toString() ?? "").toList();
        
      stationNames.assignAll(names);
      stationNumbers.assignAll(numbers);

      final stopMarkers = stations.map((station) {
        return Marker(
          width: 30.0,
          height: 30.0,
          point: LatLng(
            double.parse(station['gpslati'].toString()),
            double.parse(station['gpslong'].toString()),
          ),
          child: GestureDetector(
            onTap: () => _showStationInfo(station),
            child: Transform.translate(
              offset: const Offset(0, -13),
              child: const Icon(
                Icons.location_on,
                color: Colors.blueAccent,
                size: 30,
              ),
            ),
          ),
        );
      }).toList();

      stationMarkers.assignAll(stopMarkers);
    } catch (e) {
      print("정류장 데이터를 불러오는 중 오류 발생: $e");
      Fluttertoast.showToast(
        msg: "정류장 데이터를 불러올 수 없습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  void _showStationInfo(Map<String, dynamic> station) {
    Get.dialog(
      AlertDialog(
        title: Text(station['nodenm'] ?? "정류장"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정류장 ID: ${station['nodeid'] ?? "없음"}'),
            const SizedBox(height: 8),
            Text('정류장 번호: ${station['nodeno'] ?? "없음"}'),
            const SizedBox(height: 8),
            Text('정류장 순서: ${station['nodeord'] ?? "없음"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  /// 버스 마커 업데이트
  void updateBusMarkers(List<Bus> busList) {
    if (busList.isEmpty) {
      markers.clear();  // Clear all markers if no bus data
      return;
    }
    final newMarkers = busList.map((bus) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(bus.latitude, bus.longitude),
        child: Column(
          children: [
            const Icon(Icons.directions_bus, color: Colors.indigo, size: 40),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                bus.vehicleNo,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    markers.assignAll(newMarkers);
  }

  void _updateCurrentPosition(List<Bus> busList) {
    if (busList.isEmpty || stationMarkers.isEmpty) {
      currentPositions.clear();
      detailedBusPositions.clear();
      return;
    }

    // 버스별로 노선 진행 방향을 고려한 위치 정보 계산
    List<int> busPositions = [];
    List<BusPosition> detailedPositions = [];

    for (final bus in busList) {
      final busLatLng = LatLng(bus.latitude, bus.longitude);
      
      // 노선 방향성을 고려한 현재 정류장 찾기
      int currentStationIndex = _findCurrentStationAlongRoute(busLatLng);
      
      // 현재 정류장까지의 거리 계산
      final distanceToCurrentStation = const Distance().as(
        LengthUnit.Meter, 
        stationMarkers[currentStationIndex].point, 
        busLatLng
      );
      
      // 진행률 계산
      double progressToNext = 0.0;
      if (currentStationIndex < stationMarkers.length - 1) {
        if (routePolylinePoints.isNotEmpty) {
          progressToNext = _calculateProgressAlongRoute(busLatLng, currentStationIndex);
        } else {
          // 폴백: 직선 거리 기반 계산 (더 보수적으로)
          progressToNext = _calculateLinearProgress(busLatLng, currentStationIndex, distanceToCurrentStation);
        }
      }
      
      // 상세 위치 정보 저장
      detailedPositions.add(BusPosition(
        vehicleNo: bus.vehicleNo,
        nearestStationIndex: currentStationIndex,
        progressToNext: progressToNext,
        distanceToStation: distanceToCurrentStation,
      ));
      
      // 중복 위치는 추가하지 않음
      if (!busPositions.contains(currentStationIndex)) {
        busPositions.add(currentStationIndex);
      }
    }

    // 위치 정렬 (오름차순)
    busPositions.sort();
    
    // 현재 위치 업데이트
    currentPositions.assignAll(busPositions);
    detailedBusPositions.assignAll(detailedPositions);
  }

  /// 노선 방향성을 고려하여 버스의 현재 정류장 인덱스를 찾는 함수
  int _findCurrentStationAlongRoute(LatLng busPosition) {
    if (routePolylinePoints.isEmpty || stationMarkers.isEmpty) {
      return _findNearestStationByDistance(busPosition);
    }

    // 버스 위치에서 가장 가까운 폴리라인 포인트 찾기
    int busPolyIndex = _findNearestPolylinePoint(busPosition);
    
    // 각 정류장의 폴리라인 인덱스 계산
    List<int> stationPolyIndices = [];
    for (int i = 0; i < stationMarkers.length; i++) {
      stationPolyIndices.add(_findNearestPolylinePoint(stationMarkers[i].point));
    }
    
    // 버스 위치보다 앞에 있는 정류장들 중 가장 가까운 것 찾기
    int currentStationIndex = 0;
    for (int i = 0; i < stationPolyIndices.length; i++) {
      if (stationPolyIndices[i] <= busPolyIndex) {
        currentStationIndex = i;
      } else {
        break; // 버스 위치를 넘어선 첫 번째 정류장에서 중단
      }
    }
    
    // 추가 검증: 현재 정류장과의 거리가 너무 멀면 다음 정류장으로 조정
    if (currentStationIndex < stationMarkers.length - 1) {
      final currentStationDistance = const Distance().as(
        LengthUnit.Meter, 
        stationMarkers[currentStationIndex].point, 
        busPosition
      );
      final nextStationDistance = const Distance().as(
        LengthUnit.Meter, 
        stationMarkers[currentStationIndex + 1].point, 
        busPosition
      );
      
      // 다음 정류장이 현재 정류장보다 훨씬 가깝고, 현재 정류장과의 거리가 300m 이상이면
      if (nextStationDistance < currentStationDistance * 0.7 && currentStationDistance > 300) {
        // 하지만 폴리라인 상에서 다음 정류장을 아직 지나지 않았다면 현재 정류장 유지
        if (stationPolyIndices[currentStationIndex + 1] > busPolyIndex + 10) { // 10포인트 여유
          // 현재 정류장 유지
        } else {
          currentStationIndex = currentStationIndex + 1;
        }
      }
    }
    
    return currentStationIndex;
  }

  /// 단순 거리 기반으로 가장 가까운 정류장 찾기 (폴백 함수)
  int _findNearestStationByDistance(LatLng busPosition) {
    double minDistance = double.infinity;
    int nearestStationIndex = 0;

    for (int i = 0; i < stationMarkers.length; i++) {
      final distance = const Distance().as(
        LengthUnit.Meter, 
        stationMarkers[i].point, 
        busPosition
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestStationIndex = i;
      }
    }
    
    return nearestStationIndex;
  }

  /// 직선 거리 기반 진행률 계산 (보수적 접근)
  double _calculateLinearProgress(LatLng busPosition, int currentStationIndex, double distanceToCurrentStation) {
    if (currentStationIndex >= stationMarkers.length - 1) {
      return 0.0;
    }
    
    final currentStation = stationMarkers[currentStationIndex].point;
    final nextStation = stationMarkers[currentStationIndex + 1].point;
    
    // 현재 정류장에서 너무 멀리 떨어져 있으면 진행률 0
    if (distanceToCurrentStation > 400) {
      return 0.0;
    }
    
    // 현재 정류장에 너무 가까우면 진행률 0 (아직 출발하지 않음)
    if (distanceToCurrentStation < 50) {
      return 0.0;
    }
    
    final totalDistance = const Distance().as(LengthUnit.Meter, currentStation, nextStation);
    if (totalDistance == 0) return 0.0;
    
    // 버스가 현재 정류장과 다음 정류장 사이의 직선상에 있는지 확인
    final distanceToNext = const Distance().as(LengthUnit.Meter, nextStation, busPosition);
    
    // 삼각형 부등식을 이용한 직선상 위치 검증
    final directDistance = totalDistance;
    final actualDistance = distanceToCurrentStation + distanceToNext;
    
    // 실제 거리가 직선 거리보다 20% 이상 크면 직선상에 있지 않다고 판단
    if (actualDistance > directDistance * 1.2) {
      return 0.0;
    }
    
    double progress = distanceToCurrentStation / totalDistance;
    return progress.clamp(0.0, 0.75); // 최대 75%로 제한 (더 보수적)
  }

  /// 노선별 다음 출발시간 계산 (특히 _DOWN 노선)
  Future<void> updateNextDepartureTime(String routeKey) async {
    try {
      final busTimes = await loadBusTimesOnce();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final timetable = busTimes[routeKey]?['시간표'] as List<dynamic>?;
      if (timetable == null || timetable.isEmpty) {
        nextDepartureTimes[routeKey] = '시간표 없음';
        return;
      }
      // HH:mm 문자열을 DateTime으로 변환
      final times = timetable.map((t) {
        final parts = t.split(':');
        return DateTime(today.year, today.month, today.day, int.parse(parts[0]), int.parse(parts[1]));
      }).toList();
      // 현재 시간 이후의 첫 출발 찾기
      final next = times.firstWhereOrNull((t) => t.isAfter(now));
      if (next != null) {
        nextDepartureTimes[routeKey] = '출발: ${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';
      } else {
        nextDepartureTimes[routeKey] = '운행 종료';
      }
    } catch (e) {
      nextDepartureTimes[routeKey] = '시간표 오류';
    }
  }

  void resetConnection() {
    // 데이터 초기화
    markers.clear();
    currentPositions.clear();
    detailedBusPositions.clear();
    routePolylinePoints.clear();
    
    // 웹소켓 데이터 수신 상태 초기화
    hasReceivedWebSocketData.value = false;
    
    // 연결 재설정
    _disconnectWebSocket();
    _connectWebSocket();
  }

  /// GeoJSON 폴리라인을 활용한 정확한 위치 계산
  double _calculateProgressAlongRoute(LatLng busPosition, int nearestStationIndex) {
    if (routePolylinePoints.isEmpty || nearestStationIndex >= stationMarkers.length - 1) {
      return 0.0;
    }

    final currentStation = stationMarkers[nearestStationIndex].point;
    final nextStation = stationMarkers[nearestStationIndex + 1].point;

    // 버스가 현재 정류장에서 너무 멀리 떨어져 있으면 진행률 0으로 설정
    final distanceToCurrentStation = const Distance().as(LengthUnit.Meter, currentStation, busPosition);
    if (distanceToCurrentStation > 500) { // 500미터 이상 떨어져 있으면
      return 0.0;
    }

    // 폴리라인에서 현재 정류장과 다음 정류장에 가장 가까운 포인트 찾기
    int currentStationPolyIndex = _findNearestPolylinePoint(currentStation);
    int nextStationPolyIndex = _findNearestPolylinePoint(nextStation);

    // 정류장 순서가 올바른지 확인 (다음 정류장이 더 뒤에 있어야 함)
    if (nextStationPolyIndex <= currentStationPolyIndex) {
      return 0.0;
    }

    // 버스 위치에서 가장 가까운 폴리라인 포인트 찾기
    int busPolyIndex = _findNearestPolylinePoint(busPosition);

    // 폴리라인을 따라 실제 거리 계산
    double totalRouteDistance = _calculateRouteDistance(currentStationPolyIndex, nextStationPolyIndex);
    
    // 더 보수적인 진행률 계산
    double busRouteDistance;
    if (busPolyIndex <= currentStationPolyIndex) {
      // 버스가 현재 정류장보다 앞에 있으면 0
      busRouteDistance = 0.0;
    } else if (busPolyIndex >= nextStationPolyIndex) {
      // 버스가 다음 정류장을 넘어갔지만 API상 도착하지 않았다면 80%로 제한
      busRouteDistance = totalRouteDistance * 0.8;
    } else {
      // 정상적으로 두 정류장 사이에 있는 경우
      busRouteDistance = _calculateRouteDistance(currentStationPolyIndex, busPolyIndex);
    }

    if (totalRouteDistance == 0) return 0.0;

    double progress = busRouteDistance / totalRouteDistance;
    return progress.clamp(0.0, 0.8); // 최대 80%로 제한
  }

  /// 폴리라인에서 주어진 위치에 가장 가까운 포인트의 인덱스 찾기
  int _findNearestPolylinePoint(LatLng targetPosition) {
    if (routePolylinePoints.isEmpty) return 0;

    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < routePolylinePoints.length; i++) {
      final distance = const Distance().as(
        LengthUnit.Meter, 
        targetPosition, 
        routePolylinePoints[i]
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  /// 폴리라인을 따라 두 포인트 사이의 실제 거리 계산
  double _calculateRouteDistance(int startIndex, int endIndex) {
    if (startIndex >= endIndex || endIndex >= routePolylinePoints.length) {
      return 0.0;
    }

    double totalDistance = 0.0;
    for (int i = startIndex; i < endIndex; i++) {
      totalDistance += const Distance().as(
        LengthUnit.Meter,
        routePolylinePoints[i],
        routePolylinePoints[i + 1],
      );
    }

    return totalDistance;
  }

  /// 경로 폴리라인 업데이트
  void updatePolyline(List<LatLng> points) {
    polylines.assignAll([
      Polyline(
        points: points,
        strokeWidth: 4.0,
        color: Colors.blueAccent,
      ),
    ]);
  }

  /// 위치 권한 확인 및 현재 위치 가져오기
  Future<void> checkLocationPermission() async {
    isLocationLoading.value = true;
    
    try {
      // 위치 서비스가 활성화되어 있는지 확인
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLocationLoading.value = false;
        isLocationEnabled.value = false;
        Fluttertoast.showToast(
          msg: "위치 서비스가 비활성화되어 있습니다. 설정에서 활성화해주세요.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // 권한이 거부된 경우, 사용자에게 권한 요청
        Fluttertoast.showToast(
          msg: "위치 권한을 요청합니다",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLocationLoading.value = false;
          isLocationEnabled.value = false;
          Fluttertoast.showToast(
            msg: "위치 권한이 거부되었습니다.",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        isLocationLoading.value = false;
        isLocationEnabled.value = false;
        Fluttertoast.showToast(
          msg: "위치 권한이 영구적으로 거부되었습니다. 설정에서 변경해주세요.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      // 권한이 있으면 현재 위치 가져오기
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // 10초 타임아웃 설정
      );
      
      currentLocation.value = LatLng(position.latitude, position.longitude);
      isLocationEnabled.value = true;
      isLocationLoading.value = false;
      
      print("현재 위치: ${position.latitude}, ${position.longitude}");
    } catch (e) {
      print("위치 정보를 가져오는 중 오류 발생: $e");
      isLocationLoading.value = false;
      isLocationEnabled.value = false;
      
      // 오류 메시지 구체화
      String errorMessage = "위치 정보를 가져올 수 없습니다.";
      if (e.toString().contains("timeout")) {
        errorMessage = "위치 정보를 가져오는 데 시간이 너무 오래 걸립니다.";
      } else if (e.toString().contains("permission")) {
        errorMessage = "위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.";
      }
      
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
  
  /// 현재 위치로 지도 이동
  void moveToCurrentLocation() async {
    if (currentLocation.value != null) {
      mapController.move(currentLocation.value!, 15);
      update(); // GetX 상태 업데이트
    } else {
      await checkLocationPermission();
      if (currentLocation.value != null) {
        mapController.move(currentLocation.value!, 15);
        update(); // GetX 상태 업데이트
      }
    }
  }
  
  /// 현재 위치를 실시간으로 추적
  void startLocationTracking() {
    if (!isLocationEnabled.value) {
      checkLocationPermission();
      return;
    }
    
    // 위치 변경 리스너 등록
    try {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // 10미터마다 업데이트
        ),
      ).listen((Position position) {
        currentLocation.value = LatLng(position.latitude, position.longitude);
        print("위치 업데이트: ${position.latitude}, ${position.longitude}");
      });
    } catch (e) {
      print("위치 추적 중 오류 발생: $e");
      Fluttertoast.showToast(
        msg: "위치 추적을 시작할 수 없습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
  
  /// 가장 가까운 정류장 찾기
  int? findNearestStation() {
    if (currentLocation.value == null || stationMarkers.isEmpty) {
      return null;
    }
    
    double minDistance = double.infinity;
    int nearestIndex = -1;
    
    for (int i = 0; i < stationMarkers.length; i++) {
      final station = stationMarkers[i];
      final distance = const Distance().as(
        LengthUnit.Meter, 
        currentLocation.value!, 
        station.point
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }
    
    if (nearestIndex != -1) {
      return nearestIndex;
    }
    
    return null;
  }
}

String _getWebSocketUrl() {
  return "wss://${EnvConfig.baseUrl.replaceAll('https://', '')}/ws/bus";
  //return "ws://10.0.2.2:8000/ws/bus";
} 