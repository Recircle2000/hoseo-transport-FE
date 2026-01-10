import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import '../../viewmodel/shuttle_viewmodel.dart';
import '../../models/shuttle_models.dart';
import 'shuttle_schedule_view.dart'; // 시간표 화면 임포트
import 'package:intl/intl.dart';
import 'nearby_stops_view.dart'; // 가까운 정류장 찾기 화면 임포트

class ShuttleRouteSelectionView extends StatelessWidget {
  final ShuttleViewModel viewModel = Get.put(ShuttleViewModel());
  // 셔틀버스 색상 - 홈 화면과 동일하게 맞춤
  final Color shuttleColor = Color(0xFFB83227);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('셔틀버스 노선 선택'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSelectionArea(context),
                
                SizedBox(height: 32),
                
                // 검색 버튼
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      backgroundColor: shuttleColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // 노선과 운행일자가 모두 선택되었는지 확인
                      if (viewModel.selectedRouteId.value == -1) {
                        Get.snackbar(
                          '알림',
                          '노선을 선택해주세요',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      
                      if (viewModel.selectedDate.value.isEmpty) {
                        Get.snackbar(
                          '알림',
                          '운행 날짜를 선택해주세요',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      
                      try {
                        // 날짜 포맷 변환 및 요일 가져오기
                        final date = DateFormat('yyyy-MM-dd').parse(viewModel.selectedDate.value);
                        final dayOfWeek = _getDayOfWeekString(date);
                        
                        // 조회 버튼을 누를 때만 API를 호출하도록 변경
                        viewModel.fetchSchedules(
                          viewModel.selectedRouteId.value, 
                          viewModel.selectedDate.value
                        ).then((success) {
                          if (!success) {
                            // 404 에러: 해당 날짜에 운행하는 셔틀 노선이 없음
                            _showNoScheduleAlert(context);
                          } else {
                            // API 호출 성공 또는 더미 데이터로 대체된 경우
                            Get.to(() => ShuttleScheduleView(
                              routeId: viewModel.selectedRouteId.value,
                              date: viewModel.selectedDate.value,
                              routeName: _getSelectedRouteName(),
                            ));
                          }
                        });
                      } catch (e) {
                        print('날짜 포맷 변환 오류: $e');
                        // 에러가 발생해도 기본 API 호출은 계속 진행
                        viewModel.fetchSchedules(
                          viewModel.selectedRouteId.value, 
                          viewModel.selectedDate.value
                        ).then((success) {
                          if (!success) {
                            _showNoScheduleAlert(context);
                          } else {
                            Get.to(() => ShuttleScheduleView(
                              routeId: viewModel.selectedRouteId.value,
                              date: viewModel.selectedDate.value,
                              routeName: _getSelectedRouteName(),
                            ));
                          }
                        });
                      }
                    },
                    child: Text('시간표 조회'),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // 구분선 추가
                Divider(
                  color: shuttleColor.withOpacity(0.3),
                  thickness: 1.5,
                ),
                
                SizedBox(height: 24),
                
                // 가까운 정류장 찾기 버튼
                Center(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.location_on),
                        label: Text('정류장별 도착 시간표'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Get.to(() => NearbyStopsView());
                        },
                      ),
                      SizedBox(height: 8),
                      Text(
                        '(주변 정류장 검색)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      return '${route.routeName}';
    }
    return '';
  }

  Widget _buildSelectionArea(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 현재 운행 상태 정보 카드 추가
        _buildCurrentTimeInfo(context),
        
        SizedBox(height: 24),
        
        Text('셔틀버스 노선 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 12),
        
        // 로딩 인디케이터를 플랫폼별로 표시
        Obx(() => viewModel.isLoadingRoutes.value
          ? Center(child: _buildPlatformLoadingIndicator())
          : viewModel.routes.isEmpty
              ? Text('사용 가능한 노선이 없습니다')
              : _buildRouteSelector(context),
        ),
        
        SizedBox(height: 20),
        _buildScheduleTypeSelector(context),
      ],
    );
  }

  // 플랫폼별 로딩 인디케이터
  Widget _buildPlatformLoadingIndicator() {
    return CircularProgressIndicator.adaptive(
      valueColor: AlwaysStoppedAnimation<Color>(shuttleColor),
    );
  }

  // 현재 시간 정보 및 도움말 카드
  Widget _buildCurrentTimeInfo(BuildContext context) {
    final now = DateTime.now();
    final dayOfWeek = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'][now.weekday - 1];
    final timeString = DateFormat('HH:mm').format(now);
    
    final brightness = Theme.of(context).brightness;
    final backgroundColor = brightness == Brightness.dark
        ? shuttleColor.withOpacity(0.2)
        : shuttleColor.withOpacity(0.1);
    final borderColor = shuttleColor.withOpacity(0.3);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.1),
        //     blurRadius: 0,
        //     offset: const Offset(0, 0),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: shuttleColor),
              SizedBox(width: 8),
              Text(
                '현재 시간: $timeString',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: brightness == Brightness.dark ? Colors.redAccent : shuttleColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, color: shuttleColor),
              SizedBox(width: 8),
              Text(
                '오늘:  ${DateFormat('yyyy년 MM월 dd일').format(now)} ($dayOfWeek)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: brightness == Brightness.dark ? Colors.redAccent : shuttleColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '아래에서 노선과 운행 날짜를 선택하여 셔틀버스 시간표를 확인하세요.',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
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
    // 셔틀버스 색상으로 통일
    final Color shuttleColor = Color(0xFFB83227);
    
    return GestureDetector(
      onTap: () => _showIOSRoutePicker(context),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          // border: Border.all(color: Theme.of(context).dividerColor),
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 0),
            ),
          ],
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
                  return Text('${selectedRoute.routeName}');
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
                      '${route.routeName}',
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
    // 셔틀버스 색상으로 통일
    final Color shuttleColor = Color(0xFFB83227);
    
