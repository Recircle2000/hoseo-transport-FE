import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodel/busmap_viewmodel.dart';
import 'bus_timetable_view.dart';

class BusMapView extends StatelessWidget {
  final Map<String, String> routeDisplayNames = { // 노선 이름 표시용
    "순환5_DOWN": "순환5 (호서대학교 → 천안아산역)",
    "순환5_UP": "순환5 (천안아산역 → 호서대학교)",
    "900_DOWN": "900 (천안터미널 → 아산터미널)",
    "900_UP": "900 (아산터미널 → 천안터미널)"
  };

  final Map<String, String> routeSimpleNames = { // 노선 이름 간단 표시용
    "순환5_DOWN": "순환5",
    "순환5_UP": "순환5",
    "900_DOWN": "900",
    "900_UP": "900"
  };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시내버스 위치'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.delete<BusMapViewModel>();
            Get.back();
          },
        ),
      ),
      body: GetBuilder<BusMapViewModel>(
        init: BusMapViewModel(),
        builder: (controller) => Stack(
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: Obx(() => DropdownButton<String>(
                            isExpanded: true,
                            value: controller.selectedRoute.value,
                            alignment: Alignment.center,
                            items: ["순환5_DOWN", "순환5_UP", "900_UP", "900_DOWN"]
                                .map((route) => DropdownMenuItem(
                              value: route, // 내부적으로 사용되는 값
                              child: Text(
                                routeDisplayNames[route] ?? route, // 사용자에게 표시되는 텍스트
                                textAlign: TextAlign.center,
                              ),
                            ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectedRoute.value = value;
                                controller.fetchRouteData();
                                controller.fetchStationData();
                                controller.resetConnection();
                              }
                            },
                          )),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: '노선 정보',
                      onPressed: () => _showRouteInfo(context, controller),
                    ),
                  ],
                ),
                Expanded(
                  child: FlutterMap(
                    mapController: controller.mapController,
                    options: MapOptions(
                      initialCenter: LatLng(36.769423, 127.047998),
                      initialZoom: 13,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      Obx(() => PolylineLayer(polylines: controller.polylines.toList())),
                      Obx(() => MarkerLayer(markers: controller.stationMarkers.toList())),
                      Obx(() => MarkerLayer(markers: controller.markers.toList())),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRouteInfo(BuildContext context, BusMapViewModel controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      TabBar(
                        tabs: const [
                          Tab(text: '노선 정보'),
                          Tab(text: '시간표'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildRouteInfo(controller),
                            _buildTimetable(controller),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo(BusMapViewModel controller) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadTimetable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('정보를 불러올 수 없습니다: ${snapshot.error}'));
        }

        final routeData = snapshot.data?[controller.selectedRoute.value];
        if (routeData == null) return const Center(child: Text('노선 정보가 없습니다'));

        final List<dynamic> times = routeData['시간표'] ?? [];
        final String firstBus = times.isNotEmpty ? times.first.toString() : '-';
        final String lastBus = times.isNotEmpty ? times.last.toString() : '-';
        final String interval = _calculateInterval(times);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _infoCard(context, '노선', routeSimpleNames[controller.selectedRoute.value] ?? controller.selectedRoute.value),
            _infoCard(context, '기점', routeData['출발지'] ?? '-'),
            _infoCard(context, '종점', routeData['종점'] ?? '-'),
            _infoCard(context, '배차 간격', interval),
            _infoCard(context, '운행시간', "$firstBus ~ $lastBus"),
          ],
        );
      },
    );
  }

  String _calculateInterval(List<dynamic> times) {
    if (times.length < 2) return '-';

    try {
      List<int> intervals = [];
      for (int i = 0; i < times.length - 1; i++) {
        final current = _parseTime(times[i].toString());
        final next = _parseTime(times[i + 1].toString());
        intervals.add(_minutesBetween(current, next));
      }

      // 최빈값 계산
      Map<int, int> frequency = {};
      intervals.forEach((interval) {
        frequency[interval] = (frequency[interval] ?? 0) + 1;
      });

      final mostCommon = frequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      return '$mostCommon분';
    } catch (e) {
      return '-';
    }
  }

  DateTime _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return DateTime(2024, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  int _minutesBetween(DateTime time1, DateTime time2) {
    return time2.difference(time1).inMinutes;
  }

  Widget _infoCard(BuildContext context, String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              content,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimetable(BusMapViewModel controller) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadTimetable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('시간표를 불러올 수 없습니다: ${snapshot.error}'));
        }

        final times = (snapshot.data?[controller.selectedRoute.value]?['시간표'] as List<dynamic>?) ?? [];

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: times.length,
          itemBuilder: (context, index) => Card(
            child: Center(
              child: Text(
                times[index].toString(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadTimetable() async {
    final String jsonString = await rootBundle.loadString('assets/bus_times/bus_times.json');
    return json.decode(jsonString);
  }
}