import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';

class ActionGridWidget extends StatelessWidget {
  const ActionGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(Icons.campaign_rounded, "Report"),
          _buildItem(Icons.newspaper_rounded, "News"),
          _buildItem(Icons.analytics_rounded, "Track"),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.08),
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
    );
  }
}
