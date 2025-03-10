import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/bus_model.dart';

class BusMapViewModel extends GetxController with WidgetsBindingObserver {
  final mapController = MapController();
  final markers = RxList<Marker>([]);
  final selectedRoute = "900_UP".obs;
  late WebSocketChannel channel;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // 앱 상태 감지 추가
    _connectWebSocket();
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
      channel = WebSocketChannel.connect(
        //Uri.parse("ws://192.168.45.87:8000/ws/bus"), // 서버 주소
        Uri.parse("ws://127.0.0.1:8000/ws/bus"),
      );

      channel.stream.listen((event) {
        final data = jsonDecode(event);
        if (data.containsKey(selectedRoute.value)) {
          final busList = (data[selectedRoute.value] as List)
              .map((e) => Bus.fromJson(e))
              .toList();
          updateBusMarkers(busList);
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

  /// 버스 마커 업데이트
  void updateBusMarkers(List<Bus> busList) {
    final newMarkers = busList.map((bus) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(bus.latitude, bus.longitude),
        child:  Column(
          children: [
            const Icon(Icons.directions_bus, color: Colors.blue, size: 40),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                bus.vehicleNo,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();

    markers.assignAll(newMarkers);
  }
}
