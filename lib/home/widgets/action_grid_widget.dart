import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';
import '../../other screens/news_screen.dart';
import '../../other screens/tracking_screen.dart';
import '../../qrscanner/qr_scanner_view.dart';
import '../../report/driver_report_history_screen.dart';

class ActionGridWidget extends StatelessWidget {
  final String role;

  const ActionGridWidget({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final isDriver = role.toLowerCase() == 'driver';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(Icons.newspaper_rounded, "News", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewsScreen()),
            );
          }),
          _buildItem(
            isDriver ? Icons.report_problem_rounded : Icons.analytics_rounded,
            isDriver ? "Report" : "Track",
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => isDriver
                      ? const DriverReportHistoryScreen()
                      : const TrackingScreen(),
                ),
              );
            },
          ),
          _buildItem(Icons.qr_code_scanner_rounded, "Scan QR", () {
            _openQrScanner(context);
          }),
        ],
      ),
    );
  }

  void _openQrScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerView()),
    );
  }

  Widget _buildItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy,
            ),
          ),
        ],
      ),
    );
  }
}
