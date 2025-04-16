import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodel/busmap_viewmodel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/rendering.dart';
import 'bus_map_Ndetail_view.dart';
import 'bus_map_detail_view.dart';

// BusMapViewModel 확장 - 강조 표시용 변수 추가
extension BusMapViewModelExtension on BusMapViewModel {
  static final RxInt highlightedStation = RxInt(-1);
  
  void highlightStation(int index) {
    BusMapViewModelExtension.highlightedStation.value = index;
  }
  
  void clearHighlightedStation() {
    BusMapViewModelExtension.highlightedStation.value = -1;
  }
}

class BusMapView extends StatefulWidget {
  const BusMapView({Key? key}) : super(key: key);

  @override
  State<BusMapView> createState() => _BusMapViewState();
}

class _BusMapViewState extends State<BusMapView> {
  final Map<String, String> routeDisplayNames = {
    // 노선 이름 표시용
    "순환5_DOWN": "순환5 (호서대학교 → 천안아산역)",
    "순환5_UP": "순환5 (천안아산역 → 호서대학교)",
    "900_DOWN": "900 (천안터미널 → 아산터미널)",
    "900_UP": "900 (아산터미널 → 천안터미널)"
  };

  final Map<String, String> routeSimpleNames = {
    // 노선 이름 간단 표시용
    "순환5_DOWN": "순환5",
    "순환5_UP": "순환5",
    "900_DOWN": "900",
    "900_UP": "900"
  };
  
  // 스크롤 컨트롤러 선언
  late ScrollController stationScrollController;
  
  @override
  void initState() {
    super.initState();
    // 스크롤 컨트롤러 초기화
    stationScrollController = ScrollController();
    
    // 스크롤 상태 모니터링 (디버깅용)
    stationScrollController.addListener(() {
      // print("스크롤 위치: ${stationScrollController.position.pixels}");
    });
  }
  
