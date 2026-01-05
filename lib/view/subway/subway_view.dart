import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../viewmodel/subway_viewmodel.dart';
import '../../models/subway_arrival_model.dart';
import 'subway_schedule_view.dart';

class SubwayView extends GetView<SubwayViewModel> {
  final String stationName;

  const SubwayView({Key? key, required this.stationName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SubwayViewModel>()) {
      Get.put(SubwayViewModel());
    }

    // Local state for selected station (default to passed stationName or '천안')
    final RxString selectedStation = (stationName == '아산' ? '아산' : '천안').obs;

    return Scaffold(
      // backgroundColor matches theme (0xFFFAFAFA)
      body: SafeArea(
        child: Column(
          children: [
             _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                       _buildStationSelector(selectedStation, context),
                      const SizedBox(height: 16),
                       _buildStatusBar(context),
                      const SizedBox(height: 24),
                      Obx(() => _buildArrivalContent(context, selectedStation.value)),
                       _buildFooter(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Text(
            '지하철 도착 정보',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 24), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildStationSelector(RxString selectedStation, BuildContext context) {
    return Obx(() {
      final isCheonan = selectedStation.value == '천안';
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                context,
                text: '천안역',
                isSelected: isCheonan,
                onTap: () => selectedStation.value = '천안',
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildToggleButton(
                context,
                text: '아산역',
                isSelected: !isCheonan,
                onTap: () => selectedStation.value = '아산',
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildToggleButton(BuildContext context,
      {required String text,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0052A4)
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : Colors.transparent, // Hover effect could be added here
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0052A4).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _PulsingDot(),
            const SizedBox(width: 8),
            Text(
              '실시간 운행 정보',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Get.to(() => const SubwayScheduleView()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
               boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(
                  '시간표 확인',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrivalContent(BuildContext context, String station) {
    if (!controller.isConnected.value && (controller.arrivalInfo[station]?.isEmpty ?? true)) {
          return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('연결 중...', style: TextStyle(color: Theme.of(context).hintColor)),
                ],
              ),
            ),
          );
    }
    
    final arrivals = controller.arrivalInfo[station] ?? [];
    
    if (arrivals.isEmpty) {
        return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
                child: Text('도착 정보가 없습니다.', style: TextStyle(color: Theme.of(context).hintColor))),
        );
    }

    // Filter Up (상행) and Down (하행)
    
    final upLine = arrivals.where((a) => a.updnLine.contains('상행')).toList();
    final downLine = arrivals.where((a) => a.updnLine.contains('하행')).toList();

    return Column(
      children: [
        _buildSection(context, '상행', '(서울/청량리 방면)', upLine, Icons.arrow_circle_up),
        const SizedBox(height: 24),
        _buildSection(context, '하행', '(신창/아산 방면)', downLine, Icons.arrow_circle_down),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, String subTitle,
      List<SubwayArrival> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF0052A4), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(
              subTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildArrivalCard(context, item)).toList(),
      ],
    );
  }

  Widget _buildArrivalCard(BuildContext context, SubwayArrival arrival) {
    // 열차번호 자릿수로 급행 구분
    final String digits = arrival.btrainNo?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final isExpress = digits.length == 4;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              color: const Color(0xFF0052A4), // Line Color
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0052A4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '1호선',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isExpress) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '급행',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          arrival.btrainNo ?? '', // Train Number e.g. 1023호
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${arrival.bstatnNm}행', // Destination e.g. 광운대행
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onBackground,
                                height: 1.2,
                              ),
                            ),
                          
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              arrival.arvlMsg2, // e.g. [2]번째 전역
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B6B), // Primary red-ish
                              ),
                            ),
                            
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 14, color: Theme.of(context).hintColor),
            const SizedBox(width: 6),
            Text(
              '실시간 정보는 상황에 따라 다를 수 있습니다',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  _PulsingDotState createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(seconds: 1), vsync: this)
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green.withOpacity(_animation.value),
          ),
        );
      },
    );
  }
}
