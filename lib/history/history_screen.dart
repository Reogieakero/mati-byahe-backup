import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import 'widgets/history_header.dart';

class HistoryScreen extends StatefulWidget {
  final String email;
  const HistoryScreen({super.key, required this.email});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const HistoryHeader(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: LocalDatabase().getTrips(widget.email),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final trips = snapshot.data ?? [];

                if (trips.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(trip);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    DateTime date = DateTime.parse(trip['date']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.darkNavy.withOpacity(0.5),
                ),
              ),
              Text(
                "₱${(trip['fare'] as double).toStringAsFixed(2)}",
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          _buildRouteItem(Icons.circle, AppColors.primaryBlue, trip['pickup']),
          const SizedBox(height: 8),
          _buildRouteItem(
            Icons.location_on,
            Colors.redAccent,
            trip['drop_off'],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.darkNavy,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 50,
            color: AppColors.darkNavy.withOpacity(0.1),
          ),
          const SizedBox(height: 10),
          const Text(
            "No past trips found",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
