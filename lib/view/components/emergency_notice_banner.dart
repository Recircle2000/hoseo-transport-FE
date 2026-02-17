import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/emergency_notice_model.dart';
import '../../repository/emergency_notice_repository.dart';
import '../emergency_notice_detail_view.dart';

class EmergencyNoticeBanner extends StatefulWidget {
  const EmergencyNoticeBanner({
    super.key,
    required this.category,
  });

  final EmergencyNoticeCategory category;

  @override
  State<EmergencyNoticeBanner> createState() => _EmergencyNoticeBannerState();
}

class _EmergencyNoticeBannerState extends State<EmergencyNoticeBanner> {
  final EmergencyNoticeRepository _repository = EmergencyNoticeRepository();
  Future<EmergencyNotice?>? _noticeFuture;

  @override
  void initState() {
    super.initState();
    _loadNotice();
  }

  @override
  void didUpdateWidget(covariant EmergencyNoticeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) {
      _loadNotice();
    }
  }

  void _loadNotice() {
    _noticeFuture = _repository.fetchLatestNotice(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bannerColor = isDark
        ? colorScheme.errorContainer.withValues(alpha: 0.45)
        : colorScheme.errorContainer;
    final borderColor = isDark
        ? colorScheme.error.withValues(alpha: 0.55)
        : colorScheme.error.withValues(alpha: 0.28);
    final foregroundColor = colorScheme.onErrorContainer;

    return FutureBuilder<EmergencyNotice?>(
      future: _noticeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          debugPrint('Emergency notice error: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        final notice = snapshot.data;
        if (notice == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Get.to(() => EmergencyNoticeDetailView(notice: notice));
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                child: Row(
                  children: [
                    Icon(
                      Icons.notification_important_rounded,
                      size: 18,
                      color: foregroundColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notice.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: foregroundColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: foregroundColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
