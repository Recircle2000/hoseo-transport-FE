import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../../viewmodel/busmap_viewmodel.dart';

class BusMapNDetailView extends StatelessWidget {
  final String routeName;

  BusMapNDetailView({Key? key, required this.routeName}) : super(key: key);

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
        builder: (controller) => NaverMap(
          options: NaverMapViewOptions(
            initialCameraPosition: const NCameraPosition(
              target: NLatLng(36.769423, 127.047998),
              zoom: 13,
            ),
          ),
        ),
      ),
    );
  }
}