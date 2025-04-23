import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodel/busmap_viewmodel.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/rendering.dart';
import 'bus_map_detail_view.dart';
import 'components/route_picker.dart';
import 'components/station_list.dart';
import 'components/route_info_view.dart';
import 'components/timetable_view.dart';
import 'helpers/location_helper.dart';

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
            onPressed: () => LocationHelper.findNearestStationAndScroll(
              context, stationScrollController
            ),
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
                      child: RoutePicker(
                        routeDisplayNames: routeDisplayNames,
                        onRouteSelected: (route) {
                          controller.currentPositions.clear();
                          controller.markers.clear();
                          controller.stationMarkers.clear();
                          controller.stationNames.clear();
                          controller.selectedRoute.value = route;
                          controller.fetchRouteData();
                          controller.fetchStationData();
                          controller.resetConnection();
                        },
                      ),
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
              child: StationList(
                routeDisplayNames: routeDisplayNames,
                scrollController: stationScrollController,
              ),
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
                    child: kIsWeb || !Platform.isIOS
                        ? DefaultTabController(
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
                                      RouteInfoView(
                                        routeDisplayNames: routeDisplayNames,
                                        routeSimpleNames: routeSimpleNames,
                                      ),
                                      TimetableView(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DefaultTabController(
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
                                    ? RouteInfoView(
                                        routeDisplayNames: routeDisplayNames,
                                        routeSimpleNames: routeSimpleNames,
                                      )
                                    : TimetableView()
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
