import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import '../viewmodel/notice_viewmodel.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'notice_detail_view.dart';
import 'notice_list_view.dart';
import 'city_bus/bus_map_view.dart';
import 'shuttle_bus/shuttle_route_selection_view.dart';
import 'settings_view.dart';
import 'components/upcoming_departures_widget.dart';
import '../utils/platform_utils.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final noticeViewModel = Get.put(NoticeViewModel());
  // 뒤로가기 시간 저장
  DateTime? _lastBackPressedTime;
  
  @override
  Widget build(BuildContext context) {
    // 다크모드 감지
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : const Color(0xFFFAFAFA);

    return WillPopScope(
      // 뒤로가기 처리
      onWillPop: () async {
        // Android에서만 동작
        if (!Platform.isAndroid) return true;

        // 현재 시간
        final currentTime = DateTime.now();

        // 처음 뒤로가기를 누른 경우 또는 마지막으로 누른 지 3초가 지난 경우
        if (_lastBackPressedTime == null ||
            currentTime.difference(_lastBackPressedTime!) > const Duration(seconds: 2)) {
          // 현재 시간 저장
          _lastBackPressedTime = currentTime;

          // 뒤로가기 안내 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('한 번 더 누르면 종료됩니다'),
              duration: Duration(seconds: 2),
            ),
          );

          return false; // 앱 종료 방지
        }

        return true; // 두 번째 누른 경우 앱 종료
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor, // 앱바도 배경과 같은 색상
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            '호통',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, size: 24),
              onPressed: () => Get.to(() => SettingsView()),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 공지사항
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        // 공지사항 제목과 전체보기 버튼이 있는 헤더
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '공지사항',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  noticeViewModel.fetchAllNotices();
                                  Get.to(() => const NoticeListView());
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  '전체보기',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 구분선 추가
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 4),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        // 공지사항 내용
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            final notice = noticeViewModel.notice.value;
                            if (notice != null) {
                              Get.to(() => NoticeDetailView(notice: notice));
                            } else {
                              noticeViewModel.fetchLatestNotice();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.campaign_outlined,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
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
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: AutoScrollText(
                                                    text: notice?.title ?? '공지사항이 없습니다',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    scrollDuration: const Duration(seconds: 5),
                                                  ),
                                                ),
                                                if (notice != null) 
                                                  const SizedBox(width: 6),
                                                if (notice != null) ...[
                                                  _buildNoticeBadge(notice.createdAt),
                                                ],
                                              ],
                                            ),
                                            if (notice != null)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 10,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _getTimeAgo(notice.createdAt),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: noticeViewModel.getNoticeTypeColor(notice.noticeType),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        noticeViewModel.getNoticeTypeDisplayName(notice.noticeType),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 곧 출발 섹션
              UpcomingDeparturesWidget(),
              
             // const SizedBox(height: 16),
              // 메뉴
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMenuCard(
                            context,
                            title: '셔틀버스',
                            icon: Icons.airport_shuttle,
                            color: Color(0xFFB83227),
                            onTap: () {
                              HapticFeedback.mediumImpact(); // 햅틱 피드백
                              Get.to(() => ShuttleRouteSelectionView());
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMenuCard(
                            context,
                            title: '시내버스',
                            icon: Icons.directions_bus,
                            color: Colors.blue,
                            onTap: () {
                              HapticFeedback.mediumImpact(); // 햅틱 피드백
                              Get.to(() => BusMapView());
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 면책 문구
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        PlatformUtils.shortDisclaimer,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        PlatformUtils.showPlatformDisclaimerDialog(context);
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '자세히 보기',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: color,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeBadge(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    // 24시간 이내인 경우에만 NEW 배지 표시
    if (difference.inHours < 24) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: const Text(
          'NEW',
          style: TextStyle(
            fontSize: 8,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    
    // 24시간 이상인 경우 빈 위젯 반환
    return const SizedBox();
  }

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays < 1) {
      return '오늘';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  }
}
