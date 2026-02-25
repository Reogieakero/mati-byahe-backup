import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_page.dart';
import 'widgets/onboarding_widgets.dart'; // Import destructured widgets
import '../login/login_screen.dart';
import '../login/widgets/login_widgets.dart'; // Import DotGridPainter

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _popController;

  final List<Map<String, String>> _onboardingData = [
    {
      'title': 'Discover Fair Fares Instantly',
      'description':
          'Scan any driver’s QR code to see real driver info, route, and official taripa fare.',
      'image': 'assets/images/onboarding1.jpg',
    },
    {
      'title': 'Ride with Confidence',
      'description':
          'Get digital receipts, track trips, rate drivers, and report issues.',
      'image': 'assets/images/onboarding2.jpg',
    },
    {
      'title': 'Ready to Travel Smarter?',
      'description':
          'Join commuters and drivers using Mati Byahe for fair, safe, and convenient rides.',
      'image': 'assets/images/onboarding3.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _popController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 400),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _popController.reset();
            if (_currentPage < _onboardingData.length - 1) {
              _currentPage++;
              _pageController.jumpToPage(_currentPage);
              setState(() {});
            } else {
              _completeOnboarding();
            }
          }
        });
  }

  @override
  void dispose() {
    _popController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _handleTap() =>
      !_popController.isAnimating ? _popController.forward() : null;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _onboardingData.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFF1F7FF),
                  Color(0xFFD7E9FF),
                ],
              ),
            ),
          ),
          // Dot Grid Pattern
          Positioned.fill(child: CustomPaint(painter: DotGridPainter())),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double imageBottom = constraints.maxHeight * 0.7;
                return Stack(
                  children: [
                    _buildPageView(),
                    OnboardingIndicator(
                      controller: _pageController,
                      topPosition: imageBottom - 40,
                      count: _onboardingData.length,
                    ),
                    if (isLastPage)
                      GetStartedButton(onPressed: _completeOnboarding),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _onboardingData.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedBuilder(
            animation: _popController,
            builder: (context, _) {
              if (index != _currentPage) return const SizedBox.shrink();
              return Opacity(
                opacity: Tween(begin: 1.0, end: 0.0).evaluate(_popController),
                child: Transform.scale(
                  scale: Tween(begin: 1.0, end: 1.5).evaluate(_popController),
                  child: Transform.rotate(
                    angle: Tween(
                      begin: 0.0,
                      end: 0.12,
                    ).evaluate(_popController),
                    child: OnboardingPage(
                      title: _onboardingData[index]['title']!,
                      description: _onboardingData[index]['description']!,
                      imagePath: _onboardingData[index]['image']!,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
