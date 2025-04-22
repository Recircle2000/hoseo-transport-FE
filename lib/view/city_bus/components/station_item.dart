import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../viewmodel/busmap_viewmodel.dart';

// BusMapViewModel 확장 - 강조 표시용 변수
// 전역 상태로 사용하기 위해 파일 레벨에 선언
class StationHighlightManager {
  static final RxInt highlightedStation = RxInt(-1);
  
  static void highlightStation(int index) {
    highlightedStation.value = index;
  }
  
  static void clearHighlightedStation() {
    highlightedStation.value = -1;
  }
}

class StationItem extends StatelessWidget {
  final int index;
  final String stationName;
  final bool isBusHere;
  final bool isLastStation;

  const StationItem({
    Key? key,
    required this.index,
    required this.stationName,
    required this.isBusHere,
    required this.isLastStation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 강조 표시 여부 확인
      final isHighlighted = StationHighlightManager.highlightedStation.value == index;
      
      // 강조 표시된 정류장이면 애니메이션 효과 추가
      if (isHighlighted) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Container(
              decoration: BoxDecoration(
                color: Color.lerp(Colors.transparent, Colors.yellow.withOpacity(0.3), value),
                borderRadius: BorderRadius.circular(8),
              ),
              child: child,
            );
          },
          child: _buildStationContent(context, isHighlighted),
        );
      }
      
      // 일반 정류장
      return _buildStationContent(context, isHighlighted);
    });
  }
  
  // 정류장 내용 위젯
  Widget _buildStationContent(BuildContext context, bool isHighlighted) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 26.0, horizontal: 16.0),
          child: Row(
            children: [
              // 왼쪽: 정류장 번호와 연결선
              SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: StationPainter(
                        index: index,
                        isLastStation: isLastStation,
                        isHighlighted: isHighlighted,
                      ),
                      size: const Size(24, 24),
                    ),
                    Center(
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: isHighlighted ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 버스 아이콘
              SizedBox(
                width: 40,
                child: isBusHere
                    ? const Icon(
                        Icons.directions_bus,
                        color: Colors.blue,
                        size: 20,
                      )
                    // 강조 표시된 정류장이면 위치 아이콘 표시
                    : isHighlighted 
                      ? _buildPulsingIcon()
                      : null,
              ),

              // 정류장 이름과 번호
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isBusHere || isHighlighted 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                        color: isHighlighted 
                            ? Colors.orange
                            : isBusHere
                              ? Colors.blue
                              : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      final controller = Get.find<BusMapViewModel>();
                      final stationNumber =
                          controller.stationNumbers.length > index
                              ? controller.stationNumbers[index]
                              : "";
                      return Text(
                        "$stationNumber",
                        style: TextStyle(
                          fontSize: 12,
                          color: isHighlighted ? Colors.orange[700] : Colors.grey,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 구분선
        if (!isLastStation)
          Padding(
            padding: const EdgeInsets.only(left: 76.0),
            child: Divider(
              height: 0, 
              thickness: 1, 
              color: isHighlighted ? Colors.orange.withOpacity(0.3) : Colors.grey,
            ),
          ),
      ],
    );
  }
  
  // 펄스 애니메이션 아이콘
  Widget _buildPulsingIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      // 애니메이션 반복
      onEnd: () {
        // 반복 애니메이션을 위해 다시 빌드하게 함
        Future.microtask(() => StationHighlightManager.highlightedStation.refresh());
      },
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: const Icon(
        Icons.location_on,
        color: Colors.orange,
        size: 20,
      ),
    );
  }
}

class StationPainter extends CustomPainter {
  final int index;
  final bool isLastStation;
  final bool isHighlighted;

  StationPainter({
    required this.index,
    required this.isLastStation,
    required this.isHighlighted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 원 그리기
    final Paint circlePaint = Paint()
      ..color = isHighlighted ? Colors.orange[100]! : Colors.grey[300]!
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = isHighlighted ? Colors.orange : Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted ? 2.0 : 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 세로선 그리기 (마지막 정류장이 아닌 경우)
    if (!isLastStation) {
      final Paint linePaint = Paint()
        ..color = isHighlighted ? Colors.orange[300]! : Colors.grey[300]!
        ..strokeWidth = isHighlighted ? 2.0 : 2.0;

      final startPoint = Offset(size.width / 2, size.height);
      final endPoint = Offset(size.width / 2, size.height + 64.0); // 다음 원까지의 거리

      canvas.drawLine(startPoint, endPoint, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 