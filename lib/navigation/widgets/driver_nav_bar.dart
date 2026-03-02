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
    return BottomAppBar(
      height: 75,
      color: Colors.white,
      elevation: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, AppTexts.navHome, 0), // Same as Passenger
          _navItem(
            Icons.account_balance_wallet_rounded,
            AppTexts.navEarnings,
            1,
          ),
          _navItem(Icons.minor_crash_rounded, AppTexts.navVehicle, 2),
          _navItem(
            Icons.person_outline,
            AppTexts.navProfile,
            3,
          ), // Same as Passenger
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.darkNavy.withOpacity(0.3),
              size: 24,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.darkNavy.withOpacity(0.3),
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 1),
                height: 2,
                width: 12,
                decoration: BoxDecoration(
                  color: AppColors.primaryYellow,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            else
              const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }
}
