import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constant/app_colors.dart';
import '../../core/database/local_database.dart';

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
        DateTime.tryParse(trip['start_time'] ?? '') ?? DateTime.now();
    final double fare = (trip['fare'] as num?)?.toDouble() ?? 0.0;
    final String pickup = trip['pickup'] ?? "Pickup";
    final String dropOff = trip['drop_off'] ?? "Destination";

    return InkWell(
      onTap: onViewDetails,
      onLongPress: () => menuKey.currentState?.showButtonMenu(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
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
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₱${fare.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.darkNavy,
                      ),
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
          FutureBuilder<bool>(
            future: LocalDatabase().isTripReported(trip['uuid']),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return IgnorePointer(
                  child: Transform.rotate(
                    angle: -0.15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.6),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "REPORTED",
                        style: TextStyle(
                          color: Colors.redAccent.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
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
