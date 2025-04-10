import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodel/busmap_viewmodel.dart';
import 'bus_timetable_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/rendering.dart';
import 'bus_map_detail_view.dart';

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
        actions: [
          GetBuilder<BusMapViewModel>(
            builder: (controller) => IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => Get.to(() => BusMapDetailView(routeName: routeDisplayNames[controller.selectedRoute.value] ?? controller.selectedRoute.value)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.near_me),
            tooltip: '가까운 정류장 찾기',
            onPressed: () => _findNearestStationAndScroll(),
          ),
        ],
      ),
      body: GetBuilder<BusMapViewModel>(
        init: BusMapViewModel(),
        builder: (controller) => Column(
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
                            // 노선 변경 전에 현재 데이터 초기화
                            controller.currentPositions.clear();
                            controller.markers.clear();
                            controller.stationMarkers.clear();
                            controller.stationNames.clear();
                            
                            // 노선 변경 및 데이터 로드
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
              child: _buildBusProgressView(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusProgressView(BusMapViewModel controller) {
    return Obx(() {
      final currentPositions = controller.currentPositions;
      final totalStations = controller.stationMarkers.length;
      
      if (totalStations == 0) {
        // 정류장 데이터 로딩 중일 때 표시할 UI
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                '${routeDisplayNames[controller.selectedRoute.value] ?? controller.selectedRoute.value}\n정류장 정보를 불러오는 중입니다...',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      
      if (controller.stationNames.isEmpty) {
        return const Center(child: Text('정류장 정보가 없습니다.'));
      }
      
      return ListView.builder(
        primary: true, // PrimaryScrollController 사용
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.stationNames.length,
        itemBuilder: (context, index) {
          final isBusHere = currentPositions.contains(index);
          final stationName = controller.stationNames.length > index 
              ? controller.stationNames[index] 
              : "정류장 ${index + 1}";
          
          // 마지막 정류장인지 확인
          final isLastStation = index == controller.stationNames.length - 1;
          
          return StationItem(
            index: index, 
            stationName: stationName, 
            isBusHere: isBusHere, 
            isLastStation: isLastStation
          );
        },
      );
    });
  }

  void _showRouteInfo(BuildContext context, BusMapViewModel controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.9,
          builder: (context, scrollController) => GestureDetector(
            onTap: () {}, // 내부 터치 이벤트 전파 방지
            child: Container(
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

  // 가장 가까운 정류장 찾기 및 해당 정류장으로 스크롤
  void _findNearestStationAndScroll() {
    final controller = Get.find<BusMapViewModel>();
    
    if (controller.currentLocation.value == null) {
      // 위치 정보가 없으면 먼저 위치 권한 요청
      controller.checkLocationPermission().then((_) {
        _processNearestStation(controller);
      });
    } else {
      _processNearestStation(controller);
    }
  }
  
  void _processNearestStation(BusMapViewModel controller) {
    final nearestStationIndex = controller.findNearestStation();
    
    if (nearestStationIndex == null) {
      Fluttertoast.showToast(
        msg: "가까운 정류장을 찾을 수 없습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }
    
    // ListView로 스크롤하기 위해 GlobalKey 사용
    final scrollController = PrimaryScrollController.of(Get.context!);
    if (scrollController != null) {
      // 해당 인덱스로 스크롤
      final stationName = controller.stationNames[nearestStationIndex];
      
      // 스크롤 애니메이션
      scrollController.animateTo(
        nearestStationIndex * 100.0, // 대략적인 아이템 높이에 인덱스를 곱함
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      
      // 토스트 메시지 표시
      Fluttertoast.showToast(
        msg: "가장 가까운 정류장: $stationName",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}

class StationItem extends StatelessWidget {
  final int index;
  final String stationName;
  final bool isBusHere;
  final bool isLastStation;

  const StationItem({
    Key? key,
    required this.index,
    required this.stationName,
    required this.isBusHere,
    required this.isLastStation,
  }) : super(key: key);

  Widget build(BuildContext context) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 26.0, horizontal: 16.0),
            child: Row(
              children: [
                // 왼쪽: 정류장 번호와 연결선
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    children: [
                      CustomPaint(
                        painter: StationPainter(
                          index: index,
                          isLastStation: isLastStation,
                        ),
                        size: const Size(24, 24),
                      ),
                      const Center(
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // 버스 아이콘
                SizedBox(
                  width: 40,
                  child: isBusHere
                      ? const Icon(
                          Icons.directions_bus,
                          color: Colors.blue,
                          size: 20,
                        )
                      : null,
                ),

                // 정류장 이름과 번호
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stationName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isBusHere ? FontWeight.bold : FontWeight.normal,
                          color: isBusHere ? Colors.blue : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() {
                        final controller = Get.find<BusMapViewModel>();
                        final stationNumber = controller.stationNumbers.length > index 
                            ? controller.stationNumbers[index] 
                            : "";
                        return Text(
                          "$stationNumber",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 구분선
          if (!isLastStation)
            const Padding(
              padding: EdgeInsets.only(left: 76.0),
              child: Divider(height: 0, thickness: 1, color: Colors.grey),
            ),
        ],
      );
    }
}

class StationPainter extends CustomPainter {
  final int index;
  final bool isLastStation;
  
  StationPainter({
    required this.index,
    required this.isLastStation,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // 원 그리기
    final Paint circlePaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;
      
    final Paint borderPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    
    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius, borderPaint);
    
    // 세로선 그리기 (마지막 정류장이 아닌 경우)
    if (!isLastStation) {
      final Paint linePaint = Paint()
        ..color = Colors.grey[300]!
        ..strokeWidth = 2.0;
      
      final startPoint = Offset(size.width / 2, size.height);
      final endPoint = Offset(size.width / 2, size.height + 64.0); // 다음 원까지의 거리
      
      canvas.drawLine(startPoint, endPoint, linePaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}