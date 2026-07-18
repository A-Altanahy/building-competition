import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const ink = Color(0xFF071A1A);
  static const canvas = Color(0xFF0B2423);
  static const surface = Color(0xFF102F2D);
  static const surfaceRaised = Color(0xFF17403D);
  static const border = Color(0xFF285451);
  static const text = Color(0xFFF4F8F4);
  static const muted = Color(0xFFA9C2BA);
  static const quiet = Color(0xFF78958D);
  static const teal = Color(0xFF2DD4BF);
  static const cyan = Color(0xFF5ED8E5);
  static const gold = Color(0xFFF6C453);
  static const coral = Color(0xFFF4776C);
  static const green = Color(0xFF55D69A);
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.cairoTextTheme(
    base.textTheme,
  ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: textTheme,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.teal,
      onPrimary: AppColors.ink,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.coral,
      onError: AppColors.text,
    ),
    dividerColor: AppColors.border,
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.ink,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
    ),
  );
}

TextStyle appTextStyle({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = AppColors.text,
}) {
  return GoogleFonts.cairo(fontSize: size, fontWeight: weight, color: color);
}

BoxDecoration panelDecoration({Color? color, Color? borderColor}) {
  return BoxDecoration(
    color: color ?? AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: borderColor ?? AppColors.border),
  );
}
