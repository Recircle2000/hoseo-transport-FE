import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../viewmodel/shuttle_viewmodel.dart';
import 'shuttle_route_detail_view.dart';

class ShuttleScheduleView extends StatefulWidget {
  final int routeId;
  final String scheduleType;
  final String routeName;
  
  const ShuttleScheduleView({
    Key? key, 
    required this.routeId, 
    required this.scheduleType,
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
  }
  
  @override
  Widget build(BuildContext context) {
    final String scheduleTypeName = viewModel.scheduleTypeNames[widget.scheduleType] ?? widget.scheduleType;
    
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
            _buildHeaderInfo(scheduleTypeName),
            
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
  
  Widget _buildHeaderInfo(String scheduleTypeName) {
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
          Row(
            children: [
              Icon(Icons.calendar_today, 
                color: shuttleColor),
              SizedBox(width: 8),
              Text(
                '운행일: $scheduleTypeName',
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
  
  Widget _buildScheduleList() {
    final bool isIOS = !kIsWeb && Platform.isIOS;
    
    return Obx(() => viewModel.isLoadingSchedules.value
      ? Center(
          child: isIOS
            ? CupertinoActivityIndicator() // iOS 기본 인디케이터
            : CircularProgressIndicator() // Android/웹 기본 인디케이터
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
                  
                  // 데이터 행
                  Expanded(
                    child: kIsWeb || !Platform.isIOS
                      ? Scrollbar( // Android/웹 기본 스크롤바
                          interactive: true,
                          thumbVisibility: true,
                          child: ListView.separated(
                            itemCount: viewModel.schedules.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            itemBuilder: (context, index) => _buildScheduleItem(index),
                          ),
                        )
                      : ListView.separated( // iOS 리스트뷰
                          itemCount: viewModel.schedules.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          itemBuilder: (context, index) => _buildScheduleItem(index),
                        ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildScheduleItem(int index) {
    final schedule = viewModel.schedules[index];
    final bool isIOS = !kIsWeb && Platform.isIOS;
    
    return InkWell(
      onTap: () {
        // 스케줄 항목 클릭시 노선 상세 화면으로 이동
        Get.to(() => ShuttleRouteDetailView(
          scheduleId: schedule.id,
          routeName: widget.routeName,
          round: schedule.round,
          startTime: DateFormat('HH:mm').format(schedule.startTime),
        ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                '${schedule.round}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('HH:mm').format(schedule.startTime),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Icon(
                isIOS
                  ? CupertinoIcons.chevron_right
                  : Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 