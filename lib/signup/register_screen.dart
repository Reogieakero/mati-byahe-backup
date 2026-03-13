import 'package:flutter/material.dart';
import '../core/constant/app_colors.dart';
import '../login/widgets/login_widgets.dart';
import 'widgets/sign_up_widgets.dart';
import 'widgets/signup_background.dart';
import 'data/signup_repository.dart';
import 'verification_screen.dart';
import '../core/widgets/sileo_notification.dart';

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
  bool _isLoading = false;
  bool _isPasswordTouched = false;
  bool _isConfirmTouched = false;

  // This is just the INITIAL value for the UI
  String _userRole = 'Passenger';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onConfirmChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _confirmPasswordController.removeListener(_onConfirmChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    if (!_isPasswordTouched && _passwordController.text.isNotEmpty) {
      setState(() => _isPasswordTouched = true);
    } else {
      setState(() {});
    }
  }

  void _onConfirmChanged() {
    if (!_isConfirmTouched && _confirmPasswordController.text.isNotEmpty) {
      setState(() => _isConfirmTouched = true);
    } else {
      setState(() {});
    }
  }

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasSpecial =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text);

  bool get _isPasswordValid =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecial;

  bool get _isConfirmMatched =>
      _confirmPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text == _passwordController.text;

  bool get _shouldShowPasswordValidation =>
      (_isPasswordTouched || _isConfirmTouched) && !_isPasswordValid;

  void _showNotification(String message, {bool isError = false}) {
    SileoNotification.show(
      context,
      message,
      type: isError ? SileoNoticeType.error : SileoNoticeType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const SignupBackground(),
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
          const SignupHeader(),
          const SizedBox(height: 20),
          RoleSelector(
            selectedRole: _userRole,
            onRoleSelected: (role) {
              setState(() {
                _userRole = role;
              });
            },
          ),
          const SizedBox(height: 20),
          LoginInput(controller: _emailController, label: 'Email Address'),
          const SizedBox(height: 14),
          LoginInput(
            controller: _passwordController,
            label: 'Password',
            obscureText: !_isPasswordVisible,
            suffix: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          const SizedBox(height: 10),
          _buildPasswordValidation(context),
          SizedBox(height: _shouldShowPasswordValidation ? 14 : 8),
          LoginInput(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            obscureText: !_isConfirmPasswordVisible,
            suffix: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
              ),
            ),
          ),
          if (_isConfirmTouched)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    _isConfirmMatched
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 16,
                    color: _isConfirmMatched ? Colors.green : Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isConfirmMatched
                        ? 'Passwords match'
                        : 'Passwords do not match',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isConfirmMatched
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 22),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                )
              : PrimaryButton(
                  label: 'Register Account',
                  onPressed: () async {
                    final String selectedRole = _userRole;
                    final String email = _emailController.text.trim();
                    final String password = _passwordController.text;

                    if (email.isEmpty || password.isEmpty) {
                      _showNotification(
                        'Please enter email and password',
                        isError: true,
                      );
                      return;
                    }

                    if (!_isPasswordValid) {
                      _showNotification(
                        'Password does not meet the required rules',
                        isError: true,
                      );
                      return;
                    }

                    if (password != _confirmPasswordController.text) {
                      _showNotification(
                        'Passwords do not match',
                        isError: true,
                      );
                      return;
                    }

                    setState(() => _isLoading = true);

                    try {
                      await _repository.registerUser(
                        email,
                        password,
                        selectedRole,
                      );

                      if (!mounted) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VerificationScreen(email: email),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _isLoading = false);
                      _showNotification(e.toString(), isError: true);
                    }
                  },
                ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already have an account? ',
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
        ],
      ),
    );
  }

  Widget _buildPasswordValidation(BuildContext context) {
    final bool show = _isPasswordTouched || _isConfirmTouched;
    if (!show) return const SizedBox.shrink();

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 280),
      firstCurve: Curves.easeOut,
      secondCurve: Curves.easeIn,
      sizeCurve: Curves.easeInOut,
      crossFadeState: _shouldShowPasswordValidation
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pendingRuleItem('At least 8 characters', _hasMinLength),
            _pendingRuleItem('At least 1 uppercase letter', _hasUppercase),
            _pendingRuleItem('At least 1 lowercase letter', _hasLowercase),
            _pendingRuleItem('At least 1 number', _hasNumber),
            _pendingRuleItem('At least 1 special character', _hasSpecial),
          ],
        ),
      ),
      secondChild: const SizedBox.shrink(),
    );
  }

  Widget _pendingRuleItem(String label, bool passed) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: passed
          ? const SizedBox.shrink()
          : Padding(
              key: ValueKey(label),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.radio_button_unchecked,
                    size: 15,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
