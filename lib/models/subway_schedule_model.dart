class SubwaySchedule {
  final String dayType;
  final String stationName;
  final Map<String, List<SubwayScheduleItem>> timetable;

  SubwaySchedule({
    required this.dayType,
    required this.stationName,
    required this.timetable,
  });

  factory SubwaySchedule.fromJson(Map<String, dynamic> json) {
    var timetableJson = json['timetable'] as Map<String, dynamic>;
    Map<String, List<SubwayScheduleItem>> timetableData = {};

    timetableJson.forEach((key, value) {
      if (value is List) {
        timetableData[key] = value
            .map((item) => SubwayScheduleItem.fromJson(item))
            .toList();
      }
    });

    return SubwaySchedule(
      dayType: json['day_type'] ?? '',
      stationName: json['station_name'] ?? '',
      timetable: timetableData,
    );
  }
}

class SubwayScheduleItem {
  final String trainNo;
  final String arrivalStation;
  final String departureTime;
  final bool isExpress;

  SubwayScheduleItem({
    required this.trainNo,
    required this.arrivalStation,
    required this.departureTime,
    required this.isExpress,
  });

  factory SubwayScheduleItem.fromJson(Map<String, dynamic> json) {
    return SubwayScheduleItem(
      trainNo: json['trainno'] ?? '',
      arrivalStation: json['arrival_station'] ?? '',
      departureTime: json['departure_time'] ?? '',
      isExpress: json['is_express'] ?? false,
    );
  }
}
