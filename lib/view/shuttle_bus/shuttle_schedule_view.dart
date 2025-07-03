import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import '../../viewmodel/shuttle_viewmodel.dart';
import 'shuttle_route_detail_view.dart';

class ShuttleScheduleView extends StatefulWidget {
  final int routeId;
  final String date;
  final String routeName;
  
  const ShuttleScheduleView({
    Key? key, 
    required this.routeId, 
    required this.date,
    required this.routeName,
  }) : super(key: key);

  @override
  _ShuttleScheduleViewState createState() => _ShuttleScheduleViewState();
}

class _ShuttleScheduleViewState extends State<ShuttleScheduleView> {
  final ShuttleViewModel viewModel = Get.find<ShuttleViewModel>();
  
  @override
  void initState() {
    super.initState();
    
    // 스케줄이 비어있는 경우 데이터 로드
    if (viewModel.schedules.isEmpty) {
      viewModel.fetchSchedules(widget.routeId, widget.date);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('운행 시간표'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 선택된 노선 정보
            _buildHeaderInfo(),
            
            SizedBox(height: 20),
            
            // 시간표 목록
            Expanded(
              child: _buildScheduleList(),
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
                color: shuttleColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '노선: ${widget.routeName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: shuttleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, 
                color: shuttleColor),
              SizedBox(width: 8),
              Text(
                // 날짜 형식 변환 (YYYY-MM-DD -> YYYY년 MM월 DD일)
                '날짜: ${_formatDate(widget.date)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: shuttleColor,
                ),
              ),
            ],
          ),
          // 요일 타입 정보 표시 (API 응답에서 가져온 경우)
          Obx(() => viewModel.scheduleTypeName.isNotEmpty 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event, 
                        color: shuttleColor),
                      SizedBox(width: 8),
                      Text(
                        '유형: ${viewModel.scheduleTypeName.value}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: shuttleColor,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : SizedBox.shrink()
          ),
          SizedBox(height: 8),
          Obx(() {
            // 첫차와 막차 시간 계산
            String firstBusTime = '정보 없음';
            String lastBusTime = '정보 없음';
            
            // 스케줄이 있는 경우 첫차/막차 정보 설정
            if (viewModel.schedules.isNotEmpty) {
              firstBusTime = DateFormat('HH:mm').format(viewModel.schedules.first.startTime);
              lastBusTime = DateFormat('HH:mm').format(viewModel.schedules.last.startTime);
            }
            
            return Row(
              children: [
                Icon(Icons.access_time, 
                  color: shuttleColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '첫차: $firstBusTime  /  막차: $lastBusTime',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: shuttleColor,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  // 날짜 형식 변환 (YYYY-MM-DD -> YYYY년 MM월 DD일)
  String _formatDate(String dateStr) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('yyyy년 MM월 dd일').format(date);
    } catch (e) {
      return dateStr;
    }
  }
  
  Widget _buildScheduleList() {
    final bool isIOS = Platform.isIOS;
    
    return Obx(() => viewModel.isLoadingSchedules.value
      ? Center(
          child: isIOS
            ? CupertinoActivityIndicator() // iOS 기본 인디케이터
            : CircularProgressIndicator() // Android 기본 인디케이터
        )
      : viewModel.schedules.isEmpty
          ? Center(child: Text('선택한 노선과 일자에 해당하는 운행 정보가 없습니다'))
          : Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),  
              child: Column(
                children: [
                  // 헤더 행
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Theme.of(context).cardColor.withOpacity(0.5)
                        : Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text('회차', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('출발 시간', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text('상세정보', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  
                  Divider(
                    height: 1, 
                    thickness: 1, 
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  
                  // 데이터 행 - 스크롤바 추가
                  Expanded(
                    child: isIOS
                      ? ListView.builder(
                          itemCount: viewModel.schedules.length,
                          itemBuilder: _buildScheduleItem,
                        )
                      : Scrollbar( // Android 기본 스크롤바
                          interactive: true,
                          thumbVisibility: true,
                          child: ListView.builder(
                            itemCount: viewModel.schedules.length,
                            itemBuilder: _buildScheduleItem,
                          ),
                        ),
                  ),
                ],
              ),
            ),
    );
  }
  
  // 스케줄 아이템 빌더 (코드 중복 제거)
  Widget _buildScheduleItem(BuildContext context, int index) {
    final schedule = viewModel.schedules[index];
    return InkWell(
      onTap: () {
        // 상세 화면으로 이동
        Get.to(() => ShuttleRouteDetailView(
          scheduleId: schedule.id,
          routeName: widget.routeName,
          round: schedule.round,
          startTime: DateFormat('HH:mm').format(schedule.startTime),
        ));
      },
      child: Container(
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
              child: Text('${schedule.round}회차'),
            ),
            Expanded(
              flex: 2,
              child: Text(DateFormat('HH:mm').format(schedule.startTime)),
            ),
            Expanded(
              flex: 1,
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
