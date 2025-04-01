import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class BusTimetableView extends StatelessWidget {
  final String route;

  const BusTimetableView({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$route 시간표'),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: loadTimetable(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('시간표를 불러올 수 없습니다: ${snapshot.error}'));
          }

          final times = (snapshot.data?[route] as List<dynamic>?) ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Table(
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                children: [
                  for (var i = 0; i < times.length; i += 3)
                    TableRow(
                      children: [
                        for (var j = 0; j < 3; j++)
                          if (i + j < times.length)
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  times[i + j].toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          else
                            const TableCell(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(''),
                              ),
                            ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> loadTimetable() async {
    final String jsonString = await rootBundle.loadString('assets/bus_times/bus_times.json');
    return json.decode(jsonString);
  }
}