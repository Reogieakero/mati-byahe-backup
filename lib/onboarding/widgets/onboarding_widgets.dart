import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingIndicator extends StatelessWidget {
  final PageController controller;
  final double topPosition;
  final int count;

  const OnboardingIndicator({
    super.key,
    required this.controller,
    required this.topPosition,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 32,
      top: topPosition,
      child: SmoothPageIndicator(
        controller: controller,
        count: count,
        effect: const ExpandingDotsEffect(
          dotHeight: 8,
          dotWidth: 8,
          spacing: 12,
          expansionFactor: 3,
          activeDotColor: Colors.black, // Darker to contrast the light gradient
          dotColor: Colors.black26,
        ),
      ),
    );
  }
}

class GetStartedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GetStartedButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 24,
      right: 24,
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Get Started',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
