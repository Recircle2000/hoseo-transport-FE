import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class BusMapView extends StatefulWidget {
  @override
  _BusMapViewState createState() => _BusMapViewState();
}

class _BusMapViewState extends State<BusMapView> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  String _selectedRoute = "900_UP";
  Timer? _timer; // Timer 변수 추가

  @override
  void initState() {
    super.initState();
    fetchBusData(); // 초기 데이터 로드
    // 10초마다 데이터 갱신
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchBusData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 타이머 해제
    super.dispose();
  }

  Future<void> fetchBusData() async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/buses/$_selectedRoute');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)); // UTF-8 디코딩
        updateBusMarkers(data[_selectedRoute]);
      } else {
        debugPrint('버스 데이터를 불러오는데 실패했습니다.');
      }
    } catch (e) {
      debugPrint('서버 연결 오류: $e');
    }
  }

  void updateBusMarkers(List<dynamic>? busList) {
    if (busList == null) return;

    setState(() {
      _markers.clear();
      for (var bus in busList) {
        try {
          double lat = double.parse(bus["gpslati"]?.toString() ?? "0");
          double lng = double.parse(bus["gpslong"]?.toString() ?? "0");
          String busNo = bus["vehicleno"]?.toString() ?? ""; // 버스 번호
          print('lat: $lat, lng: $lng, busNo: $busNo');

          _markers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(lat, lng),
              child: Column(
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Colors.red,
                    size: 40,
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      busNo,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          debugPrint('마커 생성 오류: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시내버스 위치')),
      body: Column(
        children: [
          DropdownButton<String>(
            value: _selectedRoute,
            items: ["순환5_DOWN", "순환5_UP", "900_UP", "900_DOWN"]
                .map((route) =>
                DropdownMenuItem(
                  value: route,
                  child: Text(route),
                ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedRoute = value!;
                fetchBusData();
              });
            },
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(36.769423, 127.047998),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: _markers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
