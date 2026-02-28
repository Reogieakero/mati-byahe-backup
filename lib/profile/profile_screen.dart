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
  final _supabase = Supabase.instance.client;

  String? _userName;
  String? _userPhone;
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
      final data = await _supabase
          .from('profiles')
          .select('full_name, phone_number')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _userName = data?['full_name'];
          _userPhone = data?['phone_number'];
          _isLoading = false;
        });
      }

      if (data != null) {
        await _localDb.updateUserProfile(
          id: user.id,
          name: _userName ?? "",
          phone: _userPhone ?? "",
        );
      }
    } catch (e) {
      final localData = await _localDb.getUserById(user.id);
      if (mounted) {
        setState(() {
          _userName = localData?['full_name'];
          _userPhone = localData?['phone_number'];
          _isLoading = false;
        });
      }
    }
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
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 30),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      ProfileHeader(
                        email: widget.email,
                        name: _userName ?? "Set your name",
                        role: widget.role,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionLabel("ACCOUNT OVERVIEW"),
                      _buildContentCard(
                        child: ProfileMenuItem(
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
