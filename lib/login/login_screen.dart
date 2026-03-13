import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import 'widgets/login_widgets.dart';
import '../signup/register_screen.dart';
import '../navigation/main_navigation.dart';
import '../core/services/auth_service.dart';
import '../core/models/user_model.dart';
import '../core/widgets/sileo_notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = true}) {
    SileoNotification.show(
      context,
      message,
      type: isError ? SileoNoticeType.error : SileoNoticeType.success,
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showNotification("Please enter both email and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(email, password);

      if (user != null) {
        _navigateToHome(user);
      } else {
        _showNotification("Invalid email or password.");
      }
    } catch (e) {
      _showNotification("An error occurred during login.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome(UserModel user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MainNavigation(email: user.email, role: user.role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _LoginBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAuthCard(context),
                            const SizedBox(height: 24),
                            const Text(
                              'Digital Solutions You Can Trust.',
                              style: TextStyle(
                                color: AppColors.darkNavy,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.darkNavy,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Log in to continue managing your trips and activities.',
            style: TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          LoginInput(controller: _emailController, label: 'Email Address'),
          const SizedBox(height: 14),
          LoginInput(
            controller: _passwordController,
            label: 'Password',
            obscureText: !_isPasswordVisible,
            suffix: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: AppColors.primaryBlue.withOpacity(0.5),
              ),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          const SizedBox(height: 22),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                )
              : PrimaryButton(label: 'Login', onPressed: _handleLogin),
          const SizedBox(height: 16),
          const LoginDivider(),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Continue as Guest',
            onPressed: () {},
            backgroundColor: AppColors.darkNavy,
          ),
          const SizedBox(height: 18),
          _buildRegisterPrompt(),
        ],
      ),
    );
  }

  Widget _buildRegisterPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have An Account? ",
          style: TextStyle(color: AppColors.textGrey),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterScreen()),
          ),
          child: const Text(
            'Register',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();
  @override
  Widget build(BuildContext context) {
    return Container(color: Theme.of(context).colorScheme.surface);
  }
}
