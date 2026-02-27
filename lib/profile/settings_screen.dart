import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import 'widgets/profile_menu_item.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _locationServices = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Color(0xFFF8F9FB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.darkNavy,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "SETTINGS",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            color: AppColors.darkNavy,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("APP PREFERENCES"),
            _buildContentCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.notifications_active_rounded,
                    title: "Push Notifications",
                    value: _pushNotifications,
                    onChanged: (val) =>
                        setState(() => _pushNotifications = val),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.location_on_rounded,
                    title: "Location Services",
                    value: _locationServices,
                    onChanged: (val) => setState(() => _locationServices = val),
                  ),
                  _buildDivider(),
                  _buildSwitchTile(
                    icon: Icons.dark_mode_rounded,
                    title: "Dark Mode",
                    value: _darkMode,
                    onChanged: (val) => setState(() => _darkMode = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel("SECURITY"),
            _buildContentCard(
              child: Column(
                children: [
                  ProfileMenuItem(
                    icon: Icons.lock_reset_rounded,
                    title: "Change Password",
                    onTap: () {},
                  ),
                  _buildDivider(),
                  ProfileMenuItem(
                    icon: Icons.phonelink_lock_rounded,
                    title: "Two-Factor Auth",
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionLabel("DATA"),
            _buildContentCard(
              child: ProfileMenuItem(
                icon: Icons.delete_forever_rounded,
                title: "Delete Account",
                titleColor: Colors.redAccent,
                iconColor: Colors.redAccent,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.textGrey.withOpacity(0.7),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildContentCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryBlue),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.darkNavy,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppColors.primaryBlue,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() => Divider(
    height: 1,
    color: Colors.grey.withOpacity(0.08),
    indent: 56,
    endIndent: 16,
  );
}
