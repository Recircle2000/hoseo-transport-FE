import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/shuttle_models.dart';
import '../utils/env_config.dart';
import '../utils/location_service.dart';

class NearbyStopsViewModel extends GetxController {
  final RxList<ShuttleStation> stations = <ShuttleStation>[].obs;
  final RxList<ShuttleStation> sortedStations = <ShuttleStation>[].obs;
  final RxList<StationSchedule> stationSchedules = <StationSchedule>[].obs;
  final RxList<ShuttleRoute> routes = <ShuttleRoute>[].obs;
  
  final RxBool isLoadingStations = false.obs;
  final RxBool isLoadingSchedules = false.obs;
  final RxBool isLoadingLocation = false.obs;
  final RxBool isLoadingRoutes = false.obs;
  
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxInt selectedStationId = (-1).obs;
  
  // API 기본 URL
  final String baseUrl = EnvConfig.baseUrl;
  
  @override
  void onInit() {
    super.onInit();
    fetchStations();
    checkLocationPermission();
  }
  
  // 권한 확인 및 자동 요청
  Future<void> checkLocationPermission() async {
    try {
      // 위치 서비스가 활성화되어 있는지 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          '위치 서비스 비활성화',
          '위치 서비스를 활성화해주세요',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange,
          duration: Duration(seconds: 3),
        );
        return;
      }

      // 위치 권한 상태 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // 권한이 거부된 경우
          Get.snackbar(
            '권한 거부',
            '위치 권한이 거부되었습니다. 가까운 정류장 찾기 기능을 사용할 수 없습니다.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
            duration: Duration(seconds: 3),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // 권한이 영구적으로 거부된 경우
        Get.snackbar(
          '권한 설정 필요',
          '위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          duration: Duration(seconds: 5),
        );
        return;
      }
      
