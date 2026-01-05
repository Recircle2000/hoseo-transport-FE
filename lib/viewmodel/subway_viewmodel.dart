import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/subway_arrival_model.dart';
import '../utils/env_config.dart';

class SubwayViewModel extends GetxController {
  WebSocketChannel? _channel;
  final RxMap<String, List<SubwayArrival>> arrivalInfo = <String, List<SubwayArrival>>{}.obs;
  final RxBool isConnected = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    connectWebSocket();
  }

  @override
  void onClose() {
    _channel?.sink.close();
    super.onClose();
  }

  void connectWebSocket() {
    try {
      final baseUrl = EnvConfig.baseUrl; // e.g. https://hotong.click
      // Replace https:// or http:// with wss:// or ws://
      String wsUrl = baseUrl.replaceFirst(RegExp(r'^http'), 'ws'); 
      if (!wsUrl.endsWith('/')) {
        wsUrl += '/';
      }
      wsUrl += 'subway/ws';
      print('Connecting to Subway WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      isConnected.value = true;

      _channel!.stream.listen(
        (message) {
          try {
            final decodedMessage = jsonDecode(message) as Map<String, dynamic>;
            final Map<String, List<SubwayArrival>> parsedData = {};

            decodedMessage.forEach((station, list) {
              if (list is List) {
                parsedData[station] = list.map((e) => SubwayArrival.fromJson(e)).toList();
              }
            });

            arrivalInfo.value = parsedData;
          } catch (e) {
            print('Error parsing subway data: $e');
          }
        },
        onError: (e) {
          isConnected.value = false;
          error.value = 'WebSocket Error: $e';
          print('WebSocket Error: $e');
        },
        onDone: () {
          isConnected.value = false;
          print('WebSocket Connection Closed');
          // Reconnect logic could be added here
        },
      );
    } catch (e) {
      isConnected.value = false;
      error.value = 'Connection failed: $e';
      print('Connection failed: $e');
    }
  }
}
