import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/env_config.dart';
import '../models/subway_schedule_model.dart';

class SubwayRepository {
  Future<SubwaySchedule> fetchSchedule(String stationName, String dayType) async {
    final baseUrl = EnvConfig.baseUrl;
    final uri = Uri.parse('$baseUrl/subway/schedule')
        .replace(queryParameters: {
      'station_name': stationName,
      'day_type': dayType,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // UTF-8 decoding is important for Korean characters
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(decodedBody);
        return SubwaySchedule.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load schedule: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching schedule: $e');
    }
  }
}
