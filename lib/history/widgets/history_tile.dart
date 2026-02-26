import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constant/app_colors.dart';

class HistoryTile extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool isDriver;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;

  final GlobalKey<PopupMenuButtonState<String>> menuKey = GlobalKey();

  HistoryTile({
    super.key,
    required this.trip,
    this.isDriver = false,
    this.onDelete,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime date =
        DateTime.tryParse(trip['date'] ?? '') ?? DateTime.now();
    final double fare = (trip['fare'] as num?)?.toDouble() ?? 0.0;
    final String pickup = trip['pickup'] ?? "Pickup";
    final String dropOff = trip['drop_off'] ?? "Destination";

    return InkWell(
      onTap: onViewDetails,
      onLongPress: () => menuKey.currentState?.showButtonMenu(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(color: AppColors.softWhite, width: 0.8),
          ),
        ),
        child: Row(
          children: [
            Column(
              children: [
                const Icon(Icons.circle, size: 8, color: AppColors.primaryBlue),
                Container(
                  width: 1,
                  height: 12,
                  color: AppColors.textGrey.withOpacity(0.3),
                ),
                const Icon(
                  Icons.location_on,
                  size: 10,
                  color: Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pickup,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dropOff,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd • hh:mm a').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textGrey.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${isDriver ? '+' : '-'} ₱${fare.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isDriver ? Colors.green[700] : AppColors.darkNavy,
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    useMaterial3: true,
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    key: menuKey,
                    padding: EdgeInsets.zero,
                    elevation: 4,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    icon: const Icon(
                      Icons.more_horiz,
                      color: AppColors.textGrey,
                      size: 20,
                    ),
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
