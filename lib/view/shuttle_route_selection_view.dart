import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import '../viewmodel/shuttle_viewmodel.dart';
import '../models/shuttle_models.dart';
import 'shuttle_schedule_view.dart'; // 시간표 화면 임포트

class ShuttleRouteSelectionView extends StatelessWidget {
  final ShuttleViewModel viewModel = Get.put(ShuttleViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('셔틀버스 노선 선택'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectionArea(context),
            
            SizedBox(height: 40),
            
            // 검색 버튼
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  // 노선과 운행일자가 모두 선택되었는지 확인
                  if (viewModel.selectedRouteId.value == -1) {
                    Get.snackbar(
                      '알림',
                      '노선을 선택해주세요',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  
                  if (viewModel.selectedScheduleType.value.isEmpty) {
                    Get.snackbar(
                      '알림',
                      '운행 일자를 선택해주세요',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  
                  // 조회 버튼을 누를 때만 API를 호출하도록 변경
                  viewModel.fetchSchedules(
                    viewModel.selectedRouteId.value, 
                    viewModel.selectedScheduleType.value
                  ).then((_) {
                    // API 호출이 완료된 후 화면 이동
                    Get.to(() => ShuttleScheduleView(
                      routeId: viewModel.selectedRouteId.value,
                      scheduleType: viewModel.selectedScheduleType.value,
                      routeName: _getSelectedRouteName(),
                    ));
                  });
                },
                child: Text('시간표 조회'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 선택된 노선 이름 가져오기
  String _getSelectedRouteName() {
    if (viewModel.selectedRouteId.value != -1) {
      final route = viewModel.routes.firstWhere(
        (route) => route.id == viewModel.selectedRouteId.value,
        orElse: () => ShuttleRoute(id: -1, routeName: '알 수 없음', direction: ''),
      );
      return '${route.routeName} (${route.direction})';
    }
    return '';
  }

  Widget _buildSelectionArea(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('셔틀버스 노선 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        Obx(() => viewModel.isLoadingRoutes.value
          ? Center(child: CircularProgressIndicator())
          : viewModel.routes.isEmpty
              ? Text('사용 가능한 노선이 없습니다')
              : _buildRouteSelector(context),
        ),
        
        SizedBox(height: 25),
        
        Text('운행 일자 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 8),
        _buildScheduleTypeSelector(context),
      ],
    );
  }

  Widget _buildRouteSelector(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSRouteSelector(context);
    } else {
      return _buildAndroidRouteSelector();
    }
  }

  Widget _buildIOSRouteSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showIOSRoutePicker(context),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                if (viewModel.selectedRouteId.value == -1) {
                  return Text('노선을 선택하세요', 
                    style: TextStyle(color: Theme.of(context).hintColor));
                } else {
                  final selectedRoute = viewModel.routes.firstWhere(
                    (route) => route.id == viewModel.selectedRouteId.value,
                    orElse: () => ShuttleRoute(id: -1, routeName: '알 수 없음', direction: ''),
                  );
                  return Text('${selectedRoute.routeName} (${selectedRoute.direction})');
                }
              }),
              Icon(Icons.arrow_drop_down, color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }

  void _showIOSRoutePicker(BuildContext context) {
    int selectedIndex = 0;
    
    // 현재 선택된 노선의 인덱스 찾기
    if (viewModel.selectedRouteId.value != -1) {
      final index = viewModel.routes.indexWhere((route) => route.id == viewModel.selectedRouteId.value);
      if (index != -1) {
        selectedIndex = index;
      }
    }
    
    // 노선이 없는 경우 처리
    if (viewModel.routes.isEmpty) {
      Get.snackbar(
        '알림', 
        '사용 가능한 노선이 없습니다',
        snackPosition: SnackPosition.BOTTOM
      );
      return;
    }
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 50,
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('취소'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text('확인'),
                    onPressed: () {
                      if (viewModel.routes.isNotEmpty) {
                        viewModel.selectRoute(viewModel.routes[selectedIndex].id);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                onSelectedItemChanged: (int index) {
                  selectedIndex = index;
                },
                children: viewModel.routes.map((route) {
                  return Center(
                    child: Text(
                      '${route.routeName} (${route.direction})',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidRouteSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(Get.context!).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        return DropdownButton<int>(
          value: viewModel.selectedRouteId.value != -1 ? viewModel.selectedRouteId.value : null,
          hint: Text('노선을 선택하세요'),
          isExpanded: true,
          underline: SizedBox(), // 밑줄 제거
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(Get.context!).hintColor),
          onChanged: (int? value) {
            if (value != null) {
              viewModel.selectRoute(value);
            }
          },
          items: viewModel.routes.map<DropdownMenuItem<int>>((route) {
            return DropdownMenuItem<int>(
              value: route.id,
              child: Text('${route.routeName} (${route.direction})'),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildScheduleTypeSelector(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSScheduleTypeSelector(context);
    } else {
      return _buildAndroidScheduleTypeSelector();
    }
  }

  Widget _buildIOSScheduleTypeSelector(BuildContext context) {
    return GestureDetector(
      onTap: () => _showIOSScheduleTypePicker(context),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() {
                if (viewModel.selectedScheduleType.value.isEmpty) {
                  return Text('운행 일자를 선택하세요', 
                    style: TextStyle(color: Theme.of(context).hintColor));
                } else {
                  return Text(viewModel.scheduleTypeNames[viewModel.selectedScheduleType.value] ?? '');
                }
              }),
              Icon(Icons.arrow_drop_down, color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }

  void _showIOSScheduleTypePicker(BuildContext context) {
    int selectedIndex = 0;
    
    // 현재 선택된 운행 일자의 인덱스 찾기
    if (viewModel.selectedScheduleType.value.isNotEmpty) {
      final index = viewModel.scheduleTypes.indexOf(viewModel.selectedScheduleType.value);
      if (index != -1) {
        selectedIndex = index;
      }
    }
    
    // 스케줄 타입이 비어있는 경우 처리
    if (viewModel.scheduleTypes.isEmpty) {
      Get.snackbar(
        '알림', 
        '운행 일자 정보를 불러올 수 없습니다',
        snackPosition: SnackPosition.BOTTOM
      );
      return;
    }
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Container(
              height: 50,
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('취소'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: Text('확인'),
                    onPressed: () {
                      if (viewModel.scheduleTypes.isNotEmpty) {
                        viewModel.selectScheduleType(viewModel.scheduleTypes[selectedIndex]);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(initialItem: selectedIndex),
                onSelectedItemChanged: (int index) {
                  selectedIndex = index;
                },
                children: viewModel.scheduleTypes.map((type) {
                  return Center(
                    child: Text(
                      viewModel.scheduleTypeNames[type] ?? type,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidScheduleTypeSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(Get.context!).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        return DropdownButton<String>(
          value: viewModel.selectedScheduleType.value.isNotEmpty ? viewModel.selectedScheduleType.value : null,
          hint: Text('운행 일자를 선택하세요'),
          isExpanded: true,
          underline: SizedBox(), // 밑줄 제거
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(Get.context!).hintColor),
          onChanged: (String? value) {
            if (value != null) {
              viewModel.selectScheduleType(value);
            }
          },
          items: viewModel.scheduleTypes.map<DropdownMenuItem<String>>((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(viewModel.scheduleTypeNames[type] ?? type),
            );
          }).toList(),
        );
      }),
    );
  }
} 