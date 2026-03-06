import 'package:flutter/material.dart';
import '../../../core/constant/app_colors.dart';

class ReasonSelector extends StatelessWidget {
  final String? selectedReason;
  final List<String> reasons;
  final ValueChanged<String> onSelected;

  const ReasonSelector({
    super.key,
    required this.selectedReason,
    required this.reasons,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SELECT REASON",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reasons.map((reason) {
            final isSelected = selectedReason == reason;
            return GestureDetector(
              onTap: () => onSelected(reason),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.redAccent.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.redAccent : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  reason,
                  style: TextStyle(
                    color: isSelected ? Colors.redAccent : AppColors.darkNavy,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
