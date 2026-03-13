import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constant/app_colors.dart';
import '../../../core/widgets/sileo_notification.dart';

class ReportDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isCopyable;
  final Color? iconColor;

  const ReportDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isCopyable = false,
    this.iconColor,
  });

  void _showCustomCopyToast(BuildContext context) {
    SileoNotification.show(
      context,
      '$label copied to clipboard',
      type: SileoNoticeType.success,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isCopyable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              HapticFeedback.mediumImpact(); // Stronger feedback for design feel
              _showCustomCopyToast(context);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textGrey),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.darkNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isCopyable) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.copy_rounded,
                size: 14,
                color: iconColor ?? Colors.redAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
