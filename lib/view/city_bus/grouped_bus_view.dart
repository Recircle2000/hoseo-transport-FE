import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../city_bus/bus_map_view.dart';
import '../../viewmodel/busmap_viewmodel.dart';
import '../../viewmodel/settings_viewmodel.dart';
import '../../utils/bus_times_loader.dart';

class CityBusGroupedView extends StatefulWidget {
  const CityBusGroupedView({Key? key}) : super(key: key);

  @override
  State<CityBusGroupedView> createState() => _CityBusGroupedViewState();
}

class _CityBusGroupedViewState extends State<CityBusGroupedView> {
  final settingsViewModel = Get.find<SettingsViewModel>();
  late final BusMapViewModel busMapViewModel;

  // 아산캠퍼스 노선 그룹핑 정보
  final List<Map<String, dynamic>> groupedRoutesAsan = [
    {
      'title': '천안아산역 · 지중해마을 방면',
      'subtitle': '아산캠퍼스 ↔ 천안아산역',
      'subGroups': [
        {
          'title': '아캠 출발',
          'icon': Icons.logout,
          'routes': [
            {
              'routeKey': '순환5_DOWN',
              'label': '순환5 (천안아산역 방면)',
            },
            {
              'routeKey': '1000_DOWN',
              'label': '1000 (지중해마을 방면)',
            },
          ],
        },
        {
          'title': '아캠 도착',
          'icon': Icons.login,
          'routes': [
            {
              'routeKey': '순환5_UP',
              'label': '순환5 (아산캠퍼스 방면)',
            },
            {
              'routeKey': '1000_UP',
              'label': '1000 (아산캠퍼스 방면)',
            },
          ],
        },
      ],
    },
    {
      'title': '아산터미널 방면',
      'subtitle': '아산캠퍼스 ↔ 아산터미널',
      'subGroups': [
        {
          'title': '아캠 출발',
          'icon': Icons.logout,
          'routes': [
            {
              'routeKey': '810_DOWN',
              'label': '810 (아산터미널 방면)',
            },
            {
              'routeKey': '820_DOWN',
              'label': '820 (아산터미널 방면)',
            },
            {
              'routeKey': '821_DOWN',
              'label': '821 (아산터미널 방면)',
            },
            {
              'routeKey': '822_DOWN',
              'label': '822 (아산터미널 방면)',
            },
          ],
        },
        {
          'title': '아캠 도착',
          'icon': Icons.login,
          'routes': [
            {
              'routeKey': '810_UP',
              'label': '810 (아산캠퍼스 방면)',
            },
            {
              'routeKey': '820_UP',
              'label': '820 (아산캠퍼스 방면)',
            },
            {
              'routeKey': '821_UP',
              'label': '821 (아산캠퍼스 방면)',
            },
            {
              'routeKey': '822_UP',
              'label': '822 (아산캠퍼스 방면)',
            },
          ],
        },
      ],
    },
  ];

  // 천안캠퍼스 노선 그룹핑 정보
  final List<Map<String, dynamic>> groupedRoutesCheonan = [
    {
      'title': '동우아파트 방면',
      'subtitle': '천안캠퍼스 ↔ 동우아파트',
      'subGroups': [
        {
          'title': '천캠 출발',
          'icon': Icons.logout,
          'routes': [
            {
              'routeKey': '24_DOWN',
              'label': '24 (동우아파트 방면)',
            },
          ],
        },
        {
          'title': '천캠 도착',
          'icon': Icons.login,
          'routes': [
            {
              'routeKey': '24_UP',
              'label': '24 (천안캠퍼스 방면)',
            },
          ],
        },
      ],
    },
    {
      'title': '차암2통 방면',
      'subtitle': '천안캠퍼스 ↔ 차암2통',
      'subGroups': [
        {
          'title': '천캠 출발',
          'icon': Icons.logout,
          'routes': [
            {
              'routeKey': '81_DOWN',
              'label': '81 (차암2통 방면)',
            },
          ],
        },
        {
          'title': '천캠 도착',
          'icon': Icons.login,
          'routes': [
            {
              'routeKey': '81_UP',
              'label': '81 (천안캠퍼스 방면)',
            },
          ],
        },
      ],
    },
  ];

  // 모든 노선의 다음 출발시간을 한 번에 관리
  final RxMap<String, String> allNextDepartureTimes = <String, String>{}.obs;
  bool _busTimesLoaded = false;

