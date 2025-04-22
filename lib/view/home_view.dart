import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;
import '../viewmodel/notice_viewmodel.dart';
import 'notice_detail_view.dart';
import 'notice_list_view.dart';
import 'city_bus/bus_map_view.dart';
import 'shuttle_bus/shuttle_route_selection_view.dart';
import 'settings_view.dart';

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
    // 사용자 이름
    final String userName = "사용자";
    // 인사말
    final int hour = DateTime.now().hour;
    String greeting = "안녕하세요!";
    
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
            'HOSEO Transport',
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
              // 환영 메시지
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$userName님, $greeting",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '호서대학교의 모든 교통 정보를 확인해보세요!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
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
                    child: InkWell(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                                  Row(
                                    children: [
                                      const Text(
                                        '공지사항',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Obx(() {
                                        final notice = noticeViewModel.notice.value;
                                        if (notice == null) return const SizedBox();
                                        
                                        // 현재 시간과 공지 생성 시간의 차이 계산
                                        final now = DateTime.now();
                                        final difference = now.difference(notice.createdAt);
                                        
                                        // 1일(24시간) 이내인 경우 NEW 배지 표시
                                        if (difference.inHours < 24) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              'NEW',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        } else {
                                          // 1일 이상인 경우 경과 시간 표시
                                          String timeAgo;
                                          if (difference.inDays < 1) {
                                            timeAgo = '오늘';
                                          } else if (difference.inDays < 7) {
                                            timeAgo = '${difference.inDays}일 전';
                                          } else if (difference.inDays < 30) {
                                            timeAgo = '${(difference.inDays / 7).floor()}주 전';
                                          } else if (difference.inDays < 365) {
                                            timeAgo = '${(difference.inDays / 30).floor()}개월 전';
                                          } else {
                                            timeAgo = '${(difference.inDays / 365).floor()}년 전';
                                          }
                                          
                                          return Text(
                                            timeAgo,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.normal,
                                            ),
                                          );
                                        }
                                      }),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
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
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // 공지사항 전체보기 버튼
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      noticeViewModel.fetchAllNotices();
                      Get.to(() => const NoticeListView());
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '전체보기',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 메뉴
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      context,
                      title: '시내버스',
                      icon: Icons.directions_bus,
                      color: Colors.blue,
                      onTap: () => Get.to(() => BusMapView()),
                    ),
                    _buildMenuCard(
                      context,
                      title: '셔틀버스',
                      icon: Icons.airport_shuttle,
                      color: Color(0xFFB83227),
                      onTap: () => Get.to(() => ShuttleRouteSelectionView()),
                    ),
                    _buildMenuCard(
                      context,
                      title: '준비중',
                      icon: Icons.schedule,
                      color: Colors.grey,
                      onTap: () {},
                    ),
                    _buildMenuCard(
                      context,
                      title: '준비중',
                      icon: Icons.more_horiz,
                      color: Colors.grey,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 면책 문구
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '이 앱은 호서대학교 비공식 앱이며, 외부 데이터를 기반으로 정보를 제공합니다. \n'
                        '실제 운행과 차이가 있을 수 있으니 공식 정보를 함께 확인해 주세요.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          height: 1.4,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
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
}
