import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import '../core/constant/app_colors.dart';

class QRCodeScreen extends StatelessWidget {
  final Map<String, dynamic> driverData;

  const QRCodeScreen({super.key, required this.driverData});

  @override
  Widget build(BuildContext context) {
    final String qrContent = jsonEncode({
      'name': driverData['full_name'],
      'plate': driverData['plate_number'],
      'type': driverData['vehicle_type'],
      'color': driverData['vehicle_color'],
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "DRIVER QR ID",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: QrImageView(
                data: qrContent,
                version: QrVersions.auto,
                size: 250.0,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              driverData['full_name']?.toUpperCase() ?? "DRIVER",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Plate: ${driverData['plate_number'] ?? 'N/A'}",
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
