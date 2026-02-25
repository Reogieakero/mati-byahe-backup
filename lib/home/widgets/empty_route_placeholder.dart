import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';

class EmptyRoutePlaceholder extends StatelessWidget {
  const EmptyRoutePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            size: 40,
            color: AppColors.darkNavy.withOpacity(0.1),
          ),
          const SizedBox(height: 12),
          Text(
            'No route selected',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.darkNavy.withOpacity(0.3),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select pick-up and drop-off to see fare',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.darkNavy.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}