  @override
  void dispose() {
    // 스크롤 컨트롤러 해제
    stationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시내버스 위치'),
        actions: [
          GetBuilder<BusMapViewModel>(
            builder: (controller) => IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => Get.to(() => BusMapDetailView(
                  routeName:
                      routeDisplayNames[controller.selectedRoute.value] ??
                          controller.selectedRoute.value)),
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
                      child: Obx(() {
                        if (Platform.isIOS) {
                          return GestureDetector(
                            onTap: () {
                              String tempSelectedRoute =
                                  controller.selectedRoute.value;
                              int initialIndex = [
                                "순환5_DOWN",
                                "순환5_UP",
                                "900_UP",
                                "900_DOWN"
                              ].indexOf(controller.selectedRoute.value);

                              FixedExtentScrollController scrollController =
                                  FixedExtentScrollController(
                                      initialItem: initialIndex);

                              showCupertinoModalPopup(
                                context: context,
                                builder: (_) => Container(
                                  height: 250,
                                  color: Colors.white,
                                  child: Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: TextButton(
                                          onPressed: () {
                                            controller.selectedRoute.value =
                                                tempSelectedRoute; // 현재 선택된 노선 업데이트
                                            controller.fetchRouteData();
                                            controller.fetchStationData();
                                            controller.resetConnection();
                                            Navigator.pop(context);
                                          },
                                          child: const Text('적용'),
                                        ),
                                      ),
                                      Expanded(
                                        child: CupertinoPicker(
                                          scrollController: scrollController,
                                          itemExtent: 32,
                                          onSelectedItemChanged: (index) {
                                            tempSelectedRoute = [
                                              "순환5_DOWN",
                                              "순환5_UP",
                                              "900_UP",
                                              "900_DOWN"
                                            ][index];
                                          },
                                          children: [
                                            "순환5_DOWN",
                                            "순환5_UP",
                                            "900_UP",
                                            "900_DOWN"
                                          ]
                                              .map((route) => Center(
                                                    child: Text(
                                                        routeDisplayNames[
                                                                route] ??
                                                            route),
                                                  ))
                                              .toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    routeDisplayNames[
                                            controller.selectedRoute.value] ??
                                        controller.selectedRoute.value,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return DropdownButton<String>(
                            isExpanded: true,
                            value: controller.selectedRoute.value,
                            alignment: Alignment.center,
                            items: ["순환5_DOWN", "순환5_UP", "900_UP", "900_DOWN"]
                                .map((route) => DropdownMenuItem(
                                      value: route,
                                      child: Text(
                                        routeDisplayNames[route] ?? route,
                                        textAlign: TextAlign.center,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.currentPositions.clear();
                                controller.markers.clear();
                                controller.stationMarkers.clear();
                                controller.stationNames.clear();
                                controller.selectedRoute.value = value;
                                controller.fetchRouteData();
                                controller.fetchStationData();
                                controller.resetConnection();
                              }
                            },
                          );
                        }
                      }),
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
        primary: false, // PrimaryScrollController 대신 직접 컨트롤러 사용
        controller: stationScrollController, // 명시적 ScrollController 연결
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
              isLastStation: isLastStation);
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                    child: Platform.isIOS
                        ? DefaultTabController(
                          length: 2,
                          child: Column(
                            children: [
                              Container(
                                width: 350,
                                child: Obx(() => CupertinoSlidingSegmentedControl<int>(
                                  children: const {
                                    0: Text('노선 정보'),
                                    1: Text('시간표'),
                                  },
                                  groupValue: controller.selectedTab.value,
                                  onValueChanged: (value) {
                                    if (value != null) {
                                      controller.selectedTab.value = value;
                                    }
                                  },
                                )),
                              ),
                              Expanded(
                                child: Obx(() =>
                                  controller.selectedTab.value == 0
                                    ? _buildRouteInfo(controller)
                                    : _buildTimetable(controller)
                                ),
                              ),
                            ],
                          ),
                        )
                        : DefaultTabController(
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
            _infoCard(
                context,
                '노선',
                routeSimpleNames[controller.selectedRoute.value] ??
                    controller.selectedRoute.value),
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

      final mostCommon =
          frequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;

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

        final times = (snapshot.data?[controller.selectedRoute.value]?['시간표']
                as List<dynamic>?) ??
            [];

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
    final String jsonString =
        await rootBundle.loadString('assets/bus_times/bus_times.json');
    return json.decode(jsonString);
  }

  // 가장 가까운 정류장 찾기 및 해당 정류장으로 스크롤
  void _findNearestStationAndScroll() {
    final controller = Get.find<BusMapViewModel>();


    if (controller.currentLocation.value == null) {
      // 위치 정보가 없으면 먼저 위치 권한 요청
      controller.checkLocationPermission().then((_) {
        if (controller.currentLocation.value != null) {
          _processNearestStation(controller);
        } else {
          Fluttertoast.showToast(
            msg: "위치 정보를 가져올 수 없습니다. 다시 시도해주세요.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
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

    try {
      // 정류장 강조 표시
      BusMapViewModelExtension.highlightedStation.value = nearestStationIndex;
      
      // 5초 후 강조 표시 해제 타이머 설정
      Future.delayed(const Duration(seconds: 5), () {
        // 현재도 같은 정류장이 강조되어 있다면 해제
        if (BusMapViewModelExtension.highlightedStation.value == nearestStationIndex) {
          BusMapViewModelExtension.highlightedStation.value = -1;
        }
      });
      
      // 직접 생성한 ScrollController 사용
      if (stationScrollController.hasClients) {
        // 해당 인덱스로 스크롤
        final stationName = controller.stationNames[nearestStationIndex];
        
        // 레이아웃이 준비된 후 스크롤 실행 (더 정확한 계산을 위해)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 목표 위치 계산
          double targetOffset = 0.0;
          
          // 두 가지 방법으로 시도: 1) 고정 높이 기반, 2) 실제 렌더박스 크기 기반
          
          // 먼저 렌더박스를 사용하여 실제 항목 높이 얻기 시도
          try {
            final RenderBox? listBox = context.findRenderObject() as RenderBox?;
            if (listBox != null) {
              // 목록 높이와 아이템 수를 사용하여 평균 높이 계산
              double listHeight = listBox.size.height;
              int visibleItems = (listHeight / 81.0).ceil(); // 대략적인 아이템 수
              
              // 렌더박스에서 얻은 정보 기반으로 스크롤 계산
              double itemHeight = listHeight / visibleItems;
              targetOffset = nearestStationIndex * itemHeight;
              print("렌더박스 기반 계산: 높이 $itemHeight, 오프셋 $targetOffset");
            } else {
              // 고정 높이 기반으로 계산
              double itemHeight = 81.0; // 기본 StationItem 높이
              targetOffset = nearestStationIndex * itemHeight;
              print("고정 높이 기반 계산: $targetOffset");
            }
          } catch (e) {
            // 예외 발생 시 고정 높이 사용
            print("렌더박스 계산 오류, 고정 높이 사용: $e");
            targetOffset = nearestStationIndex * 81.0;
          }
          
          // 안전한 스크롤 범위 내로 제한
          double safeOffset = targetOffset.clamp(
            0.0, 
            stationScrollController.position.maxScrollExtent
          );
          
          print("스크롤 시도: 인덱스 $nearestStationIndex, 위치 $safeOffset");
          
          // 부드러운 스크롤 시도
          stationScrollController.animateTo(
            safeOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ).catchError((error) {
            print("animateTo 실패, jumpTo 시도: $error");
            // 애니메이션 실패 시 즉시 이동
            stationScrollController.jumpTo(safeOffset);
          });
        });
      } else {
        // 스크롤 컨트롤러가 없거나 준비되지 않은 경우
        print("스크롤 컨트롤러가 준비되지 않았습니다");
        Fluttertoast.showToast(
          msg: "가장 가까운 정류장: ${controller.stationNames[nearestStationIndex]}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      print("스크롤 처리 중 오류 발생: $e");
      // 오류 발생시에도 정류장 정보는 표시시
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
    return Obx(() {
      // 강조 표시 여부 확인
      final isHighlighted = BusMapViewModelExtension.highlightedStation.value == index;
      
      // 강조 표시된 정류장이면 애니메이션 효과 추가
      if (isHighlighted) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Container(
              decoration: BoxDecoration(
                color: Color.lerp(Colors.transparent, Colors.yellow.withOpacity(0.3), value),
                borderRadius: BorderRadius.circular(8),
              ),
              child: child,
            );
          },
          child: _buildStationContent(context, isHighlighted),
        );
      }
      
      // 일반 정류장
      return _buildStationContent(context, isHighlighted);
    });
  }
  
  // 정류장 내용 위젯
  Widget _buildStationContent(BuildContext context, bool isHighlighted) {
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
                        isHighlighted: isHighlighted,
                      ),
                      size: const Size(24, 24),
                    ),
                    Center(
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: isHighlighted ? Colors.orange : Colors.grey,
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
                    // 강조 표시된 정류장이면 위치 아이콘 표시
                    : isHighlighted 
                      ? _buildPulsingIcon()
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
                        fontWeight: isBusHere || isHighlighted 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        color: isHighlighted 
                            ? Colors.orange
                            : isBusHere
                              ? Colors.blue
                              : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      final controller = Get.find<BusMapViewModel>();
                      final stationNumber =
                          controller.stationNumbers.length > index
                              ? controller.stationNumbers[index]
                              : "";
                      return Text(
                        "$stationNumber",
                        style: TextStyle(
                          fontSize: 12,
                          color: isHighlighted ? Colors.orange[700] : Colors.grey,
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
          Padding(
            padding: const EdgeInsets.only(left: 76.0),
            child: Divider(
              height: 0, 
              thickness: 1, 
              color: isHighlighted ? Colors.orange.withOpacity(0.3) : Colors.grey,
            ),
          ),
      ],
    );
  }
  
  // 펄스 애니메이션 아이콘
  Widget _buildPulsingIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      // 애니메이션 반복
      onEnd: () {
        // 반복 애니메이션을 위해 다시 빌드하게 함
        Future.microtask(() => BusMapViewModelExtension.highlightedStation.refresh());
      },
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: const Icon(
        Icons.location_on,
        color: Colors.orange,
        size: 20,
      ),
    );
  }
}

class StationPainter extends CustomPainter {
  final int index;
  final bool isLastStation;
  final bool isHighlighted;

  StationPainter({
    required this.index,
    required this.isLastStation,
    required this.isHighlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 원 그리기
    final Paint circlePaint = Paint()
      ..color = isHighlighted ? Colors.orange[100]! : Colors.grey[300]!
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = isHighlighted ? Colors.orange : Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted ? 2.0 : 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 세로선 그리기 (마지막 정류장이 아닌 경우)
    if (!isLastStation) {
      final Paint linePaint = Paint()
        ..color = isHighlighted ? Colors.orange[300]! : Colors.grey[300]!
        ..strokeWidth = isHighlighted ? 2.0 : 2.0;

      final startPoint = Offset(size.width / 2, size.height);
      final endPoint = Offset(size.width / 2, size.height + 64.0); // 다음 원까지의 거리

      canvas.drawLine(startPoint, endPoint, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
