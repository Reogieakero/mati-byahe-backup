import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constant/app_colors.dart';

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
    final Color primaryRed = iconColor ?? Colors.redAccent;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: primaryRed,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "$label Copied to Clipboard",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.darkNavy, // Matching the Hero card dark
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: primaryRed.withOpacity(0.5), width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
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
