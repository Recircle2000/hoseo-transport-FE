import 'package:flutter/material.dart';
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

  // 아산캠퍼스 노선 그룹핑 정보
  final List<Map<String, dynamic>> groupedRoutesAsan = [
    {
      'title': '천안아산역 · 지중해마을 방면',
      'subtitle': '아산캠퍼스 ↔ 천안아산역',
      'routes': [
        {
          'routeKey': '순환5_DOWN',
          'label': '순환5 (천안아산역 방면)',
        },
        {
          'routeKey': '순환5_UP',
          'label': '순환5 (아산캠퍼스 방면)',
        },
        {
          'routeKey': '1000_DOWN',
          'label': '1000 (지중해마을 방면)',
        },
        {
          'routeKey': '1000_UP',
          'label': '1000 (아산캠퍼스 방면)',
        },
      ],
    },
    {
      'title': '아산터미널 방면',
      'subtitle': '아산캠퍼스 ↔ 아산터미널',
      'routes': [
        {
          'routeKey': '810_DOWN',
          'label': '810 (아산터미널 방면)',
        },
        {
          'routeKey': '810_UP',
          'label': '810 (아산캠퍼스 방면)',
        },
        {
          'routeKey': '820_DOWN',
          'label': '820 (아산터미널 방면)',
        },
        {
          'routeKey': '820_UP',
          'label': '820 (아산캠퍼스 방면)',
        },
        {
          'routeKey': '821_DOWN',
          'label': '821 (아산터미널 방면)',
        },
        {
          'routeKey': '821_UP',
          'label': '821 (아산캠퍼스 방면)',
        },
        {
          'routeKey': '822_DOWN',
          'label': '822 (아산터미널 방면)',
        },
        {
          'routeKey': '822_UP',
          'label': '822 (아산캠퍼스 방면)',
        },
      ],
    },
  ];

  // 천안캠퍼스 노선 그룹핑 정보
  final List<Map<String, dynamic>> groupedRoutesCheonan = [
    {
      'title': '동우아파트 방면',
      'subtitle': '천안캠퍼스 ↔ 동우아파트',
      'routes': [
        {
          'routeKey': '24_DOWN',
          'label': '24 (동우아파트 방면)',
        },
        {
          'routeKey': '24_UP',
          'label': '24 (천안캠퍼스 방면)',
        },
      ],
    },
    {
      'title': '차암2통 방면',
      'subtitle': '천안캠퍼스 ↔ 차암2통',
      'routes': [
        {
          'routeKey': '81_DOWN',
          'label': '81 (차암2통 방면)',
        },
        {
          'routeKey': '81_UP',
          'label': '81 (천안캠퍼스 방면)',
        },
      ],
    },
  ];

  final Map<String, BusMapViewModel> _viewModels = {};

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
      for (final route in group['routes']) {
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
    _busTimesLoaded = true;
  }

  @override
  void initState() {
    super.initState();
    _loadAllNextDepartureTimes();
  }

  @override
  void dispose() {
    for (final vm in _viewModels.values) {
      vm.dispose();
    }
    super.dispose();
  }

  BusMapViewModel _getViewModel(String routeKey) {
    if (_viewModels.containsKey(routeKey)) return _viewModels[routeKey]!;
    final vm = BusMapViewModel();
    vm.selectedRoute.value = routeKey;
    vm.fetchRouteData();
    vm.fetchStationData();
    _viewModels[routeKey] = vm;
    return vm;
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
          padding: const EdgeInsets.all(20),
          itemCount: groupedRoutes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, groupIdx) {
            final group = groupedRoutes[groupIdx];
            return Card(
              color: cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus, color: Colors.blue),
                        const SizedBox(width: 5),
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
                    const SizedBox(height: 5),
                    ...List.generate(group['routes'].length, (routeIdx) {
                      final route = group['routes'][routeIdx];
                      final routeKey = route['routeKey'];
                      final label = route['label'];
                      final vm = _getViewModel(routeKey);
                      final isDownRoute = routeKey.endsWith('_DOWN');
                      return Obx(() {
                        String status = '현재 운행 없음';
                        if (vm.detailedBusPositions.isNotEmpty && vm.stationNames.isNotEmpty) {
                          final bus = vm.detailedBusPositions.first;
                          final idx = bus.nearestStationIndex;
                          if (idx >= 0 && idx < vm.stationNames.length) {
                            status = '현재 위치: 0{vm.stationNames[idx]}';
                          }
                        } else if (isDownRoute) {
                          // 실시간 버스 없고 _DOWN 노선이면 다음 출발시간 표시
                          status = allNextDepartureTimes[routeKey] ?? '로딩...';
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Get.to(() => BusMapView(initialRoute: routeKey));
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: status == '현재 운행 없음' || status == '운행 종료' ? Colors.grey : Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        );
                      });
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
