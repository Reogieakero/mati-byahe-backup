import 'package:flutter/material.dart';

import '../constant/app_colors.dart';

enum SileoDialogType { success, info, error }

class SileoDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    SileoDialogType type = SileoDialogType.info,
    bool barrierDismissible = false,
  }) {
    final _DialogStyle style = _styleFor(type);

    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: style.accent.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.accent, size: 42),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _DialogStyle _styleFor(SileoDialogType type) {
    switch (type) {
      case SileoDialogType.success:
        return const _DialogStyle(
          icon: Icons.check_circle_rounded,
          accent: Color(0xFF34C759),
        );
      case SileoDialogType.error:
        return const _DialogStyle(
          icon: Icons.error_rounded,
          accent: Color(0xFFFF3B30),
        );
      case SileoDialogType.info:
        return const _DialogStyle(
          icon: Icons.info_rounded,
          accent: AppColors.primaryBlue,
        );
    }
  }
}

class _DialogStyle {
  final IconData icon;
  final Color accent;

  const _DialogStyle({required this.icon, required this.accent});
}
