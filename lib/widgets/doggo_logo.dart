import 'package:flutter/material.dart';

class DogGoLogo extends StatelessWidget {
  final double size;

  const DogGoLogo({
    super.key,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_doggo.png',
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🐕',
              style: TextStyle(fontSize: size * 0.65),
            ),
            const SizedBox(width: 4),
            Text(
              'DogGo',
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF202033),
              ),
            ),
          ],
        );
      },
    );
  }
}