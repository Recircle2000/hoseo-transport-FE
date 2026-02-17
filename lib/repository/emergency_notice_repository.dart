import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/emergency_notice_model.dart';
import '../utils/env_config.dart';

class EmergencyNoticeRepository {
  Future<EmergencyNotice?> fetchLatestNotice(
    EmergencyNoticeCategory category,
  ) async {
    final uri = Uri.parse('${EnvConfig.baseUrl}/emergency-notices/latest')
        .replace(queryParameters: {'category': category.apiValue});

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final rawBody = utf8.decode(response.bodyBytes).trim();
      if (rawBody.isEmpty || rawBody == 'null') {
        return null;
      }

      final jsonData = json.decode(rawBody);
      if (jsonData == null) {
        return null;
      }

      return EmergencyNotice.fromJson(Map<String, dynamic>.from(jsonData));
    }

    if (response.statusCode == 422) {
      throw FormatException(
        'Invalid emergency notice category: ${category.apiValue}',
      );
    }

    throw Exception(
      'Failed to load emergency notice (status: ${response.statusCode})',
    );
  }
}
