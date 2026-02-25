import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';
import '../../login/widgets/login_widgets.dart';

class SignupBackground extends StatelessWidget {
  const SignupBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
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
        ),
        Positioned.fill(child: CustomPaint(painter: DotGridPainter())),
      ],
    );
  }
}
