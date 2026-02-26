import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../report/report_history_screen.dart';
import '../core/constant/app_texts.dart';

class NavigationScreens {
  static List<Widget> getScreens(String email, String role) {
    final bool isDriver = role.toLowerCase() == 'driver';

    if (isDriver) {
      return [
        HomeScreen(email: email, role: role),
        _placeholder(AppTexts.navEarnings),
        _placeholder(AppTexts.navVehicle),
        _placeholder("REPORTS"), // Added to ensure list length is 5
        ProfileScreen(email: email, role: role),
      ];
    }

    return [
      HomeScreen(email: email, role: role),
      HistoryScreen(email: email),
      _placeholder("SCANNER"),
      const ReportHistoryScreen(),
      ProfileScreen(email: email, role: role),
    ];
  }

  static Widget _placeholder(String text) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
