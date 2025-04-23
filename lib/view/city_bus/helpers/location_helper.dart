import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../viewmodel/busmap_viewmodel.dart';
import '../components/station_item.dart';
import '../bus_map_view.dart';  // BusMapViewModelExtension 사용을 위해 추가

/// 위치 관련 헬퍼 기능 모음
class LocationHelper {
  /// 가장 가까운 정류장 찾기 및 스크롤 처리
  static void findNearestStationAndScroll(
    BuildContext context, 
    ScrollController scrollController
  ) {
    final controller = Get.find<BusMapViewModel>();

    if (controller.currentLocation.value == null) {
      // 위치 정보가 없으면 먼저 위치 권한 요청
      Fluttertoast.showToast(
        msg: kIsWeb 
            ? "브라우저에서 위치 정보를 가져오는 중입니다. 잠시 기다려주세요..." 
            : "위치 정보를 가져오는 중입니다...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      
      controller.checkLocationPermission().then((_) {
        if (controller.currentLocation.value != null) {
          _processNearestStation(context, controller, scrollController);
        } else {
          Fluttertoast.showToast(
            msg: kIsWeb 
                ? "브라우저에서 위치 정보를 가져오지 못했습니다. 브라우저 설정에서 위치 권한을 확인해주세요."
                : "위치 정보를 가져올 수 없습니다. 다시 시도해주세요.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      });
    } else {
      _processNearestStation(context, controller, scrollController);
    }
  }

  /// 가까운 정류장 찾고 스크롤 처리하는 내부 함수
  static void _processNearestStation(
    BuildContext context, 
    BusMapViewModel controller,
    ScrollController scrollController
  ) {
    final nearestStationIndex = controller.findNearestStation();

    if (nearestStationIndex == null) {
      Fluttertoast.showToast(
        msg: kIsWeb 
            ? "현재 위치에서 가까운 정류장을 찾을 수 없습니다. 위치 정보가 정확한지 확인해주세요."
            : "가까운 정류장을 찾을 수 없습니다.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    try {
      // 정류장 강조 표시 - BusMapViewModelExtension 사용
      controller.highlightStation(nearestStationIndex);
      
      // 5초 후 강조 표시 해제 타이머 설정
      Future.delayed(const Duration(seconds: 5), () {
        // 현재도 같은 정류장이 강조되어 있다면 해제
        if (BusMapViewModelExtension.highlightedStation.value == nearestStationIndex) {
          controller.clearHighlightedStation();
        }
      });
      
      // 스크롤 컨트롤러 사용
      if (scrollController.hasClients) {
        // 해당 인덱스로 스크롤
        final stationName = controller.stationNames[nearestStationIndex];
        
        // 레이아웃이 준비된 후 스크롤 실행 (더 정확한 계산을 위해)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 목표 위치 계산
          double targetOffset = 0.0;
          
          // 두 가지 방법으로 시도: 1) 고정 높이 기반, 2) 실제 렌더박스 크기 기반
          
          // 먼저 렌더박스를 사용하여 실제 항목 높이 얻기 시도
          try {
            final RenderBox? listBox = context.findRenderObject() as RenderBox?;
            if (listBox != null) {
              // 목록 높이와 아이템 수를 사용하여 평균 높이 계산
              double listHeight = listBox.size.height;
              int visibleItems = (listHeight / 81.0).ceil(); // 대략적인 아이템 수
              
              // 렌더박스에서 얻은 정보 기반으로 스크롤 계산
              double itemHeight = listHeight / visibleItems;
              targetOffset = nearestStationIndex * itemHeight;
              debugPrint("렌더박스 기반 계산: 높이 $itemHeight, 오프셋 $targetOffset");
            } else {
              // 고정 높이 기반으로 계산
              double itemHeight = 81.0; // 기본 StationItem 높이
              targetOffset = nearestStationIndex * itemHeight;
              debugPrint("고정 높이 기반 계산: $targetOffset");
            }
          } catch (e) {
            // 예외 발생 시 고정 높이 사용
            debugPrint("렌더박스 계산 오류, 고정 높이 사용: $e");
            targetOffset = nearestStationIndex * 81.0;
          }
          
          // 안전한 스크롤 범위 내로 제한
          double safeOffset = targetOffset.clamp(
            0.0, 
            scrollController.position.maxScrollExtent
          );
          
          debugPrint("스크롤 시도: 인덱스 $nearestStationIndex, 위치 $safeOffset");
          
          // 부드러운 스크롤 시도
          scrollController.animateTo(
            safeOffset,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ).catchError((error) {
            debugPrint("animateTo 실패, jumpTo 시도: $error");
            // 애니메이션 실패 시 즉시 이동
            scrollController.jumpTo(safeOffset);
          });
        });
      } else {
        // 스크롤 컨트롤러가 없거나 준비되지 않은 경우
        debugPrint("스크롤 컨트롤러가 준비되지 않았습니다");
        Fluttertoast.showToast(
          msg: "가장 가까운 정류장: ${controller.stationNames[nearestStationIndex]}",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint("스크롤 처리 중 오류 발생: $e");
      // 오류 발생시에도 정류장 정보는 표시
      Fluttertoast.showToast(
        msg: "정류장 정보 처리 중 오류가 발생했습니다: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
} 