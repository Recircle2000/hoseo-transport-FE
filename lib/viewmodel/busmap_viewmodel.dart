import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:latlong2/latlong.dart';
import '../models/bus_model.dart';

class BusMapViewModel extends GetxController {
  final mapController = MapController();
  final markers = RxList<Marker>([]);
  final selectedRoute = "900_UP".obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    ever(selectedRoute, (_) => fetchBusData());
    fetchBusData().then((_) => _startTimer());
  }

  Future<void> fetchBusData() async {
    try {
      final url =
          Uri.parse('http://127.0.0.1:8000/buses/${selectedRoute.value}');
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
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => fetchBusData());
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
