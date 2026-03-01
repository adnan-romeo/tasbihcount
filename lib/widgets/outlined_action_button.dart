import 'package:flutter/material.dart';

class OutlinedActionButton extends StatelessWidget {
  const OutlinedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.textColor = Colors.white,
    this.filled = false,
    this.height = 62,
  });

  final String label;
  final VoidCallback onPressed;
  final Color textColor;
  final bool filled;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          backgroundColor: filled ? Colors.white : Colors.transparent,
          side: BorderSide(
            color: filled ? Colors.transparent : Colors.white,
            width: 1.8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.black : textColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
