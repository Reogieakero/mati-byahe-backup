import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constant/app_colors.dart';
import 'widgets/details/trip_info_card.dart';
import 'widgets/details/payment_info_card.dart';
import 'widgets/details/report_button.dart';

class HistoryDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> trip;

  const HistoryDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final DateTime date =
        DateTime.tryParse(trip['date'] ?? '') ?? DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(date),
              const SizedBox(height: 24),
              const _SectionLabel(label: "Trip Logistics"),
              const SizedBox(height: 8),
              TripInfoCard(trip: trip),
              const SizedBox(height: 24),
              const _SectionLabel(label: "Payment & Personnel"),
              const SizedBox(height: 8),
              PaymentInfoCard(trip: trip),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ReportButton(trip: trip),
    );
  }

  Widget _buildStatusHeader(DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Trip Summary",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Completed on ${DateFormat('MMMM dd, yyyy').format(date)}",
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.darkNavy, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "TRIP-ID-8291",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: Colors.grey.shade500,
      ),
    );
  }
}
