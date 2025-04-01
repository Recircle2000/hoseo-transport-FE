import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShuttleMapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('셔틀버스 시간표'),
      ),
      body: Center(
        child: Text('셔틀버스 정보가 여기에 표시됩니다.'),
      ),
    );
  }
} 