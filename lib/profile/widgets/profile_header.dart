import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String email;
  final String? name;
  final String role;
  final double scrollOffset;

  const ProfileHeader({
    super.key,
    required this.email,
    this.name,
    required this.role,
    this.scrollOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    bool isScrolled = scrollOffset > 50;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.fromLTRB(16, isScrolled ? 50 : 20, 16, 20),
      decoration: BoxDecoration(
        color: isScrolled ? Colors.white : Colors.transparent,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  width: isScrolled ? 1 : 2,
                ),
              ),
              child: CircleAvatar(
                radius: isScrolled ? 30 : 50,
                backgroundColor: AppColors.primaryBlue,
                child: Icon(
                  Icons.person_rounded,
                  size: isScrolled ? 35 : 55,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            (name == null || name!.isEmpty) ? email : name!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isScrolled ? 16 : 20,
              fontWeight: FontWeight.w800,
              color: AppColors.darkNavy,
            ),
          ),
          if (!isScrolled && name != null && name!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                email,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGrey.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (!isScrolled) const SizedBox(height: 12),
          if (!isScrolled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
