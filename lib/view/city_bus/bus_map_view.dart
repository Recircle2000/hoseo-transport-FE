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
  final String? initialRoute;
  final String? initialDestination;
  
  const BusMapView({Key? key, this.initialRoute, this.initialDestination}) : super(key: key);

  @override
  State<BusMapView> createState() => _BusMapViewState();
}

class _BusMapViewState extends State<BusMapView> {
  final Map<String, String> routeDisplayNames = {
    // 노선 이름 표시용
    "순환5_DOWN": "순환5 (호서대학교 → 천안아산역)",
    "순환5_UP": "순환5 (천안아산역 → 호서대학교)",
    "1000_UP": "1000 (탕정면사무소 → 호서대학교)",
    "1000_DOWN": "1000 (호서대학교 → 탕정면사무소)",
    "810_UP": "810 (아산터미널 → 호서대학교)",
    "810_DOWN": "810 (호서대학교 → 아산터미널)",
    "820_UP": "820 (아산터미널 → 호서대학교)",
    "820_DOWN": "820 (호서대학교 → 아산터미널)",
    "821_UP": "821 (아산터미널 → 호서대학교)",
    "821_DOWN": "821 (호서대학교 → 아산터미널)",
  };

  final Map<String, String> routeSimpleNames = {
    // 노선 이름 간단 표시용
    "순환5_DOWN": "순환5",
    "순환5_UP": "순환5",
    "1000_UP": "1000",
    "1000_DOWN": "1000",
    "810_UP": "810",
    "810_DOWN": "810",
    "820_UP": "820",
    "820_DOWN": "820",
    "821_UP": "821",
    "821_DOWN": "821",
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
    
    // 초기 노선이 지정된 경우 자동 선택
    if (widget.initialRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = Get.find<BusMapViewModel>();
        // 노선 매핑 확인
        String? mappedRoute = _findMappedRoute(widget.initialRoute!, destination: widget.initialDestination);
        if (mappedRoute != null) {
          controller.currentPositions.clear();
          controller.markers.clear();
          controller.stationMarkers.clear();
          controller.stationNames.clear();
          controller.selectedRoute.value = mappedRoute;
          controller.fetchRouteData();
          controller.fetchStationData();
          controller.resetConnection();
        }
      });
    }
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
            
            // 운행 중인 버스가 없을 때 표시할 정보
            Obx(() {
              if (controller.stationNames.isNotEmpty && 
                  controller.hasReceivedWebSocketData.value && 
                  controller.markers.isEmpty) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '현재 노선에 운행 중인 버스가 없습니다.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

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
                                    ? RouteInfoView(
                                        routeDisplayNames: routeDisplayNames,
                                        routeSimpleNames: routeSimpleNames,
                                      )
                                    : TimetableView()
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

  String? _findMappedRoute(String routeName, {String? destination}) {
    // 목적지 정보가 있는 경우 상행/하행 구분
    if (destination != null) {
      // 목적지를 기반으로 상행/하행 판단
      bool isUpDirection = _isUpDirection(destination);
      
      // 해당 노선의 상행/하행 키 찾기
      String targetSuffix = isUpDirection ? "_UP" : "_DOWN";
      String targetKey = "${routeName}${targetSuffix}";
      
      if (routeDisplayNames.containsKey(targetKey)) {
        return targetKey;
      }
    }
    
    // 목적지 정보가 없거나 매칭되지 않는 경우 기존 로직 사용
    for (String key in routeDisplayNames.keys) {
      if (key.startsWith(routeName)) {
        return key;
      }
    }
    
    // 직접 매칭되는 키가 있는지 확인
    if (routeDisplayNames.containsKey(routeName)) {
      return routeName;
    }
    
    return null;
  }
  
  bool _isUpDirection(String destination) {
    // 호서대학교 방향이면 상행(UP), 그 외는 하행(DOWN)
    List<String> upDestinations = [
      '호서대학교',
      '호서대',
    ];
    
    List<String> downDestinations = [
      '천안아산역',
      '아산역', 
      '아산터미널',
      '탕정면사무소',
      '지중해마을',
    ];
    
    // 상행 목적지 확인 (호서대학교 방향)
    for (String upDest in upDestinations) {
      if (destination.contains(upDest)) {
        return true;
      }
    }
    
    // 하행 목적지 확인 (호서대학교에서 출발하는 방향)
    for (String downDest in downDestinations) {
      if (destination.contains(downDest)) {
        return false;
      }
    }
    
    // 기본값은 하행
    return false;
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
