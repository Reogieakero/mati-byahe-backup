import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';

class DriverDetailsView extends StatelessWidget {
  final Map<String, dynamic> driverData;

  const DriverDetailsView({super.key, required this.driverData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "DRIVER DETAILS",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: AppColors.darkNavy,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFF0F2F5),
                  child: Icon(
                    Icons.person_rounded,
                    size: 60,
                    color: AppColors.darkNavy,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  (driverData['name'] ?? "UNKNOWN").toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkNavy,
                  ),
                ),
                const Text(
                  "Verified Driver",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoTile(
                  Icons.directions_car_filled_outlined,
                  "Vehicle Type",
                  driverData['type'],
                ),
                _buildInfoTile(
                  Icons.numbers_rounded,
                  "Plate Number",
                  driverData['plate'],
                ),
                _buildInfoTile(
                  Icons.color_lens_outlined,
                  "Vehicle Color",
                  driverData['color'],
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "CONFIRM RIDE",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
              ),
              Text(
                value ?? "N/A",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
