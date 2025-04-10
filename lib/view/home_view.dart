import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'city_bus/bus_map_view.dart';
import 'settings_view.dart';
import 'shuttle_map_view.dart';
import '../viewmodel/notice_viewmodel.dart';
import 'notice_detail_view.dart';
import 'notice_list_view.dart';

class HomeView extends StatelessWidget {
  final noticeViewModel = Get.put(NoticeViewModel());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('교통 서비스'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => SettingsView()),
          ),
        ],
      ),
      body: Column(
        children: [
          // 환영 메시지 섹션
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '환영합니다!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '다양한 교통 정보를 확인하세요.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          // 공지사항 섹션
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final notice = noticeViewModel.notice.value;
                  if (notice != null) {
                    Get.to(() => NoticeDetailView(notice: notice));
                  } else {
                    noticeViewModel.fetchLatestNotice(); // 공지사항이 없을 경우 새로고침
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: // lib/view/home_view.dart의 공지사항 섹션 Row 위젯 수정
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.campaign_outlined),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            final notice = noticeViewModel.notice.value;
                            if (notice != null) {
                              Get.to(() => NoticeDetailView(notice: notice));
                            }
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '공지사항',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Obx(() => noticeViewModel.notice.value != null
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'NEW',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : const SizedBox()),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Obx(() {
                                if (noticeViewModel.isLoading.value) {
                                  return const Text(
                                    '로딩중...',
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  );
                                }

                                if (noticeViewModel.error.isNotEmpty) {
                                  return Text(
                                    noticeViewModel.error.value,
                                    style: const TextStyle(fontSize: 14, color: Colors.red),
                                  );
                                }

                                final notice = noticeViewModel.notice.value;
                                return Text(
                                  notice?.title ?? '공지사항이 없습니다',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: Colors.grey.withOpacity(0.5)),
                        onPressed: () {
                          noticeViewModel.fetchAllNotices();
                          Get.to(() => const NoticeListView());
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 메뉴 그리드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                physics: const BouncingScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildMenuButton(
                    context,
                    title: '시내버스',
                    icon: Icons.directions_bus,
                    color: Colors.blue,
                    onTap: () => Get.to(() => BusMapView()),
                  ),
                  _buildMenuButton(
                    context,
                    title: '셔틀버스',
                    icon: Icons.airport_shuttle,
                    color: Colors.red,
                    onTap: () => Get.to(() => ShuttleMapView()),
                  ),
                  _buildMenuButton(
                    context,
                    title: '준비중',
                    icon: Icons.schedule,
                    color: Colors.grey,
                    onTap: () {},
                  ),
                  _buildMenuButton(
                    context,
                    title: '준비중',
                    icon: Icons.more_horiz,
                    color: Colors.grey,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    final backgroundColor = brightness == Brightness.dark
        ? color.withOpacity(0.2)
        : color.withOpacity(0.1);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
