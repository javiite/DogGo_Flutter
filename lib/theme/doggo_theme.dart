import 'package:flutter/material.dart';

class DogGoTheme {
  static const Color teal = Color(0xFF0B9F8A);
  static const Color tealLight = Color(0xFFE1F5F1);
  static const Color tealDark = Color(0xFF087566);

  static const Color cream = Color(0xFFF8F1E7);
  static const Color cream2 = Color(0xFFFFFBF5);
  static const Color card = Colors.white;

  static const Color ink = Color(0xFF242135);
  static const Color muted = Color(0xFF746F83);
  static const Color border = Color(0xFFE7DED3);

  static const Color orange = Color(0xFFF3A333);
  static const Color orangeLight = Color(0xFFFFF0D6);

  static const Color green = Color(0xFF22C55E);
  static const Color greenLight = Color(0xFFE7F9EE);

  static const Color red = Color(0xFFEF4444);
  static const Color redLight = Color(0xFFFEEEEE);

  static const Color purple = Color(0xFF7C5CBF);
  static const Color purpleLight = Color(0xFFF1ECFA);

  static List<BoxShadow> softShadow() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.055),
        blurRadius: 18,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static TextStyle title({
    double size = 26,
    Color color = ink,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      height: 1.08,
      letterSpacing: -0.6,
    );
  }

  static TextStyle subtitle({
    double size = 14,
    Color color = muted,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.35,
    );
  }

  static TextStyle label({
    double size = 12,
    Color color = teal,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      letterSpacing: 1,
    );
  }

  static TextStyle body({
    double size = 14,
    Color color = ink,
    FontWeight weight = FontWeight.w600,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.35,
    );
  }

  static ButtonStyle primaryButton() {
    return ElevatedButton.styleFrom(
      backgroundColor: teal,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 14,
      ),
    );
  }

  static ButtonStyle secondaryButton() {
    return OutlinedButton.styleFrom(
      foregroundColor: ink,
      side: const BorderSide(color: border),
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    );
  }
}