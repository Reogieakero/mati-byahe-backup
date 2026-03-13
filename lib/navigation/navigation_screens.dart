import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../qrscanner/qr_scanner_view.dart';
import '../profile/profile_screen.dart';
import '../report/report_history_screen.dart';
import '../other screens/driver_earnings_screen.dart';
import '../other screens/driver_vehicle_screen.dart';

class NavigationScreens {
  static List<Widget> getScreens(String email, String role) {
    final String normalizedRole = role.toLowerCase();

    if (normalizedRole == 'driver') {
      return [
        HomeScreen(email: email, role: role),
        const DriverEarningsScreen(),
        const DriverVehicleScreen(),
        ProfileScreen(email: email, role: role),
      ];
    }

    return [
      HomeScreen(email: email, role: role),
      HistoryScreen(email: email),
      const QrScannerView(),
      const ReportHistoryScreen(),
      ProfileScreen(email: email, role: role),
    ];
  }
}
