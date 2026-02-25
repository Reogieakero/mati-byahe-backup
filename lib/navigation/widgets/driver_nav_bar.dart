import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';
import '../../core/constant/app_texts.dart';

class DriverNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const DriverNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onTap,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.darkNavy.withOpacity(0.3),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: AppTexts.navHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: AppTexts.navEarnings,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.minor_crash_rounded),
            label: AppTexts.navVehicle,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: AppTexts.navProfile,
          ),
        ],
      ),
    );
  }
}
