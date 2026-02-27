import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String email;

  const ProfileHeader({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primaryBlue,
              child: Icon(Icons.person_rounded, size: 55, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          email,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.darkNavy,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Text(
            "PASSENGER",
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
