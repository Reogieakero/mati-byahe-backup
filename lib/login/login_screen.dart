import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import 'widgets/login_widgets.dart';
import '../signup/register_screen.dart';
import '../navigation/main_navigation.dart';
import '../core/services/auth_service.dart';
import '../core/models/user_model.dart';

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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
          Positioned.fill(child: CustomPaint(painter: DotGridPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  const Text(
                    'Hop In · Log In to Your\nByahe Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkNavy,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Access your rides. Track trips. Manage your travels.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 50),
                  LoginInput(
                    controller: _emailController,
                    label: 'Email Address',
                  ),
                  const SizedBox(height: 20),
                  LoginInput(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: !_isPasswordVisible,
                    suffix: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.primaryBlue.withOpacity(0.5),
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        )
                      : PrimaryButton(label: 'Login', onPressed: _handleLogin),
                  const SizedBox(height: 20),
                  const LoginDivider(),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Continue as Guest',
                    onPressed: () {},
                    backgroundColor: AppColors.darkNavy,
                  ),
                  const SizedBox(height: 32),
                  _buildRegisterPrompt(),
                  const SizedBox(height: 80),
                  const Text(
                    'Digital Solutions You Can Trust.',
                    style: TextStyle(
                      color: AppColors.darkNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgYellowStart,
            AppColors.bgYellowMid,
            AppColors.bgYellowEnd,
          ],
        ),
      ),
    );
  }
}
