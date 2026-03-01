import 'package:flutter/material.dart';

class MoonLogo extends StatelessWidget {
  const MoonLogo({super.key, this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.nightlight_round,
            size: size,
            color: Colors.white,
          ),
          Positioned(
            right: size * 0.05,
            top: size * 0.2,
            child: const Icon(
              Icons.auto_awesome,
              size: 13,
              color: Colors.white,
            ),
          ),
          Positioned(
            right: 0,
            bottom: size * 0.15,
            child: const Icon(
              Icons.star,
              size: 8,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
