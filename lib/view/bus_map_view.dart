import 'package:flutter/material.dart';
        import 'package:flutter_map/flutter_map.dart';
        import 'package:get/get.dart';
        import 'package:latlong2/latlong.dart';
        import '../viewmodel/busmap_viewmodel.dart';

        class BusMapView extends StatelessWidget {
          @override
          Widget build(BuildContext context) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('시내버스 위치'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Get.delete<BusMapViewModel>(); //  타이머 정리
                    Get.back();
                  },
                ),
              ),
              body: GetBuilder<BusMapViewModel>(
                init: BusMapViewModel(), // 새 ViewModel 초기화
                builder: (controller) => Column(
                  children: [
                    Obx(() => DropdownButton<String>(
                      value: controller.selectedRoute.value,
                      items: ["순환5_DOWN", "순환5_UP", "900_UP", "900_DOWN"]
                          .map((route) => DropdownMenuItem(
                        value: route,
                        child: Text(route),
                      ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.selectedRoute.value = value;
                        }
                      },
                    )),
                    Expanded(
                      child: FlutterMap(
                        mapController: controller.mapController,
                        options: MapOptions(
                          initialCenter: LatLng(36.769423, 127.047998),
                          initialZoom: 13,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom | InteractiveFlag.scrollWheelZoom | InteractiveFlag.drag
                          )
                        ),

                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          Obx(() {
                            return MarkerLayer(
                              markers: controller.markers.toList(),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }