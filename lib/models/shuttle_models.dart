import 'package:flutter/material.dart';

class ShuttleRoute {
  final int id;
  final String routeName;
  final String direction;

  ShuttleRoute({
    required this.id,
    required this.routeName,
    required this.direction,
  });

  factory ShuttleRoute.fromJson(Map<String, dynamic> json) {
    return ShuttleRoute(
      id: json['id'],
      routeName: json['route_name'],
      direction: json['direction'],
    );
  }
}

class Schedule {
  final int id;
  final int routeId;
  final String scheduleType;
  final DateTime startTime;
  final int round;

  Schedule({
    required this.id,
    required this.routeId,
    required this.scheduleType,
    required this.startTime,
    required this.round,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final timeStr = json['start_time'];
    DateTime startTime;
    try {
      final now = DateTime.now();
      final timeParts = timeStr.split(':');
      startTime = DateTime(
        now.year, 
        now.month, 
        now.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        int.parse(timeParts[2]),
      );
    } catch (e) {
      print('시간 파싱 오류: $timeStr - $e');
      startTime = DateTime.now();
    }

    return Schedule(
      id: json['id'],
      routeId: json['route_id'],
      scheduleType: json['schedule_type'],
      startTime: startTime,
      round: json['round'] ?? 1,
    );
  }
}

class ScheduleStop {
  final String stationName;
  final String arrivalTime;
  final int stopOrder;

  ScheduleStop({
    required this.stationName,
    required this.arrivalTime,
    required this.stopOrder,
  });

  factory ScheduleStop.fromJson(Map<String, dynamic> json) {
    return ScheduleStop(
      stationName: json['station_name'],
      arrivalTime: json['arrival_time'],
      stopOrder: json['stop_order'],
    );
  }
}

class ShuttleStation {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? description;
  final String? imageUrl;

  ShuttleStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    this.imageUrl,
  });

  factory ShuttleStation.fromJson(Map<String, dynamic> json) {
    return ShuttleStation(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }
}

class StationSchedule {
  final int routeId;
  final String stationName;
  final String arrivalTime;
  final int stopOrder;
  final String scheduleType;

  StationSchedule({
    required this.routeId,
    required this.stationName,
    required this.arrivalTime,
    required this.stopOrder,
    required this.scheduleType,
  });

  factory StationSchedule.fromJson(Map<String, dynamic> json) {
    return StationSchedule(
      routeId: json['route_id'],
      stationName: json['station_name'],
      arrivalTime: json['arrival_time'],
      stopOrder: json['stop_order'],
      scheduleType: json['schedule_type'] ?? 'Weekday',
    );
  }
} 