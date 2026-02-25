import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import '../core/services/auth_service.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String email;
  final String role;

  const ProfileScreen({super.key, required this.email, required this.role});

  void _handleLogout(BuildContext context) async {
    final AuthService authService = AuthService();
    await authService.signOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkNavy,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: AppColors.primaryBlue,
                child: const CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              email,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Divider(thickness: 1, height: 1),
            _buildProfileOption(
              icon: Icons.history,
              title: role.toLowerCase() == 'driver'
                  ? 'Ride History'
                  : 'My Trips',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.help_outline,
              title: 'Support',
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.logout,
              title: 'Logout',
              titleColor: Colors.redAccent,
              iconColor: Colors.redAccent,
              onTap: () => _handleLogout(context),
            ),
            const Divider(thickness: 1, height: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.darkNavy),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppColors.darkNavy,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textGrey,
      ),
      onTap: onTap,
    );
  }
}
