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
import 'guide_screen.dart';
import 'legal_screen.dart';
import 'set_pin_screen.dart';
import 'qr_code_screen.dart';

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
  final _supabase = Supabase.instance.client;

  String? _userName;
  String? _userPhone;
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final localData = await _localDb.getUserById(user.id);
      if (localData != null) {
        setState(() {
          _userName = localData['full_name'];
          _userPhone = localData['phone_number'];
          _avatarUrl = localData['avatar_url'];
          _isLoading = false;
        });
      }

      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (mounted && data != null) {
        setState(() {
          _userName = data['full_name'];
          _userPhone = data['phone_number'];
          _avatarUrl = data['avatar_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: "Logout",
        content: "Are you sure you want to log out?",
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
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetchUserData,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(
                    email: widget.email,
                    name: _userName ?? "Set your name",
                    role: widget.role,
                    avatarUrl: _avatarUrl,
                  ),
                  const SizedBox(height: 25),
                  _buildSectionLabel("ACCOUNT SETTINGS"),
                  _buildShadcnCard(
                    child: Column(
                      children: [
                        ProfileMenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profile',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(
                                  initialName: _userName ?? "",
                                  initialEmail: widget.email,
                                  initialPhone: _userPhone ?? "",
                                  role: widget.role,
                                ),
                              ),
                            );
                            if (result == true) _fetchUserData();
                          },
                        ),
                        if (widget.role.toLowerCase() == 'driver') ...[
                          _buildDivider(),
                          ProfileMenuItem(
                            icon: Icons.qr_code_2_rounded,
                            title: 'My QR Code ID',
                            onTap: () async {
                              final userId = _supabase.auth.currentUser?.id;
                              if (userId != null) {
                                final data = await _localDb.getUserById(userId);
                                if (data != null && mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          QRCodeScreen(driverData: data),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                        _buildDivider(),
                        ProfileMenuItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Security PIN',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SetPinScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionItem(
                        icon: Icons.auto_stories_rounded,
                        label: "App Guide",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GuideScreen(role: widget.role),
                          ),
                        ),
                      ),
                      _buildActionItem(
                        icon: Icons.gavel_rounded,
                        label: "Legal",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LegalScreen(),
                          ),
                        ),
                      ),
                      _buildActionItem(
                        icon: Icons.logout_rounded,
                        label: "Logout",
                        color: Colors.redAccent,
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.primaryBlue,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkNavy.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.textGrey.withOpacity(0.5),
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildShadcnCard({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.softWhite, width: 1),
    ),
    child: child,
  );

  Widget _buildDivider() =>
      Divider(height: 1, color: AppColors.softWhite, indent: 50, endIndent: 16);
}
