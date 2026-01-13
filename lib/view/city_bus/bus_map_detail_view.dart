import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodel/busmap_viewmodel.dart';
import '../../viewmodel/settings_viewmodel.dart';

class BusMapDetailView extends StatefulWidget {
  final String routeName;
  
  BusMapDetailView({Key? key, required this.routeName}) : super(key: key);

  @override
  State<BusMapDetailView> createState() => _BusMapDetailViewState();
}

class _BusMapDetailViewState extends State<BusMapDetailView> {
  final BusMapViewModel controller = Get.find<BusMapViewModel>();
  final SettingsViewModel settingsViewModel = Get.find<SettingsViewModel>();
  
  @override
  void initState() {
    super.initState();
    // 뷰가 생성될 때 현재 위치 확인
    _getCurrentLocation();
    
    // 지도가 로드된 후 현재 위치로 이동
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(const Duration(milliseconds: 500), () {
    //     if (controller.currentLocation.value != null) {
    //       controller.moveToCurrentLocation();
    //     }
    //   });
    // });
  }
  
  // 현재 위치 확인 메서드
  Future<void> _getCurrentLocation() async {
    if (controller.currentLocation.value == null) {
      await controller.checkLocationPermission();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routeName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: GetBuilder<BusMapViewModel>(
        builder: (controller) => Stack(
          children: [
            Obx(() {
              // 캠퍼스에 따라 기본 중심 좌표 결정
              final campus = settingsViewModel.selectedCampus.value;
              final LatLng defaultCenter =
                  campus == "천안"
                      ? LatLng(36.8299, 127.1814)
                      : LatLng(36.769423, 127.08);
              return FlutterMap(
                mapController: controller.mapController,
                options: MapOptions(
                  // 현재 위치가 있으면 현재 위치를, 없으면 기본 위치를 중심으로 설정
                  //initialCenter: controller.currentLocation.value ?? defaultCenter,
                  initialCenter: defaultCenter,
                  initialZoom: 13,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.flingAnimation,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.jw.hoseotransport',
                  ),
                  PolylineLayer(polylines: controller.polylines.toList()),
                  MarkerLayer(markers: controller.stationMarkers.toList()),
                  MarkerLayer(markers: controller.markers.toList()),
                  // 현재 위치 마커
                  if (controller.currentLocation.value != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: controller.currentLocation.value!,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                ],
              );
            }),
            // 현재 위치 버튼
            Positioned(
              right: 16,
              bottom: 16,
              child: Obx(() => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () => controller.moveToCurrentLocation(),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        controller.isLocationLoading.value
                            ? Icons.hourglass_empty
                            : Icons.my_location,
                        color: controller.isLocationEnabled.value
                            ? Colors.blue
                            : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
} 