      // 권한이 허용된 경우 위치 가져오기
      await getCurrentLocation();
    } catch (e) {
      print('위치 권한 확인 중 오류 발생: $e');
    }
  }

  // 모든 정류장 정보 조회
  Future<void> fetchStations() async {
    isLoadingStations.value = true;
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/shuttle/stations'));
      
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        stations.value = data.map((item) => ShuttleStation.fromJson(item)).toList();
        
        // 위치 정보가 있다면 정류장을 거리순으로 정렬
        if (currentPosition.value != null) {
          sortStationsByDistance();
        }
      } else {
        throw Exception('정류장 목록을 불러오는데 실패했습니다 (${response.statusCode})');
      }
    } catch (e) {
      print('정류장 목록을 불러오는데 실패했습니다: $e');
      Get.snackbar(
        '오류',
        '정류장 정보를 불러오는데 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 3),
      );
      
      // 테스트 더미 데이터
      if (stations.isEmpty) {
        stations.add(ShuttleStation(id: 1, name: '아산캠퍼스(출발)', latitude: 36.738529, longitude: 127.077037, description: '아캠출발'));
        stations.add(ShuttleStation(id: 2, name: '천안아산역(천캠방향)', latitude: 36.794076, longitude: 127.10345, description: '1층정문 시내버스정류장 앞 5번 정류장'));
        stations.add(ShuttleStation(id: 3, name: 'KTX캠퍼스', latitude: 36.790865, longitude: 127.107828));
      }
    } finally {
      isLoadingStations.value = false;
    }
  }
  
  // 현재 위치 정보 조회
  Future<bool> getCurrentLocation() async {
    isLoadingLocation.value = true;
    bool success = false;
    
    try {
      // 위치 서비스 사용 가능 여부 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          '위치 서비스 비활성화',
          '위치 서비스를 활성화해주세요',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange,
          duration: Duration(seconds: 3),
        );
        return false;
      }
      
      // Geolocator를 통해 직접 위치 권한 확인 및 요청
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            '권한 거부',
            '위치 권한이 거부되었습니다',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.1),
            colorText: Colors.red,
            duration: Duration(seconds: 3),
          );
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar(
          '권한 설정 필요',
          '설정에서 위치 권한을 허용해주세요',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.red,
          duration: Duration(seconds: 3),
        );
        return false;
      }
      
      // 위치 정보 가져오기
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );
      
      currentPosition.value = position;
      
      // 위치 정보 이용해 정류장 정렬
      sortStationsByDistance();
      success = true;
      
      // 디버깅용 - 위치 정보 확인
      print('현재 위치: ${position.latitude}, ${position.longitude}');
      
    } catch (e) {
      print('위치 정보를 가져오는데 실패했습니다: $e');
      Get.snackbar(
        '오류',
        '위치 정보를 가져오는데 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 3),
      );
    } finally {
      isLoadingLocation.value = false;
    }
    
    return success;
  }
  
  // 정류장을 현재 위치부터의 거리순으로 정렬
  void sortStationsByDistance() {
    if (currentPosition.value == null || stations.isEmpty) return;
    
    final position = currentPosition.value!;
    
    sortedStations.value = List.from(stations);
    sortedStations.sort((a, b) {
      final distanceA = Geolocator.distanceBetween(
        position.latitude, position.longitude, a.latitude, a.longitude
      );
      
      final distanceB = Geolocator.distanceBetween(
        position.latitude, position.longitude, b.latitude, b.longitude
      );
      
      return distanceA.compareTo(distanceB);
    });
    
    // 가장 가까운 정류장을 자동 선택
    if (sortedStations.isNotEmpty && selectedStationId.value == -1) {
      selectedStationId.value = sortedStations.first.id;
      fetchStationSchedules(sortedStations.first.id);
    }
  }
  
  // 특정 정류장의 시간표 조회
  Future<void> fetchStationSchedules(int stationId) async {
    selectedStationId.value = stationId;
    isLoadingSchedules.value = true;
    stationSchedules.clear();
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shuttle/stations/$stationId/schedules')
      );
      
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        stationSchedules.value = data.map((item) => StationSchedule.fromJson(item)).toList();
        
        // 모든 노선 정보 가져오기 (필터링 위해)
        await fetchRoutes();
      } else {
        throw Exception('정류장 시간표를 불러오는데 실패했습니다 (${response.statusCode})');
      }
    } catch (e) {
      print('정류장 시간표를 불러오는데 실패했습니다: $e');
      Get.snackbar(
        '오류',
        '정류장 시간표를 불러오는데 실패했습니다',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 3),
      );
      
      // 테스트 더미 데이터
      if (stationSchedules.isEmpty) {
        stationSchedules.add(StationSchedule(routeId: 1, stationName: '천안아산역(천캠방향)', arrivalTime: '21:13:00', stopOrder: 2));
        stationSchedules.add(StationSchedule(routeId: 1, stationName: '천안아산역(천캠방향)', arrivalTime: '21:15:00', stopOrder: 2));
        stationSchedules.add(StationSchedule(routeId: 1, stationName: '천안아산역(천캠방향)', arrivalTime: '21:43:00', stopOrder: 2));
        stationSchedules.add(StationSchedule(routeId: 4, stationName: '천안아산역(천캠방향)', arrivalTime: '09:38:00', stopOrder: 2));
      }
    } finally {
      isLoadingSchedules.value = false;
    }
  }
  
  // 모든 노선 정보 조회
  Future<void> fetchRoutes() async {
    isLoadingRoutes.value = true;
    
    try {
      final response = await http.get(Uri.parse('$baseUrl/shuttle/routes'));
      
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        routes.value = data.map((item) => ShuttleRoute.fromJson(item)).toList();
      } else {
        throw Exception('노선 목록을 불러오는데 실패했습니다 (${response.statusCode})');
      }
    } catch (e) {
      print('노선 목록을 불러오는데 실패했습니다: $e');
      
      // 테스트 더미 데이터
      if (routes.isEmpty) {
        routes.add(ShuttleRoute(id: 1, routeName: '아산캠퍼스 → 천안캠퍼스', direction: 'UP'));
        routes.add(ShuttleRoute(id: 4, routeName: '천안캠퍼스 → 아산캠퍼스', direction: 'DOWN'));
      }
    } finally {
      isLoadingRoutes.value = false;
    }
  }
  
  // 노선 이름 가져오기
  String getRouteName(int routeId) {
    try {
      final route = routes.firstWhere((r) => r.id == routeId);
      return route.routeName;
    } catch (e) {
      return '알 수 없는 노선';
    }
  }
  
  // 정류장 이름 가져오기
  String getStationName(int stationId) {
    try {
      final station = stations.firstWhere((s) => s.id == stationId);
      return station.name;
    } catch (e) {
      return '알 수 없는 정류장';
    }
  }
  
  // 현재 위치부터 정류장까지의 거리 가져오기
  String getDistanceToStation(ShuttleStation station) {
    if (currentPosition.value == null) return '거리 측정 불가';
    
    final position = currentPosition.value!;
    final distance = Geolocator.distanceBetween(
      position.latitude, position.longitude, station.latitude, station.longitude
    );
    
    // 1km 이상이면 km 단위로 표시
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    } else {
      return '${distance.toInt()}m';
    }
  }
} 