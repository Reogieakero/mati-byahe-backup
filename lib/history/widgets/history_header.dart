import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';

class HistoryHeader extends StatelessWidget {
  const HistoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 50, 10, 15),
      decoration: const BoxDecoration(color: Colors.white),
      child: const Center(
        child: Text(
          'HISTORY',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.darkNavy,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }
}
