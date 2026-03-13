import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constant/app_colors.dart';

class ReportHistoryTile extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  final GlobalKey<PopupMenuButtonState<String>> menuKey = GlobalKey();

  ReportHistoryTile({
    super.key,
    required this.report,
    this.onDelete,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime date =
        DateTime.tryParse(report['reported_at'] ?? '') ?? DateTime.now();

    // These now come from the JOIN query
    final String pickup = report['pickup'] ?? "Unknown Location";
    final String dropOff = report['drop_off'] ?? "Unknown Destination";
    final String issueType = (report['issue_type']?.toString() ?? "REPORT")
        .toUpperCase();

    return InkWell(
      onTap: onViewDetails,
      onLongPress: () => menuKey.currentState?.showButtonMenu(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Same Date formatting as Trip Tile
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textGrey.withOpacity(0.7),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Same Location formatting as Trip Tile
                  Text(
                    "$pickup → $dropOff",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Metadata subtext (Issue Type)
                  Text(
                    issueType,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent.withOpacity(0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Right-side Status Icon and Menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Icon(
                  Icons.report_problem_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 2),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: PopupMenuButton<String>(
                    key: menuKey,
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: AppColors.textGrey,
                    ),
                    onSelected: (value) {
                      if (value == 'view') onViewDetails?.call();
                      if (value == 'unreport') onDelete?.call();
                    },
                    itemBuilder: (context) {
                      final items = <PopupMenuItem<String>>[
                        _buildMenuItem(
                          value: 'view',
                          icon: Icons.visibility_outlined,
                          label: 'VIEW DETAILS',
                          color: AppColors.darkNavy,
                        ),
                      ];

                      if (onDelete != null) {
                        items.add(
                          _buildMenuItem(
                            value: 'unreport',
                            icon: Icons.undo_rounded,
                            label: 'UNREPORT',
                            color: Colors.redAccent,
                          ),
                        );
                      }

                      return items;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
