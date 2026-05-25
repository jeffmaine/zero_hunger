import 'package:flutter/material.dart';

// Primary green scale (uiux.md §3.8)
const Color green50 = Color(0xFFF1F8F4);
const Color green100 = Color(0xFFD8EDE3);
const Color green200 = Color(0xFFB7DFC9);
const Color green500 = Color(0xFF2D6A4F);
const Color green700 = Color(0xFF1B4332);

const Color gray100 = Color(0xFFF1F3EF);
const Color gray300 = Color(0xFFD7DBD2);
const Color gray500 = Color(0xFF6B7280);
const Color gray700 = Color(0xFF374151);

const Color kBackground = Color(0xFFF5F7F2);
const Color kSurface = Color(0xFFFFFFFF);
const Color kAccent = Color(0xFFE07B00);
const Color kError = Color(0xFFC1121F);
const Color kErrorBg = Color(0xFFFDECEA);
const Color kErrorText = Color(0xFFB33A3A);
const Color kSearchFill = Color(0xFFE8EFE6);
const Color kTextPrimary = Color(0xFF1A3D2B);
const Color kTextSecondary = Color(0xFF5A7A66);
const Color kTextDisabled = Color(0xFF9AB5A3);
const Color kBorder = Color(0xFFD0DECA);

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: green500,
      primary: green500,
      onPrimary: Colors.white,
      primaryContainer: green100,
      surface: kSurface,
      onSurface: kTextPrimary,
      onSurfaceVariant: gray500,
      error: kError,
    ),
    scaffoldBackgroundColor: kBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBackground,
      foregroundColor: kTextPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: kTextPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: green500, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: kErrorText),
      ),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: kTextSecondary,
      ),
      hintStyle: const TextStyle(color: kTextDisabled, fontSize: 16),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: kTextPrimary,
        height: 1.2,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: kTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: kTextPrimary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: kTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: kTextDisabled,
        letterSpacing: 0.5,
      ),
    ),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 0.5),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: green700,
    ),
  );
  return base;
}
