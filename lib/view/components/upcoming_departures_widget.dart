import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'dart:io' show Platform;
import '../../viewmodel/upcoming_departure_viewmodel.dart';
import '../shuttle_bus/shuttle_route_detail_view.dart';
import '../../viewmodel/shuttle_viewmodel.dart';
import '../city_bus/bus_map_view.dart';

class UpcomingDeparturesWidget extends StatefulWidget {
  UpcomingDeparturesWidget({Key? key}) : super(key: key);

  @override
  _UpcomingDeparturesWidgetState createState() => _UpcomingDeparturesWidgetState();
}

class _UpcomingDeparturesWidgetState extends State<UpcomingDeparturesWidget> with RouteAware {
  final UpcomingDepartureViewModel viewModel = Get.put(UpcomingDepartureViewModel());
  int _remainingSeconds = 30; // 자동 새로고침까지 남은 시간(초)
  Timer? _refreshCountdownTimer;

  final RouteObserver<PageRoute> _routeObserver = Get.find<RouteObserver<PageRoute>>();

  @override
  void initState() {
    super.initState();

    // 뷰모델의 새로고침 콜백 등록
    viewModel.setRefreshCallback(() {
      // 뷰모델에서 새로고침이 발생할 때 카운트다운 초기화
      _startRefreshCountdown();
    });

    // 초기 타이머 시작
    _startRefreshCountdown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 라우트 옵저버에 등록
    _routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void didPush() {
    // 새 페이지가 이 위젯으로 푸시될 때 (진입할 때)
    viewModel.setHomePageState(true);
    _resetTimerDisplay();
    super.didPush();
  }

  @override
  void didPopNext() {
    // 이 페이지가 최상위로 올라왔을 때 (다른 페이지에서 돌아왔을 때)
    viewModel.setHomePageState(true);
    _resetTimerDisplay();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    // 이 페이지 위에 새 페이지가 푸시될 때 (다른 페이지로 이동할 때)
    viewModel.setHomePageState(false);
    super.didPushNext();
  }

  @override
  void didPop() {
    // 이 페이지가 스택에서 제거될 때 (뒤로가기 등)
    viewModel.setHomePageState(false);
    super.didPop();
  }

  @override
  void dispose() {
    _refreshCountdownTimer?.cancel();
    // 라우트 옵저버에서 구독 해제
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _startRefreshCountdown() {
    // 기존 타이머 취소
    _refreshCountdownTimer?.cancel();

    // 초기값 설정
    _remainingSeconds = 30;

    // 1초마다 카운트다운
    _refreshCountdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          // 카운트다운 종료 시 다시 시작
          _remainingSeconds = 30;
          // 타이머 초기화와 동시에 수행되는 자동 새로고침
          // 뷰모델의 타이머가 자동으로 새로고침을 실행하므로 여기서는 호출하지 않음
        }
      });
    });
  }

  // 수동 새로고침 시 카운트다운도 리셋
  void _manualRefresh() {
    // 햅틱 피드백 추가
    HapticFeedback.lightImpact();
    viewModel.loadData();
    _startRefreshCountdown();
  }

  // 타이머 디스플레이를 리셋하는 메소드
  void _resetTimerDisplay() {
    setState(() {
      _remainingSeconds = 30;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.timer, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '곧 출발',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Obx(() => Text(
                  '${viewModel.settingsViewModel.selectedCampus.value == '천안' ? '기점에서 출발 기준. 천캠 도착 까지\n81번: 약 2분, 24번: 약 5분 추가 소요' : '아캠 출발 기준'} ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                )),
              ),
              const SizedBox(width: 8),
              Text(
                '${_remainingSeconds}초',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _manualRefresh,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(
                      Icons.refresh,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 로딩 상태에 따른 표시
          Obx(() {
            if (viewModel.isLoading.value) {
              return Container(
                //height: 200, // 로딩 상태에서의 고정된 높이
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Platform.isIOS
                    ? CupertinoActivityIndicator(
                        radius: 12,
                      )
                    : CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                ),
              );
            }

            if (viewModel.error.isNotEmpty) {
              return Container(
                //height: 210, // 에러 상태에서의 고정된 높이
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    viewModel.error.value,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // 셔틀과 시내버스 데이터 모두 없는 경우
            if (viewModel.upcomingShuttles.isEmpty && viewModel.upcomingCityBuses.isEmpty) {
              return Container(
                height: 190, // 데이터 없음 상태에서의 고정된 높이
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '90분 내에 출발 예정인 버스/셔틀이 없습니다',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            // 기본 데이터가 있는 경우는 고정된 컨테이너로 감싸기
            return Container(
              //height: 210, // 데이터 표시 상태에서의 고정된 높이
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 셔틀버스 (왼쪽)
                  Expanded(
                    child: Container(
                      //height: 210,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 추가
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, '셔틀버스'),
                          viewModel.upcomingShuttles.isEmpty
                            ? _buildEmptyMessage(context, '셔틀')
                            : Column(
                                children: viewModel.upcomingShuttles
                                  .take(3) // 최대 2개만 표시
                                  .map((shuttle) => _buildCompactShuttleItem(
                                    context,
                                    shuttle,
                                    Colors.deepOrange,
                                    Icons.airport_shuttle,
                                  )).toList(),
                              ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 10),

                  // 시내버스 (오른쪽)
                  Expanded(
                    child: Container(
                     // height: 210,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 추가
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, '시내버스'),
                          viewModel.upcomingCityBuses.isEmpty
                            ? _buildEmptyMessage(context, '버스')
                            : Column(
                                children: viewModel.upcomingCityBuses
                                  .take(3) // 최대 2개만 표시
                                  .map((cityBus) => _buildCompactBusItem(
                                    context,
                                    cityBus,
                                    Colors.blue,
                                    Icons.directions_bus,
                                  )).toList(),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(BuildContext context, String type) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          '90분 내 출발 $type 없음',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 2),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // 셔틀버스용 아이템 (노선명만 표시)
  Widget _buildCompactShuttleItem(
    BuildContext context,
    BusDeparture departure,
    Color color,
    IconData icon,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          child: InkWell(
            onTap: () {
              // 셔틀버스 클릭 시 상세 페이지로 이동
              HapticFeedback.mediumImpact(); // 햅틱 피드백
              
              // 해당 셔틀의 scheduleId가 있는 경우에만 이동
              if (departure.scheduleId != null) {
                // ShuttleViewModel이 없는 경우 초기화 (Get.find 오류 방지)
                if (!Get.isRegistered<ShuttleViewModel>()) {
                  Get.put(ShuttleViewModel());
                }
                
                // 셔틀 상세 화면으로 이동
                Get.to(() => ShuttleRouteDetailView(
                  scheduleId: departure.scheduleId!, // 각 셔틀의 scheduleId 사용
                  routeName: departure.destination, // 노선명 전달
                  round: 0, // 기본값으로 0 (0으로 설정시 표시되지 않음)
                  startTime: '${departure.departureTime.hour.toString().padLeft(2, '0')}:${departure.departureTime.minute.toString().padLeft(2, '0')}', // 출발 시간 전달
                ));
              } else {
                // scheduleId가 없는 경우 스낵바 표시
                Get.snackbar(
                  '정보 없음',
                  '해당 셔틀의 상세 정보를 불러올 수 없습니다.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  colorText: Colors.red,
                  duration: Duration(seconds: 2),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoScrollText(
                          text: departure.destination,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${departure.departureTime.hour.toString().padLeft(2, '0')}:${departure.departureTime.minute.toString().padLeft(2, '0')} 출발',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTimeColor(departure.minutesLeft).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${departure.minutesLeft}분',
                      style: TextStyle(
                        color: _getTimeColor(departure.minutesLeft),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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

  // 시내버스용 아이템 (노선명 → 목적지 표시)
  Widget _buildCompactBusItem(
    BuildContext context,
    BusDeparture departure,
    Color color,
    IconData icon,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          child: InkWell(
            onTap: () {
              // 시내버스 클릭 시 햅틱 피드백 제공
              HapticFeedback.mediumImpact();
              
              // BusMapView로 이동 (클릭한 노선 정보와 목적지 전달)
              Get.to(() => BusMapView(
                initialRoute: departure.routeName,
                initialDestination: departure.destination,
              ));
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 자동 롤링 텍스트
                        AutoScrollText(
                          text: '${departure.routeName} → ${departure.destination}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${departure.departureTime.hour.toString().padLeft(2, '0')}:${departure.departureTime.minute.toString().padLeft(2, '0')} 출발',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTimeColor(departure.minutesLeft).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${departure.minutesLeft}분',
                      style: TextStyle(
                        color: _getTimeColor(departure.minutesLeft),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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

  Color _getTimeColor(int minutes) {
    if (minutes <= 5) {
      return Colors.red;
    } else if (minutes <= 15) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}

// 자동 스크롤 텍스트 위젯
class AutoScrollText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double height;
  final Duration pauseDuration;
  final Duration scrollDuration;

  AutoScrollText({
    required this.text,
    required this.style,
    this.height = 20,
    this.pauseDuration = const Duration(seconds: 1),
    this.scrollDuration = const Duration(seconds: 2),
  });

  @override
  _AutoScrollTextState createState() => _AutoScrollTextState();
}

class _AutoScrollTextState extends State<AutoScrollText> {
  late ScrollController _scrollController;
  Timer? _timer;
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    // 스크롤할 필요가 없는 경우는 타이머 설정 안함
    if (!_hasOverflow()) {
      return;
    }

    // 일정 시간 후에 스크롤 시작
    _timer = Timer(widget.pauseDuration, () {
      if (_scrollController.hasClients && mounted) {
        setState(() {
          _isScrolling = true;
        });

        // 오른쪽 끝까지 스크롤
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: widget.scrollDuration,
          curve: Curves.easeInOut,
        ).then((_) {
          // 스크롤이 끝나면 다시 처음으로 돌아가기 전에 잠시 멈춤
          if (mounted) {
            setState(() {
              _isScrolling = false;
            });

            _timer = Timer(widget.pauseDuration, () {
              if (_scrollController.hasClients && mounted) {
                // 처음으로 돌아가기
                _scrollController.animateTo(
                  0,
                  duration: Duration(milliseconds: 1),
                  curve: Curves.easeInOut,
                ).then((_) {
                  if (mounted) {
                    // 다시 시작
                    _startScrolling();
                  }
                });
              }
            });
          }
        });
      }
    });
  }

  bool _hasOverflow() {
    if (!_scrollController.hasClients) {
      return false;
    }
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    return maxScrollExtent > 0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        physics: NeverScrollableScrollPhysics(), // 사용자 스크롤 비활성화
        child: Text(
          widget.text,
          style: widget.style,
        ),
      ),
    );
  }
}
