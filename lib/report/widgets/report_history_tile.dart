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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final DateTime date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onViewDetails,
      onLongPress: () => menuKey.currentState?.showButtonMenu(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.softWhite, width: 0.8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.report_problem_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (report['issue_type']?.toString() ?? "REPORT")
                            .toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.darkNavy,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _formatDate(report['reported_at']),
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report['description'] ?? "No details provided.",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkNavy.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "TRIP ID: ${report['trip_uuid'].toString().toUpperCase().substring(0, 8)}",
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textGrey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (report['evidence_path'] != null)
                        const Icon(
                          Icons.attach_file,
                          size: 12,
                          color: AppColors.textGrey,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              key: menuKey,
              icon: const Icon(
                Icons.more_vert,
                color: AppColors.textGrey,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'view') onViewDetails?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                _buildMenuItem(
                  value: 'view',
                  icon: Icons.visibility_outlined,
                  label: 'VIEW DETAILS',
                  color: AppColors.darkNavy,
                ),
                _buildMenuItem(
                  value: 'delete',
                  icon: Icons.delete_outline_rounded,
                  label: 'DELETE',
                  color: Colors.redAccent,
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
      height: 38,
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
