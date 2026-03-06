import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';

class DetailsInput extends StatelessWidget {
  final TextEditingController controller;
  const DetailsInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DETAILS",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(fontSize: 14, color: AppColors.darkNavy),
            decoration: InputDecoration(
              hintText: "What happened during the trip?",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              contentPadding: const EdgeInsets.all(15),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
