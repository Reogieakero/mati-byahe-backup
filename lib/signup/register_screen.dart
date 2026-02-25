import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import '../login/widgets/login_widgets.dart';
import 'widgets/sign_up_widgets.dart';
import 'widgets/signup_background.dart';
import 'data/signup_repository.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final SignupRepository _repository = SignupRepository();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String _userRole = 'Passenger';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = false}) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const SignupBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const SignupHeader(),
                  const SizedBox(height: 40),
                  RoleSelector(
                    selectedRole: _userRole,
                    onRoleSelected: (role) => setState(() => _userRole = role),
                  ),
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 20),
                  LoginInput(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    obscureText: !_isConfirmPasswordVisible,
                    suffix: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: AppColors.primaryBlue.withOpacity(0.5),
                      ),
                      onPressed: () => setState(
                        () => _isConfirmPasswordVisible =
                            !_isConfirmPasswordVisible,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    label: 'Register Account',
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text;
                      if (password != _confirmPasswordController.text) {
                        _showNotification(
                          "Passwords do not match",
                          isError: true,
                        );
                        return;
                      }
                      try {
                        await _repository.registerUser(
                          email,
                          password,
                          _userRole,
                        );
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VerificationScreen(email: email),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        String msg = e.toString().replaceAll("Exception: ", "");
                        bool isOfflineSuccess = msg.contains("Offline");

                        _showNotification(msg, isError: !isOfflineSuccess);

                        if (isOfflineSuccess) {
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) Navigator.pop(context);
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Have an account already? ",
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'Digital Solutions You Can Trust.',
                    style: TextStyle(
                      color: AppColors.darkNavy,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
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
}
