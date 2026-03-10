import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';

class DriverDetailsView extends StatelessWidget {
  final Map<String, dynamic> driverData;

  const DriverDetailsView({super.key, required this.driverData});

  @override
  Widget build(BuildContext context) {
    final String name = driverData['name']?.toString() ?? 'Unknown Driver';
    final String plate = driverData['plate']?.toString() ?? 'No Plate Info';
    final String vehicle = driverData['type']?.toString() ?? 'Vehicle';
    final String color = driverData['color']?.toString() ?? 'Not Specified';
    final String photoUrl = driverData['avatar']?.toString() ?? '';

    final ignoredKeys = ['name', 'plate', 'type', 'color', 'avatar', 'id'];

    final otherData = driverData.entries
        .where((entry) => !ignoredKeys.contains(entry.key.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.darkNavy,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "IDENTIFICATION",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.darkNavy,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.darkNavy.withValues(alpha: 0.02),
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.darkNavy.withValues(alpha: 0.1),
                    backgroundImage: photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                    child: photoUrl.isEmpty
                        ? const Icon(
                            Icons.person_outline,
                            size: 40,
                            color: AppColors.darkNavy,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkNavy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "VERIFIED OPERATOR",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  _buildModernRow("Plate Number", plate, Icons.tag),
                  _buildDivider(),
                  _buildModernRow(
                    "Vehicle Type",
                    vehicle,
                    Icons.local_taxi_outlined,
                  ),
                  _buildDivider(),
                  _buildModernRow("Color", color, Icons.palette_outlined),
                  if (otherData.isNotEmpty) ...[
                    const SizedBox(height: 30),
                    const Text(
                      "CREDENTIALS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: otherData.length,
                        separatorBuilder: (context, index) => _buildDivider(),
                        itemBuilder: (context, index) {
                          final entry = otherData[index];
                          return _buildModernRow(
                            entry.key.toUpperCase().replaceAll('_', ' '),
                            entry.value.toString(),
                            Icons.info_outline,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.darkNavy.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.withValues(alpha: 0.1),
      thickness: 1,
      height: 1,
    );
  }
}
