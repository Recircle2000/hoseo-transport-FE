import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../viewmodel/notice_viewmodel.dart';
import 'notice_detail_view.dart';

class NoticeListView extends GetView<NoticeViewModel> {
  const NoticeListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 공지사항'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }

        return ListView.separated(
          itemCount: controller.allNotices.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final notice = controller.allNotices[index];
            return ListTile(
              title: Text(notice.title),
              subtitle: Text(
                notice.createdAt.toLocal().toString().split('.')[0],
                style: TextStyle(color: Colors.grey[600]),
              ),
              onTap: () => Get.to(() => NoticeDetailView(notice: notice)),
            );
          },
        );
      }),
    );
  }
}