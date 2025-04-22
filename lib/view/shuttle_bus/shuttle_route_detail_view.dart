import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../viewmodel/shuttle_viewmodel.dart';
import 'dart:io' show Platform;
import 'station_detail_view.dart'; // 정류장 상세 정보 화면 임포트
import 'naver_map_station_detail_view.dart'; // 네이버 지도 정류장 상세 정보 화면 임포트

class ShuttleRouteDetailView extends StatefulWidget {
  final int scheduleId;
  final String routeName;
  final int round;
  final String startTime;
  
  const ShuttleRouteDetailView({
    Key? key, 
    required this.scheduleId, 
    required this.routeName,
    required this.round,
    required this.startTime,
  }) : super(key: key);

  @override
  _ShuttleRouteDetailViewState createState() => _ShuttleRouteDetailViewState();
}

class _ShuttleRouteDetailViewState extends State<ShuttleRouteDetailView> {
  final ShuttleViewModel viewModel = Get.find<ShuttleViewModel>();
  
  @override
  void initState() {
    super.initState();
    // 화면이 열릴 때 정류장 정보 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchScheduleStops(widget.scheduleId).then((success) {
        if (!success) {
          // 404 에러: 해당 스케줄의 정류장 정보가 없음
          _showNoStopsAlert(context);
        }
      });
    });
  }
  
  // 404 에러 - 정류장 정보가 없음을 알리는 팝업
  void _showNoStopsAlert(BuildContext context) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('알림'),
          content: Text('해당 스케줄의 정류장 정보가 없습니다.'),
          actions: [
            CupertinoDialogAction(
              child: Text('확인'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // 이전 화면으로 돌아가기
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('알림'),
          content: Text('해당 스케줄의 정류장 정보가 없습니다.'),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // 이전 화면으로 돌아가기
              },
            ),
          ],
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('노선 상세 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 노선 정보 헤더
            _buildHeaderInfo(),
            
            SizedBox(height: 20),
            
            // 정류장 목록
            Expanded(
              child: _buildStopsList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeaderInfo() {
    // 셔틀버스 색상 - 홈 화면과 동일하게 맞춤
    final Color shuttleColor = Color(0xFFB83227);
    final brightness = Theme.of(context).brightness;
    final backgroundColor = brightness == Brightness.dark
        ? shuttleColor.withOpacity(0.2)
        : shuttleColor.withOpacity(0.1);
    final borderColor = shuttleColor.withOpacity(0.3);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus, 
                color: shuttleColor),
              SizedBox(width: 8),
              Text(
                '노선: ${widget.routeName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: shuttleColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Obx(() {
            // 정류장 정보에서 출발 시간 가져오기 (stop_order가 1인 정류장)
            String departureTime = '';
            if (viewModel.scheduleStops.isNotEmpty) {
              try {
                // stop_order가 1인 정류장 찾기
                final firstStop = viewModel.scheduleStops.firstWhere(
                  (stop) => stop.stopOrder == 1,
                  orElse: () => viewModel.scheduleStops.first,
                );
                
                // HH:MM:SS 형식을 HH:MM으로 변환
                if (firstStop.arrivalTime.length >= 5) {
                  departureTime = firstStop.arrivalTime.substring(0, 5);
                } else {
                  departureTime = firstStop.arrivalTime;
                }
              } catch (e) {
                departureTime = widget.startTime;
              }
            } else {
              departureTime = widget.startTime;
            }
            
            return Row(
              children: [
                Icon(Icons.access_time, 
                  color: shuttleColor),
                SizedBox(width: 8),
                Text(
                  widget.round > 0 
                    ? '${widget.round}회차 (출발: $departureTime)'
                    : '출발: $departureTime',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: shuttleColor,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildStopsList() {
    final bool isIOS = Platform.isIOS;
    
    return Obx(() => viewModel.isLoadingStops.value
      ? Center(
          child: isIOS
            ? CupertinoActivityIndicator() // iOS 기본 인디케이터
            : CircularProgressIndicator() // Android 기본 인디케이터
        )
      : viewModel.scheduleStops.isEmpty
          ? Center(child: Text('정류장 정보를 불러올 수 없습니다'))
          : Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '정류장 정보', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '총 ${viewModel.scheduleStops.length}개 정류장',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1, 
                    thickness: 1, 
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  // 헤더 행
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Theme.of(context).cardColor.withOpacity(0.5)
                        : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('순서', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('정류장', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('도착(경유) 시간', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  
                  // 데이터 행
                  Expanded(
                    child: Platform.isIOS
                      ? ListView.builder(
                          itemCount: viewModel.scheduleStops.length,
                          itemBuilder: _buildStopItem,
                        )
                      : Scrollbar( // Android 기본 스크롤바
                          interactive: true,
                          thumbVisibility: true,
                          child: ListView.builder(
                            itemCount: viewModel.scheduleStops.length,
                            itemBuilder: _buildStopItem,
                          ),
                        ),
                  ),
                ],
              ),
            ),
    );
  }
  
  // 정류장 아이템 빌더
  Widget _buildStopItem(BuildContext context, int index) {
    final stop = viewModel.scheduleStops[index];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '${stop.stopOrder}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () {
                // station_id 필드가 있는 경우에만 상세 화면으로 이동
                if (stop.stationId != null) { 
                  Get.to(() => NaverMapStationDetailView(stationId: stop.stationId!));
                } else {
                  _showNoStationDetailAlert(context);
                }
              },
              child: Row(
                children: [
                  Text(
                    stop.stationName,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Platform.isIOS 
                      ? CupertinoIcons.info_circle_fill 
                      : Icons.info_outline,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              stop.arrivalTime,
              style: TextStyle(
                fontWeight: stop.stopOrder == 1 
                  ? FontWeight.bold 
                  : FontWeight.normal,
                color: stop.stopOrder == 1
                  ? Theme.of(context).colorScheme.primary
                  : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 정류장 상세 정보가 없음을 알리는 팝업
  void _showNoStationDetailAlert(BuildContext context) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('정보 없음'),
          content: Text('이 정류장의 상세 정보가 없습니다.'),
          actions: [
            CupertinoDialogAction(
              child: Text('확인'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('정보 없음'),
          content: Text('이 정류장의 상세 정보가 없습니다.'),
          actions: [
            TextButton(
              child: Text('확인'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }
} 