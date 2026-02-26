import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../core/constant/app_colors.dart';
import '../core/database/local_database.dart';
import 'data/signup_repository.dart';
import 'widgets/signup_background.dart';
import '../login/widgets/login_widgets.dart';
import '../navigation/main_navigation.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  final _repository = SignupRepository();
  final LocalDatabase _localDb = LocalDatabase();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
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

  Future<void> _verifyOTP() async {
    if (_codeController.text.length < 8) {
      _showNotification("Please enter the complete 8-digit code.");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        token: _codeController.text.trim(),
        type: OtpType.signup,
        email: widget.email,
      );

      await _repository.markAsVerified(widget.email);

      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showNotification("Invalid or expired code. Please try again.");
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Account Verified!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.darkNavy,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your account is now ready to use.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: 30),
            PrimaryButton(
              label: "Go to Home",
              onPressed: () async {
                final db = await _localDb.database;
                final List<Map<String, dynamic>> user = await db.query(
                  'users',
                  where: 'email = ?',
                  whereArgs: [widget.email],
                );

                String role = user.isNotEmpty
                    ? user.first['role']
                    : "Passenger";

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MainNavigation(email: widget.email, role: role),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const Icon(
                    Icons.security_outlined,
                    size: 90,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Verification Required",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Please enter the 8-digit secure token\nsent to ${widget.email}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  PinCodeTextField(
                    appContext: context,
                    length: 8,
                    controller: _codeController,
                    animationType: AnimationType.fade,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 38,
                      activeColor: AppColors.primaryBlue,
                      inactiveColor: AppColors.primaryBlue.withOpacity(0.15),
                    ),
                    onCompleted: (v) => _verifyOTP(),
                    onChanged: (v) {},
                  ),
                  const SizedBox(height: 40),
                  _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        )
                      : PrimaryButton(
                          label: "Verify Token",
                          onPressed: _verifyOTP,
                        ),
                  const SizedBox(height: 30),
                  _buildResendSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        const Text(
          "Didn't receive the token?",
          style: TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await Supabase.instance.client.auth.resend(
                      type: OtpType.signup,
                      email: widget.email,
                    );
                    _showNotification(
                      "A new token has been sent.",
                      isError: false,
                    );
                  } catch (e) {
                    _showNotification(
                      "Failed to resend. Please try again later.",
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: const Text(
            "Resend Secure Code",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
