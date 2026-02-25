import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constant/app_colors.dart';

class HistoryTile extends StatelessWidget {
  final Map<String, dynamic> trip;

  const HistoryTile({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    DateTime date = DateTime.tryParse(trip['date'] ?? '') ?? DateTime.now();
    double fare = (trip['fare'] as num?)?.toDouble() ?? 0.0;
    String pickup = trip['pickup'] ?? "Unknown";
    String dropOff = trip['drop_off'] ?? "Unknown";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        // Removed white color and border to show the screen gradient
        color: Colors.transparent,
        border: Border(
          // Using a subtle navy with low opacity for the divider
          bottom: BorderSide(color: AppColors.softWhite, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_outlined,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$pickup ➔ $dropOff",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                "-₱${fare.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.more_horiz, color: AppColors.darkNavy, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