  Future<void> _loadAllNextDepartureTimes() async {
    if (_busTimesLoaded) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final busTimes = await BusTimesLoader.loadBusTimes();
    // 모든 노선에 대해 계산
    for (final group in [...groupedRoutesAsan, ...groupedRoutesCheonan]) {
      for (final subGroup in group['subGroups']) {
        for (final route in subGroup['routes']) {
          final routeKey = route['routeKey'];
          final timetable = busTimes[routeKey]?['시간표'] as List<dynamic>?;
          if (timetable == null || timetable.isEmpty) {
            allNextDepartureTimes[routeKey] = '시간표 없음';
            continue;
          }
          final times = timetable.map((t) {
            final parts = t.split(':');
            return DateTime(today.year, today.month, today.day, int.parse(parts[0]), int.parse(parts[1]));
          }).toList();
          final next = times.firstWhereOrNull((t) => t.isAfter(now));
          if (next != null) {
            allNextDepartureTimes[routeKey] = '출발: ${next.hour.toString().padLeft(2, '0')}:${next.minute.toString().padLeft(2, '0')}';
          } else {
            allNextDepartureTimes[routeKey] = '운행 종료';
          }
        }
      }
    }
    _busTimesLoaded = true;
  }

  @override
  void initState() {
    super.initState();
    // BusMapViewModel 인스턴스 생성 및 초기화
    busMapViewModel = Get.put(BusMapViewModel(), tag: 'grouped_view');
    _loadAllNextDepartureTimes();
  }

  @override
  void dispose() {
    Get.delete<BusMapViewModel>(tag: 'grouped_view');
    super.dispose();
  }

  /// 특정 노선의 현재 버스 위치 정보를 가져오는 함수
  String _getBusLocationStatus(String routeKey) {
    // ViewModel에서 해당 노선의 버스 데이터 확인
    if (busMapViewModel.allRoutesBusData.containsKey(routeKey)) {
      final buses = busMapViewModel.allRoutesBusData[routeKey]!;
      
      if (buses.isNotEmpty) {
        if (buses.length == 1) {
          return '${buses.first.stationName}';
        } else {
          return '운행중 ${buses.length}대 (${buses.first.stationName} 외)';
        }
      }
    }
    
    return '현재 운행 없음';
  }

  /// 특정 노선의 다음 출발시간 정보를 가져오는 함수
  String _getNextDepartureTime(String routeKey) {
    // 모든 노선에 대해 출발시간 표시 (UP, DOWN 구분 없이)
    return allNextDepartureTimes[routeKey] ?? '로딩...';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    return Scaffold(
      appBar: AppBar(
        title: const Text('시내버스 노선 정보'),
        centerTitle: true,
        backgroundColor: cardColor,
        elevation: 0,
      ),
      body: Obx(() {
        final campus = settingsViewModel.selectedCampus.value;
        final groupedRoutes = campus == '천안' ? groupedRoutesCheonan : groupedRoutesAsan;
                 return ListView.separated(
           padding: const EdgeInsets.all(12),
           itemCount: groupedRoutes.length,
           separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, groupIdx) {
            final group = groupedRoutes[groupIdx];
            return Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 메인 그룹 타이틀
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.blue),
                        const SizedBox(width: 6),
                        Text(
                          group['subtitle'] ?? group['title'],
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 서브 그룹들
                    ...List.generate(group['subGroups'].length, (subGroupIdx) {
                      final subGroup = group['subGroups'][subGroupIdx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 서브 그룹 타이틀
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  subGroup['icon'],
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  subGroup['title'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          // 서브 그룹의 노선들
                          ...List.generate(subGroup['routes'].length, (routeIdx) {
                            final route = subGroup['routes'][routeIdx];
                            final routeKey = route['routeKey'];
                            final label = route['label'];
                            return Obx(() {
                              final busLocationStatus = _getBusLocationStatus(routeKey);
                              final nextDepartureTime = _getNextDepartureTime(routeKey);
                              
                              return Padding(
                                padding: const EdgeInsets.only(left: 12, top: 3, bottom: 3),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Get.to(() => BusMapView(initialRoute: routeKey));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDarkMode 
                                          ? Colors.grey[800]?.withOpacity(0.3)
                                          : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDarkMode 
                                            ? Colors.grey[700]!.withOpacity(0.5)
                                            : Colors.grey[300]!.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // 첫 번째 줄: 노선명 + 다음 출발시간
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              nextDepartureTime,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: nextDepartureTime == '운행 종료' || nextDepartureTime == '로딩...' 
                                                    ? Colors.grey 
                                                    : Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // 두 번째 줄: 현재 버스 위치

                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 13,
                                              color: busLocationStatus == '현재 운행 없음'
                                                  ? Colors.grey
                                                  : Colors.blue,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              busLocationStatus,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: busLocationStatus == '현재 운행 없음'
                                                    ? Colors.grey
                                                    : Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            });
                          }),
                          if (subGroupIdx < group['subGroups'].length - 1)
                            const SizedBox(height: 12), // 서브 그룹 간 간격
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
