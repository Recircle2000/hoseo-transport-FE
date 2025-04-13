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
    return Schedule(
      id: json['id'],
      routeId: json['route_id'],
      scheduleType: json['schedule_type'],
      startTime: DateTime.parse(json['start_time']),
      round: json['round'],
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