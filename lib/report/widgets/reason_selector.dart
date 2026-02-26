import 'package:flutter/material.dart';

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
        const Text(
          "REASON FOR REPORT",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.grey,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reasons.map((reason) {
            final isSelected = selectedReason == reason;
            return ChoiceChip(
              label: Text(reason),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onSelected(reason);
              },
              selectedColor: Colors.redAccent.withOpacity(0.2),
              backgroundColor: Colors.white.withOpacity(0.5),
              labelStyle: TextStyle(
                color: isSelected ? Colors.redAccent : Colors.black87,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? Colors.redAccent : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }
}