    return Container(
      height: 50,
      decoration: BoxDecoration(
        // border: Border.all(color: Theme.of(Get.context!).dividerColor),
        color: Theme.of(Get.context!).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 0),
          ),
        ],
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
              child: Text('${route.routeName}'),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildScheduleTypeSelector(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSDateSelector(context);
    } else {
      return _buildAndroidDateSelector(context);
    }
  }

  Widget _buildIOSDateSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운행 날짜 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showIOSDatePicker(context),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              // border: Border.all(color: Theme.of(context).dividerColor),
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    if (viewModel.selectedDate.value.isEmpty) {
                      return Text('운행 날짜를 선택하세요', 
                        style: TextStyle(color: Theme.of(context).hintColor));
                    } else {
                      // 날짜 형식 변환 (YYYY-MM-DD -> YYYY년 MM월 DD일)
                      final dateStr = viewModel.selectedDate.value;
                      try {
                        final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                        return Text('${DateFormat('yyyy년 MM월 dd일').format(date)} (${_getDayOfWeekString(date)})');
                      } catch (e) {
                        return Text(dateStr);
                      }
                    }
                  }),
                  Icon(Icons.calendar_today, color: Theme.of(context).hintColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showIOSDatePicker(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    
    // 현재 선택된 날짜가 있으면 해당 날짜로 초기화
    if (viewModel.selectedDate.value.isNotEmpty) {
      try {
        selectedDate = DateFormat('yyyy-MM-dd').parse(viewModel.selectedDate.value);
      } catch (e) {
        print('날짜 파싱 오류: $e');
      }
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
                      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                      viewModel.selectDate(formattedDate);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: selectedDate,
                onDateTimeChanged: (DateTime date) {
                  selectedDate = date;
                },
                minimumYear: DateTime.now().year - 1,
                maximumYear: DateTime.now().year + 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidDateSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '운행 날짜 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          height: 50,
          decoration: BoxDecoration(
            // border: Border.all(color: Theme.of(context).dividerColor),
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            onTap: () => _showAndroidDatePicker(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() {
                  if (viewModel.selectedDate.value.isEmpty) {
                    return Text('운행 날짜를 선택하세요', style: TextStyle(color: Theme.of(context).hintColor));
                  } else {
                    // 날짜 형식 변환 (YYYY-MM-DD -> YYYY년 MM월 DD일)
                    final dateStr = viewModel.selectedDate.value;
                    try {
                      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
                      return Text('${DateFormat('yyyy년 MM월 dd일').format(date)} (${_getDayOfWeekString(date)})');
                    } catch (e) {
                      return Text(dateStr);
                    }
                  }
                }),
                Icon(Icons.calendar_today, color: Theme.of(context).hintColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAndroidDatePicker(BuildContext context) async {
    DateTime selectedDate = DateTime.now();
    
    // 현재 선택된 날짜가 있으면 해당 날짜로 초기화
    if (viewModel.selectedDate.value.isNotEmpty) {
      try {
        selectedDate = DateFormat('yyyy-MM-dd').parse(viewModel.selectedDate.value);
      } catch (e) {
        print('날짜 파싱 오류: $e');
      }
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: shuttleColor, // 셔틀버스 테마 색상
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      viewModel.selectDate(formattedDate);
    }
  }

  // 요일 이름 가져오기
  String _getDayOfWeekString(DateTime date) {
    final dayOfWeek = date.weekday;
    switch (dayOfWeek) {
      case 1: return '월';
      case 2: return '화';
      case 3: return '수';
      case 4: return '목';
      case 5: return '금';
      case 6: return '토';
      case 7: return '일';
      default: return '';
    }
  }

  // 404 에러 - 해당 날짜에 운행하는 셔틀 노선이 없음을 알리는 팝업
  void _showNoScheduleAlert(BuildContext context) {
    try {
      final date = DateFormat('yyyy-MM-dd').parse(viewModel.selectedDate.value);
      final formattedDate = '${DateFormat('yyyy년 MM월 dd일').format(date)} (${_getDayOfWeekString(date)})';
      final routeName = _getSelectedRouteName();
      
      final message = '$formattedDate에\n$routeName 노선의 운행 정보가 없습니다.';
      
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('운행 정보 없음'),
            content: Text(message),
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
            title: Text('운행 정보 없음'),
            content: Text(message),
            actions: [
              TextButton(
                child: Text('확인'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 날짜 형식 변환 오류 시 기본 메시지 표시
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text('알림'),
            content: Text('해당 날짜에 운행하는 셔틀노선이 없습니다.'),
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
            title: Text('알림'),
            content: Text('해당 날짜에 운행하는 셔틀노선이 없습니다.'),
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
} 