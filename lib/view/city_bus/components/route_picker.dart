import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../viewmodel/busmap_viewmodel.dart';

/// 시내버스 노선 선택 위젯
/// iOS와 Android에 맞는 UI 제공
class RoutePicker extends StatelessWidget {
  final Map<String, String> routeDisplayNames;
  final Function(String) onRouteSelected;
  
  const RoutePicker({
    Key? key, 
    required this.routeDisplayNames,
    required this.onRouteSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BusMapViewModel>();
    
    return Obx(() {
      if (Platform.isIOS) {
        return _buildIOSPicker(context, controller);
      } else {
        return _buildAndroidPicker(context, controller);
      }
    });
  }
  
  /// iOS용 피커 위젯 구현
  Widget _buildIOSPicker(BuildContext context, BusMapViewModel controller) {
    return GestureDetector(
      onTap: () => _showCupertinoPicker(context, controller),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              routeDisplayNames[controller.selectedRoute.value] ?? 
                  controller.selectedRoute.value,
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
  
  /// 쿠퍼티노 픽커 모달 표시
  void _showCupertinoPicker(BuildContext context, BusMapViewModel controller) {
    String tempSelectedRoute = controller.selectedRoute.value;
    
    final routes = [ "순환5_UP","순환5_DOWN", "1000_UP", "1000_DOWN", "810_UP", "810_DOWN", "820_UP", "820_DOWN", "821_UP", "821_DOWN"];
    int initialIndex = routes.indexOf(controller.selectedRoute.value);
    
    if (initialIndex < 0) initialIndex = 0;
    
    FixedExtentScrollController scrollController = FixedExtentScrollController(
        initialItem: initialIndex);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(  // Material 위젯으로 감싸서 테마 적용
        child: Container(
          height: 250,
          color: CupertinoTheme.of(context).brightness == Brightness.dark
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.white,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onPressed: () {
                    controller.selectedRoute.value = tempSelectedRoute;
                    onRouteSelected(tempSelectedRoute);
                    Navigator.pop(context);
                  },
                  child: const Text('적용'),
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Theme.of(context).brightness,
                    primaryColor: CupertinoColors.activeBlue,
                    textTheme: CupertinoTextThemeData(
                      pickerTextStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                  ),
                  child: CupertinoPicker(
                    scrollController: scrollController,
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      tempSelectedRoute = routes[index];
                    },
                    children: routes
                        .map((route) => Center(
                              child: Text(
                                  routeDisplayNames[route] ?? route,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Android용 드롭다운 위젯 구현
  Widget _buildAndroidPicker(BuildContext context, BusMapViewModel controller) {
    return DropdownButton<String>(
      isExpanded: true,
      value: controller.selectedRoute.value,
      alignment: Alignment.center,
        items: [ "순환5_UP","순환5_DOWN", "1000_UP", "1000_DOWN", "810_UP", "810_DOWN", "820_UP", "820_DOWN", "821_UP", "821_DOWN"]
          .map((route) => DropdownMenuItem(
                value: route,
                child: Text(
                  routeDisplayNames[route] ?? route,
                  textAlign: TextAlign.center,
                ),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onRouteSelected(value);
        }
      },
    );
  }
} 