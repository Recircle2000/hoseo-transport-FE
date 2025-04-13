import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/shuttle_viewmodel.dart';

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
      viewModel.fetchScheduleStops(widget.scheduleId);
    });
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
              Icon(Icons.access_time, 
                color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text(
                '${widget.round}회차 (출발: ${widget.startTime})',
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
  
  Widget _buildStopsList() {
    return Obx(() => viewModel.isLoadingStops.value
      ? Center(child: CircularProgressIndicator())
      : viewModel.scheduleStops.isEmpty
          ? Center(child: Text('정류장 정보를 불러올 수 없습니다'))
          : Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
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
                  Divider(height: 1),
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
                          child: Text('도착 시간', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  
                  // 데이터 행
                  Expanded(
                    child: ListView.builder(
                      itemCount: viewModel.scheduleStops.length,
                      itemBuilder: (context, index) {
                        final stop = viewModel.scheduleStops[index];
                        return Container(
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
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${stop.stopOrder}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  stop.stationName,
                                  style: TextStyle(fontWeight: FontWeight.w500),
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
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 