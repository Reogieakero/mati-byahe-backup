import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String email;
  final String? name;
  final String role;

  const ProfileHeader({
    super.key,
    required this.email,
    this.name,
    required this.role,
  });

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
          (name == null || name!.isEmpty) ? email : name!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.darkNavy,
          ),
        ),
        if (name != null && name!.isNotEmpty)
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
        const SizedBox(height: 12),
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
    );
  }
}
