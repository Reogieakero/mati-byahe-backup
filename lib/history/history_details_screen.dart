import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constant/app_colors.dart';
import 'widgets/details/route_card.dart';
import 'widgets/details/detail_row.dart';
import 'widgets/details/report_button.dart';

class HistoryDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  const HistoryDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final DateTime date =
        DateTime.tryParse(trip['date'] ?? '') ?? DateTime.now();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryYellow.withOpacity(0.2),
              Colors.white,
              AppColors.primaryYellow.withOpacity(0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("ROUTE INFORMATION"),
                    const SizedBox(height: 16),
                    RouteCard(
                      pickup: trip['pickup'] ?? "Unknown",
                      dropOff:
                          (trip['drop_off']?.toString().isNotEmpty ?? false)
                          ? trip['drop_off']
                          : "---",
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader("PAYMENT & FARE"),
                    const SizedBox(height: 12),
                    DetailRow(
                      label: "Total Fare",
                      value: "₱${trip['fare']}",
                      isBold: true,
                    ),
                    DetailRow(
                      label: "Gas Tier",
                      value:
                          trip['gas_tier']?.toString().toUpperCase() ?? "N/A",
                    ),
                    const Divider(height: 32, color: AppColors.softWhite),
                    _buildSectionHeader("TIME LOGS"),
                    const SizedBox(height: 12),
                    DetailRow(
                      label: "Date",
                      value: DateFormat('MMMM dd, yyyy').format(date),
                    ),
                    DetailRow(
                      label: "Pickup Time",
                      value: trip['start_time'] ?? "--:--",
                    ),
                    DetailRow(
                      label: "Drop-off Time",
                      value: trip['end_time'] ?? "--:--",
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader("PARTICIPANTS"),
                    const SizedBox(height: 12),
                    DetailRow(
                      label: "Driver Name",
                      value:
                          trip['driver_name']?.toString().toUpperCase() ??
                          "N/A",
                      isBold: true,
                    ),
                    DetailRow(
                      label: "Plate Number",
                      value: trip['driver_plate'] ?? trip['driver_id'] ?? "N/A",
                    ),
                    DetailRow(
                      label: "Passenger ID",
                      value: trip['passenger_id'] ?? "N/A",
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ReportButton(trip: trip),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        "TRIP DETAILS",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: AppColors.darkNavy,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.darkNavy,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
  }
}
