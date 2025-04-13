import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../viewmodel/shuttle_viewmodel.dart';
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus, 
                color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text(
                '노선: ${widget.routeName}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, 
                color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text(
                '운행일: $scheduleTypeName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildScheduleList() {
    return Obx(() => viewModel.isLoadingSchedules.value
      ? Center(child: CircularProgressIndicator())
      : viewModel.schedules.isEmpty
          ? Center(child: Text('선택한 노선과 일자에 해당하는 운행 정보가 없습니다'))
          : Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
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
                  
                  // 데이터 행
                  Expanded(
                    child: ListView.builder(
                      itemCount: viewModel.schedules.length,
                      itemBuilder: (context, index) {
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
                                bottom: BorderSide(color: Theme.of(context).dividerColor),
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
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 