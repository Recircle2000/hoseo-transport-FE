import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../viewmodel/busmap_viewmodel.dart';

class BusMapDetailView extends StatelessWidget {
  final String routeName;

  BusMapDetailView({Key? key, required this.routeName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routeName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<BusMapViewModel>(
        builder: (controller) => Stack(
          children: [
            FlutterMap(
              mapController: controller.mapController,
              options: MapOptions(
                initialCenter: LatLng(36.769423, 127.047998),
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
                  userAgentPackageName: 'com.example.app',
                ),
                Obx(() => PolylineLayer(polylines: controller.polylines.toList())),
                Obx(() => MarkerLayer(markers: controller.stationMarkers.toList())),
                Obx(() => MarkerLayer(markers: controller.markers.toList())),
                // 현재 위치 마커
                Obx(() {
                  if (controller.currentLocation.value != null) {
                    return MarkerLayer(
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
                    );
                  } else {
                    return const MarkerLayer(markers: []);
                  }
                }),
              ],
            ),
            // 현재 위치 버튼
            Positioned(
              right: 16,
              bottom: 16,
              child: Obx(() => FloatingActionButton(
                heroTag: "locationButton",
                mini: true,
                onPressed: () => controller.moveToCurrentLocation(),
                backgroundColor: Colors.white,
                child: Icon(
                  controller.isLocationLoading.value
                      ? Icons.hourglass_empty
                      : Icons.my_location,
                  color: controller.isLocationEnabled.value
                      ? Colors.blue
                      : Colors.grey,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }
} 