import 'package:flutter/material.dart';

class LocationInputField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const LocationInputField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          floatingLabelBehavior: hasValue
              ? FloatingLabelBehavior.always
              : FloatingLabelBehavior.never,
          prefixIcon: Icon(icon, color: iconColor, size: 16),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: const Color(0xFF2196F3).withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2196F3)),
          ),
        ),
        child: Text(
          hasValue ? value! : label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: hasValue ? FontWeight.w700 : FontWeight.w400,
            color: hasValue ? Colors.black : Colors.grey.shade500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
