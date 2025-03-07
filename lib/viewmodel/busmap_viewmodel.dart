import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../models/bus_model.dart';

class BusMapViewModel extends GetxController with WidgetsBindingObserver {
  final mapController = MapController();
  final markers = RxList<Marker>([]);
  final selectedRoute = "900_UP".obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // 앱 상태 감지 추가
    ever(selectedRoute, (_) => fetchBusData());
    fetchBusData().then((_) => _startTimer());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this); //앱 상태 감지 제거
    _stopTimer();
    super.onClose();
  }

  ///앱 상태 감지
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      print("백그라운드로 이동. -> 타이머 중지");
      _stopTimer();
    } else if (state == AppLifecycleState.resumed) {
      print("앱 활성화됨. -> 타이머 재개");
      _startTimer();
    }
  }

  Future<void> fetchBusData() async {
    try {
      final url =
      Uri.parse('http://192.168.45.87:8000/buses/${selectedRoute.value}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        updateBusMarkers((data[selectedRoute.value] as List)
            .map((e) => Bus.fromJson(e))
            .toList());
      } else {
        print('Failed to load bus data');
      }
    } catch (e) {
      print('Server connection error: $e');
    }
  }

  void _startTimer() {
    _stopTimer(); //타이머 초기화(중복x)
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchBusData());
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void updateBusMarkers(List<Bus> busList) {
    final newMarkers = busList.map((bus) {
      return Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(bus.latitude, bus.longitude),
        child: Column(
          children: [
            const Icon(Icons.directions_bus, color: Colors.red, size: 40),
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
