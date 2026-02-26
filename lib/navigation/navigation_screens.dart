import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../report/report_history_screen.dart'; //
import '../core/constant/app_texts.dart';

class NavigationScreens {
  static List<Widget> getScreens(String email, String role) {
    bool isDriver = role.toLowerCase() == 'driver';

    if (isDriver) {
      return [
        HomeScreen(email: email, role: role),
        _placeholder(AppTexts.navEarnings),
        _placeholder(AppTexts.navVehicle),
        ProfileScreen(email: email, role: role),
      ];
    }

    return [
      HomeScreen(email: email, role: role),
      HistoryScreen(email: email),
      _placeholder("Scanner"),
      const ReportHistoryScreen(), // Replaced placeholder with actual screen
      ProfileScreen(email: email, role: role),
    ];
  }

  static Widget _placeholder(String text) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text(text)),
    );
  }
}
