import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'doggo_radius.dart';

abstract final class DogGoTheme {
  static const Color teal = Color(0xFF006C5B);
  static const Color tealLight = Color(0xFFE8F3F0);
  static const Color tealDark = Color(0xFF075A4D);

  static const Color cream = Color(0xFFF9FAF8);
  static const Color cream2 = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color ink = Color(0xFF202232);
  static const Color muted = Color(0xFF70727D);
  static const Color border = Color(0xFFE4E8E6);

  static const Color orange = Color(0xFFF0A72E);
  static const Color orangeLight = Color(0xFFFFF4DF);

  static const Color green = Color(0xFF218B68);
  static const Color greenLight = Color(0xFFE7F4EE);

  static const Color red = Color(0xFFD85050);
  static const Color redLight = Color(0xFFFCECEC);

  static const Color purple = Color(0xFF5F6680);
  static const Color purpleLight = Color(0xFFF0F1F5);

  static const Color disabled = Color(0xFFB7BCBA);
  static const Color divider = Color(0xFFE9ECEA);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      primary: teal,
      onPrimary: Colors.white,
      secondary: tealDark,
      onSecondary: Colors.white,
      error: red,
      onError: Colors.white,
      surface: card,
      onSurface: ink,
    );

    final baseTextTheme = GoogleFonts.manropeTextTheme(
      ThemeData.light().textTheme,
    ).apply(bodyColor: ink, displayColor: ink);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: cream,
      canvasColor: cream,
      splashFactory: InkRipple.splashFactory,
      textTheme: baseTextTheme,
      dividerColor: border,
      disabledColor: disabled,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: card,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: ink, size: 23),
        titleTextStyle: title(size: 19, color: ink),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: card,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DogGoRadius.large),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: teal,
        linearTrackColor: tealLight,
        circularTrackColor: tealLight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: body(
          size: 13,
          color: Colors.white,
          weight: FontWeight.w600,
        ),
        actionTextColor: tealLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DogGoRadius.large),
        ),
        titleTextStyle: title(size: 22),
        contentTextStyle: subtitle(size: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        hintStyle: subtitle(size: 13.5),
        labelStyle: body(size: 13, color: muted, weight: FontWeight.w600),
        floatingLabelStyle: body(
          size: 13,
          color: teal,
          weight: FontWeight.w800,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
          borderSide: const BorderSide(color: teal, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
          borderSide: const BorderSide(color: red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DogGoRadius.medium),
          borderSide: const BorderSide(color: red, width: 1.6),
        ),
        errorStyle: body(size: 11.5, color: red, weight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton()),
      filledButtonTheme: FilledButtonThemeData(style: primaryButton()),
      outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButton()),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: teal,
          textStyle: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DogGoRadius.button),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return disabled;
          }

          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }

          return muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return border;
          }

          if (states.contains(WidgetState.selected)) {
            return green;
          }

          return purpleLight;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 76,
        backgroundColor: card,
        indicatorColor: tealLight,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return body(
            size: 10.5,
            color: states.contains(WidgetState.selected) ? teal : muted,
            weight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected) ? teal : muted,
          );
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.dark,
      primary: const Color(0xFF75D5C0),
      secondary: const Color(0xFFFFC864),
      surface: const Color(0xFF1B2321),
    );
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101715),
      canvasColor: const Color(0xFF101715),
      appBarTheme: lightTheme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF1B2321),
        foregroundColor: Colors.white,
      ),
      cardTheme: lightTheme.cardTheme.copyWith(color: const Color(0xFF1B2321)),
      dialogTheme: lightTheme.dialogTheme.copyWith(
        backgroundColor: const Color(0xFF1B2321),
      ),
      bottomSheetTheme: lightTheme.bottomSheetTheme.copyWith(
        backgroundColor: const Color(0xFF1B2321),
      ),
    );
  }

  static List<BoxShadow> softShadow({
    double opacity = .045,
    double blur = 22,
    Offset offset = const Offset(0, 9),
  }) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity),
        blurRadius: blur,
        offset: offset,
      ),
    ];
  }

  static List<BoxShadow> elevatedShadow() {
    return [
      BoxShadow(
        color: teal.withValues(alpha: .12),
        blurRadius: 30,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static TextStyle display({double size = 34, Color color = ink}) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.08,
      letterSpacing: -1,
    );
  }

  static TextStyle title({double size = 26, Color color = ink}) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.12,
      letterSpacing: -0.65,
    );
  }

  static TextStyle subtitle({double size = 14, Color color = muted}) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle label({double size = 12, Color color = teal}) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.2,
      letterSpacing: .9,
    );
  }

  static TextStyle body({
    double size = 14,
    Color color = ink,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.4,
    );
  }

  static TextStyle caption({
    double size = 11,
    Color color = muted,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.manrope(
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
      disabledBackgroundColor: disabled,
      disabledForegroundColor: Colors.white.withValues(alpha: .75),
      elevation: 0,
      minimumSize: const Size(double.infinity, 50),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DogGoRadius.button),
      ),
      textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 14),
    );
  }

  static ButtonStyle secondaryButton() {
    return OutlinedButton.styleFrom(
      foregroundColor: ink,
      disabledForegroundColor: disabled,
      side: const BorderSide(color: border),
      minimumSize: const Size(double.infinity, 50),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DogGoRadius.button),
      ),
      textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: 14),
    );
  }

  static Color walkStatusColor(String status) {
    final normalized = status
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');

    switch (normalized) {
      case 'pendiente':
      case 'pending':
        return orange;

      case 'aceptado':
      case 'accepted':
        return purple;

      case 'encurso':
      case 'inprogress':
      case 'activo':
        return teal;

      case 'finalizado':
      case 'completado':
      case 'completed':
        return green;

      case 'cancelado':
      case 'rechazado':
      case 'cancelled':
      case 'rejected':
        return red;

      default:
        return muted;
    }
  }

  static Color walkStatusBackground(String status) {
    final color = walkStatusColor(status);

    if (color == orange) {
      return orangeLight;
    }

    if (color == purple) {
      return purpleLight;
    }

    if (color == teal) {
      return tealLight;
    }

    if (color == green) {
      return greenLight;
    }

    if (color == red) {
      return redLight;
    }

    return purpleLight;
  }
}
