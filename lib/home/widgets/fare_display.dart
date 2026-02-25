import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';
import '../../core/constant/app_texts.dart';

class FareDisplay extends StatelessWidget {
  final double fare;
  final VoidCallback onArrived;
  final String buttonLabel;

  const FareDisplay({
    super.key,
    required this.fare,
    required this.onArrived,
    this.buttonLabel = 'Arrive',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Text(
          AppTexts.fareLabel.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.darkNavy.withOpacity(0.4),
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: onArrived,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(12),
                      elevation: 2,
                    ),
                    child: Icon(
                      buttonLabel == 'Arrive' ? Icons.check : Icons.local_taxi,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        AppTexts.currency,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryBlue.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      fare.toStringAsFixed(0),
                      style: const TextStyle(
                        fontFamily: 'Unbound',
                        fontSize: 80,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryBlue,
                        letterSpacing: -4,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Container(
                  height: 3,
                  width: 35,
                  decoration: BoxDecoration(
                    color: AppColors.primaryYellow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 22,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Insured',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 35),
        Text(
          'Standard rates applied based on local guidelines.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
