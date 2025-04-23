import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  // 싱글톤 패턴
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();
  
  // 위치 서비스 초기화
  Future<bool> initLocationService() async {
    // 웹에서는 초기화 생략 (기본적으로 성공으로 처리)
    if (kIsWeb) {
      if (kDebugMode) {
        print('웹 환경에서는 위치 서비스 초기화를 건너뜁니다.');
      }
      return true;
    }
    
    try {
      // 위치 서비스가 활성화되어 있는지 확인
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('위치 서비스가 비활성화되어 있습니다.');
        }
        return false;
      }
      
      // 위치 권한 상태 확인
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // 위치 권한 요청
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('위치 권한이 거부되었습니다.');
          }
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('위치 권한이 영구적으로 거부되었습니다.');
        }
        return false;
      }
      
      // 위치 서비스 초기화 성공
      if (kDebugMode) {
        print('위치 서비스 초기화 성공!');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('위치 서비스 초기화 중 오류 발생: $e');
      }
      return false;
    }
  }
  
  // 위치 서비스 사용 가능 여부 확인
  Future<bool> isLocationAvailable() async {
    // 웹에서는 단순화된 체크
    if (kIsWeb) {
      try {
        // 웹에서는 Geolocator.checkPermission() 대신 
        // Geolocator의 웹 버전이 제공하는 API를 사용해야 함
        return true; // 웹에서는 기본적으로 가능하다고 가정
      } catch (e) {
        return false;
      }
    }
    
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }
} 