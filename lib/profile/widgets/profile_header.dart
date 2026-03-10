import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String email;
  final String? name;
  final String role;
  final String? avatarUrl;

  const ProfileHeader({
    super.key,
    required this.email,
    this.name,
    required this.role,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 50, 10, 15),
          child: const Center(
            child: Text(
              'PROFILE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.darkNavy,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.primaryBlue,
              child: ClipOval(
                child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? Image.network(
                        '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          );
                        },
                      )
                    : const Icon(
                        Icons.person_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
              ),
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
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textGrey.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
