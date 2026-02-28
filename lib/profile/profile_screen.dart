import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import '../core/services/auth_service.dart';
import '../login/login_screen.dart';
import '../components/confirmation_dialog.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_menu_item.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  final String role;

  const ProfileScreen({super.key, required this.email, required this.role});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalDatabase _localDb = LocalDatabase();
  final AuthService _authService = AuthService();
  String? _userName;
  String? _userPhone;
  String? _lastUpdate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final String? userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      final userData = await _localDb.getUserById(userId);
      if (mounted) {
        setState(() {
          _userName = userData?['full_name'];
          _userPhone = userData?['phone_number'];
          _lastUpdate = userData?['last_profile_update'];
          _isLoading = false;
        });
      }
    }
  }

  bool _canEdit() {
    if (_lastUpdate == null || _lastUpdate!.isEmpty) return true;
    final lastDate = DateTime.parse(_lastUpdate!);
    return DateTime.now().difference(lastDate).inDays >= 14;
  }

  int _daysRemaining() {
    if (_lastUpdate == null) return 0;
    final lastDate = DateTime.parse(_lastUpdate!);
    int diff = DateTime.now().difference(lastDate).inDays;
    return 14 - diff;
  }

  void _showCooldownDialog() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Profile Locked",
        content:
            "To maintain security, profile changes are allowed once every 14 days. You can update your profile again in ${_daysRemaining()} days.",
        confirmText: "Understood",
        onConfirm: () {},
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Logout",
        content: "Are you sure you want to log out of your account?",
        confirmText: "Logout",
        onConfirm: () async {
          await _authService.signOut();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FB),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          _buildGradientBackground(),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverPadding(
                  // SET TO 15 PIXELS GUTTER
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      ProfileHeader(
                        email: widget.email,
                        name: _userName,
                        role: widget.role,
                      ),
                      const SizedBox(height: 32),

                      _buildSectionLabel("ACCOUNT OVERVIEW"),
                      _buildContentCard(
                        child: ProfileMenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profile',
                          onTap: () async {
                            if (!_canEdit()) {
                              _showCooldownDialog();
                              return;
                            }
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  initialName: _userName ?? "",
                                  initialEmail: widget.email,
                                  initialPhone: _userPhone ?? "",
                                ),
                              ),
                            );
                            if (result == true) _fetchUserData();
                          },
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildSectionLabel("SUPPORT & LEGAL"),
                      _buildContentCard(
                        child: Column(
                          children: [
                            ProfileMenuItem(
                              icon: Icons.help_outline_rounded,
                              title: 'Help Center',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            ProfileMenuItem(
                              icon: Icons.gavel_rounded,
                              title: 'Legal & Privacy',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            ProfileMenuItem(
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              titleColor: Colors.redAccent,
                              iconColor: Colors.redAccent,
                              onTap: _handleLogout,
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

  Widget _buildGradientBackground() => Positioned.fill(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primaryBlue.withOpacity(0.12),
            const Color(0xFFF8F9FB),
          ],
          stops: const [0.0, 0.4],
        ),
      ),
    ),
  );

  Widget _buildSliverAppBar() => const SliverAppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    pinned: true,
    centerTitle: true,
    automaticallyImplyLeading: false,
    title: Text(
      "MY ACCOUNT",
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        color: AppColors.darkNavy,
      ),
    ),
  );

  Widget _buildSectionLabel(String title) => Padding(
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

  Widget _buildContentCard({required Widget child}) => Container(
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

  Widget _buildDivider() => Divider(
    height: 1,
    color: Colors.grey.withOpacity(0.08),
    indent: 56,
    endIndent: 16,
  );
}
