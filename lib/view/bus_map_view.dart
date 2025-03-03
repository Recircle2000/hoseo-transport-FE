import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../viewmodel/busmap_viewmodel.dart';

class BusMapView extends StatelessWidget {
  final BusMapViewModel _busMapViewModel = Get.put(BusMapViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시내버스 위치')),
      body: Column(
        children: [
          Obx(() => DropdownButton<String>(
                value: _busMapViewModel.selectedRoute.value,
                items: ["순환5_DOWN", "순환5_UP", "900_UP", "900_DOWN"]
                    .map((route) => DropdownMenuItem(
                          value: route,
                          child: Text(route),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _busMapViewModel.selectedRoute.value = value;
                  }
                },
              )),
          Expanded(
            child: FlutterMap(
              mapController: _busMapViewModel.mapController,
              options: MapOptions(
                initialCenter: LatLng(36.769423, 127.047998),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                Obx(() {
                  return MarkerLayer(
                    markers: _busMapViewModel.markers.toList(),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
