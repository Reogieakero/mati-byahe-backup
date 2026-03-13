import 'package:flutter/material.dart';

import '../constant/app_colors.dart';

enum SileoNoticeType { info, success, error, warning }

class SileoNotification {
  static void show(
    BuildContext context,
    String message, {
    SileoNoticeType type = SileoNoticeType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final _NoticeStyle style = _styleFor(type);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkNavy,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: style.accentColor.withOpacity(0.45)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1E000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(style.icon, size: 20, color: style.accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _NoticeStyle _styleFor(SileoNoticeType type) {
    switch (type) {
      case SileoNoticeType.success:
        return const _NoticeStyle(
          icon: Icons.check_circle_rounded,
          accentColor: Color(0xFF34C759),
        );
      case SileoNoticeType.error:
        return const _NoticeStyle(
          icon: Icons.error_rounded,
          accentColor: Color(0xFFFF3B30),
        );
      case SileoNoticeType.warning:
        return const _NoticeStyle(
          icon: Icons.warning_amber_rounded,
          accentColor: AppColors.primaryYellow,
        );
      case SileoNoticeType.info:
        return const _NoticeStyle(
          icon: Icons.info_rounded,
          accentColor: AppColors.primaryBlue,
        );
    }
  }
}

class _NoticeStyle {
  final IconData icon;
  final Color accentColor;

  const _NoticeStyle({required this.icon, required this.accentColor});
}
