import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';
import '../../core/constant/app_texts.dart';

class PassengerNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const PassengerNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 75,
      notchMargin: 12.0,
      shape: const CircularNotchedRectangle(),
      color: Colors.white,
      elevation: 10,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_filled, AppTexts.navHome, 0),
          _navItem(Icons.history, AppTexts.navHistory, 1),
          const SizedBox(width: 48),
          _navItem(Icons.outlined_flag, AppTexts.navReport, 3),
          _navItem(Icons.person_outline, AppTexts.navProfile, 4),
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

class PassengerFloatingButton extends StatelessWidget {
  final Animation<double> animation;
  final VoidCallback onTap;

  const PassengerFloatingButton({
    super.key,
    required this.animation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: onTap,
              backgroundColor: AppColors.primaryBlue,
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        );
      },
    );
  }
}
