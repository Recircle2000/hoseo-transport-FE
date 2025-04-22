import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import '../../viewmodel/nearby_stops_viewmodel.dart';
import '../../models/shuttle_models.dart';

class NearbyStopsView extends StatelessWidget {
  // 셔틀버스 색상 - 홈 화면과 동일하게 맞춤
  final Color shuttleColor = Color(0xFFB83227);
  final NearbyStopsViewModel viewModel = Get.put(NearbyStopsViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('가까운 정류장 찾기'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationHeader(context),
              SizedBox(height: 16),
              _buildStationSelector(context),
              SizedBox(height: 16),
              _buildScheduleTypeSelector(context),
              SizedBox(height: 8),
              _buildScheduleHeader(context),
              SizedBox(height: 8),
              Expanded(
                child: _buildScheduleTable(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader(BuildContext context) {
    return Obx(() {
      final isLoading = viewModel.isLoadingLocation.value;
      final hasLocation = viewModel.currentPosition.value != null;
      
      return Card(
        elevation: 2,
        child: Container(
          padding: EdgeInsets.all(16),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                  SizedBox(width: 8),
              Text(
                    '내 위치에서 가까운 정류장',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (isLoading)
                Center(
                  child: Column(
                    children: [
                      Platform.isIOS
                        ? CupertinoActivityIndicator()
                        : CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('위치 정보를 가져오는 중입니다...'),
                    ],
                  ),
                )
              else if (!hasLocation)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildGetLocationButton(context),
                    SizedBox(height: 8),
                    Text(
                      '위치 권한을 허용하면 가까운 정류장을 자동으로 찾아줍니다',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Text(
                      '현재 위치를 기준으로 정류장이 정렬됩니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => viewModel.getCurrentLocation(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '위치 새로고침',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
        ),
      ),
    );
    });
  }

  Widget _buildGetLocationButton(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: Colors.green.shade700,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.location, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text('현재 위치 확인하기'),
          ],
        ),
        onPressed: () => viewModel.getCurrentLocation(),
      );
    } else {
      return ElevatedButton.icon(
        icon: Icon(Icons.my_location, size: 18),
        label: Text('현재 위치 확인하기'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        onPressed: () => viewModel.getCurrentLocation(),
      );
    }
  }

  Widget _buildStationSelector(BuildContext context) {
    return Obx(() {
      final isLoading = viewModel.isLoadingStations.value;
      final hasLocation = viewModel.currentPosition.value != null;
      final stations = hasLocation 
          ? viewModel.sortedStations 
          : viewModel.stations;
      
      if (isLoading) {
        return Center(
          child: Platform.isIOS
            ? CupertinoActivityIndicator()
            : CircularProgressIndicator(),
        );
      }
      
      if (stations.isEmpty) {
        return Center(
          child: Text('정류장 정보를 불러올 수 없습니다.'),
        );
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '정류장 선택',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: viewModel.selectedStationId.value != -1
                    ? viewModel.selectedStationId.value
                    : stations.first.id,
                isExpanded: true,
                padding: EdgeInsets.symmetric(horizontal: 12),
                borderRadius: BorderRadius.circular(8),
                items: stations.map((station) {
                  final hasDistance = hasLocation && viewModel.currentPosition.value != null;
                  final distance = hasDistance
                      ? viewModel.getDistanceToStation(station)
                      : null;
                  
                  return DropdownMenuItem<int>(
                    value: station.id,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasDistance)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: Text(
                              distance!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    viewModel.fetchStationSchedules(value);
                  }
                },
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildScheduleTypeSelector(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selectedColor = brightness == Brightness.dark 
        ? Colors.green.shade700.withOpacity(0.3) 
        : Colors.green.shade50;
    final borderColor = Colors.green.shade700;
    
    return Obx(() {
      final selectedType = viewModel.selectedScheduleType.value;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '운행 일자',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: viewModel.scheduleTypes.map((type) {
                final isSelected = type == selectedType;
                final typeName = viewModel.scheduleTypeNames[type] ?? type;
                
                return GestureDetector(
                  onTap: () => viewModel.filterSchedulesByType(type),
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? borderColor : Colors.grey.shade400,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      typeName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? borderColor : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildScheduleHeader(BuildContext context) {
    return Obx(() {
      final selectedId = viewModel.selectedStationId.value;
      final stationName = selectedId != -1
          ? viewModel.getStationName(selectedId)
          : '';
      final scheduleTypeName = viewModel.scheduleTypeNames[viewModel.selectedScheduleType.value] ?? '전체';
      
      return Row(
        children: [
          Icon(
            Icons.schedule,
            color: shuttleColor,
            size: 22,
          ),
          SizedBox(width: 8),
          Text(
            '정류장 시간표 ($scheduleTypeName)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: shuttleColor,
            ),
          ),
          Spacer(),
          if (stationName.isNotEmpty)
            Text(
              stationName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      );
    });
  }
  
  Widget _buildScheduleTable(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final headerBgColor = brightness == Brightness.dark 
        ? Colors.grey.shade800 
        : Colors.grey.shade200;
    
    return Obx(() {
      if (viewModel.isLoadingSchedules.value) {
        return Center(
          child: Platform.isIOS
            ? CupertinoActivityIndicator()
            : CircularProgressIndicator(),
        );
      }
      
      if (viewModel.filteredSchedules.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 48,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16),
              Text(
                '선택한 정류장의 ${viewModel.scheduleTypeNames[viewModel.selectedScheduleType.value]} 시간표가 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // 다른 일정 유형 표시
                  final types = viewModel.scheduleTypes;
                  final currentIndex = types.indexOf(viewModel.selectedScheduleType.value);
                  final nextIndex = (currentIndex + 1) % types.length;
                  viewModel.filterSchedulesByType(types[nextIndex]);
                },
                child: Text('다른 요일 시간표 보기'),
              ),
            ],
          ),
        );
      }
      
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // 테이블 헤더
            Container(
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text('번호', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('노선', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('도착 시간', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            
            // 테이블 내용
            Expanded(
              child: Platform.isIOS
                ? _buildIosScheduleList()
                : _buildAndroidScheduleList(),
            ),
          ],
        ),
      );
    });
  }
  
  Widget _buildIosScheduleList() {
    return ListView.separated(
      itemCount: viewModel.filteredSchedules.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final schedule = viewModel.filteredSchedules[index];
        final routeName = viewModel.getRouteName(schedule.routeId);
        
        return Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Text('${index + 1}'),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  routeName,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  _formatTime(schedule.arrivalTime),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: shuttleColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAndroidScheduleList() {
    return Scrollbar(
      interactive: true,
      thumbVisibility: true,
      child: ListView.separated(
        itemCount: viewModel.filteredSchedules.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final schedule = viewModel.filteredSchedules[index];
          final routeName = viewModel.getRouteName(schedule.routeId);
          
          return Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text('${index + 1}'),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    routeName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatTime(schedule.arrivalTime),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: shuttleColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // "HH:MM:SS" 형식의 시간을 "HH:MM" 형식으로 변환
  String _formatTime(String timeString) {
    if (timeString.length >= 5) {
      return timeString.substring(0, 5);
    }
    return timeString;
  }
} 