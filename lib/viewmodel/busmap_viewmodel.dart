import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/services.dart';
import '../models/bus_model.dart';

class BusMapViewModel extends GetxController with WidgetsBindingObserver {
  final mapController = MapController();
  final markers = RxList<Marker>([]);
  final stationMarkers = RxList<Marker>([]);  // 🚀 정류장 마커 추가
  final polylines = RxList<Polyline>([]);
  final selectedRoute = "900_UP".obs;
  late WebSocketChannel channel;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // 앱 상태 감지 추가
    _connectWebSocket();
    fetchRouteData();  // 초기 경로 데이터 로드
    fetchStationData();  // 초기 정류장 데이터 로드
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
     // final wsUrl = _getWebSocketUrl();
      channel = WebSocketChannel.connect(Uri.parse(_getWebSocketUrl()));

      channel.stream.listen((event) {

        final data = jsonDecode(event);
        print('Current selected route: ${selectedRoute.value}');
        print('WebSocket received data: $data');

        // 선택된 루트가 json 데이터에 포함되어 있는 경우에만 마커 업데이트
        if (data.containsKey(selectedRoute.value) &&
            data[selectedRoute.value] is List &&
            (data[selectedRoute.value] as List).isNotEmpty) {
          print('Found ${(data[selectedRoute.value] as List).length} buses for route ${selectedRoute.value}');
          final busList = (data[selectedRoute.value] as List)
              .map((e) => Bus.fromJson(e))
              .toList();
          updateBusMarkers(busList);
        } else {
          print('No data found for route ${selectedRoute.value} - clearing markers');
          markers.clear(); //마커 클리어
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
        Fluttertoast.showToast(
          msg: "웹소켓 연결 종료",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      });
    } catch (e) {
      print("WebSocket Connection Error: $e");
      Fluttertoast.showToast(
        msg: "웹소켓 연결 실패: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
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

      updatePolyline(polylinePoints);
    } catch (e) {
      print("경로 데이터를 불러오는 중 오류 발생: $e");
      Fluttertoast.showToast(
        msg: "경로 데이터를 불러올 수 없습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// 🚏 정류장 데이터 불러오기
Future<void> fetchStationData() async {
  try {
    final jsonFile = 'assets/bus_stops/${selectedRoute.value}.json';
    final jsonData = await rootBundle.loadString(jsonFile);
    final data = jsonDecode(jsonData);

    final stations = data['response']['body']['items']['item'] as List;

    final stopMarkers = stations.map((station) {
      return Marker(
        width: 60.0,
        height: 60.0,
        point: LatLng(
          double.parse(station['gpslati'].toString()),
          double.parse(station['gpslong'].toString()),
        ),
        child: GestureDetector(
          onTap: () => _showStationInfo(station),
          child: Transform.translate(
            offset: const Offset(0, -14),  // 아이콘 높이의 절반만큼 위로 이동
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
  void resetConnection() {
    _disconnectWebSocket();
    _connectWebSocket();
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
}

String _getWebSocketUrl() {
  if (GetPlatform.isAndroid) {
    return "ws://192.168.45.97:8000/ws/bus";
  } else {
    return "ws://127.0.0.1:8000/ws/bus";
  }
}