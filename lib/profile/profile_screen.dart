import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import '../core/services/auth_service.dart';
import '../login/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String email;
  final String role;

  const ProfileScreen({super.key, required this.email, required this.role});

  static const Color backgroundColor = Color(0xFFF8F9FB);

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
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.12),
                    backgroundColor,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildProfileHeader(),
                      const SizedBox(height: 32),
                      _buildSectionLabel("ACCOUNT OVERVIEW"),
                      _buildContentCard(
                        child: Column(
                          children: [
                            _buildProfileOption(
                              icon: Icons.settings_suggest_rounded,
                              title: 'Settings',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionLabel("PREFERENCES & SUPPORT"),
                      _buildContentCard(
                        child: Column(
                          children: [
                            _buildProfileOption(
                              icon: Icons.help_outline_rounded,
                              title: 'Help Center',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildProfileOption(
                              icon: Icons.info_outline_rounded,
                              title: 'Legal & Privacy',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _buildProfileOption(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              titleColor: Colors.redAccent,
                              iconColor: Colors.redAccent,
                              onTap: () => _handleLogout(context),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text(
        "MY ACCOUNT",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          color: AppColors.darkNavy,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
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

  Widget _buildSectionLabel(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
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
      ),
    );
  }

  Widget _buildContentCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primaryBlue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: iconColor ?? AppColors.primaryBlue),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? AppColors.darkNavy,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textGrey,
        size: 20,
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
