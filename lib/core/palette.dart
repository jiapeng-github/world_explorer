import 'package:flutter/material.dart';

abstract final class AtlasColors {
  static const background = Color(0xFFFAF7EE),
      forest = Color(0xFF286756),
      ink = Color(0xFF173F3D),
      ocean = Color(0xFF6DB8CF),
      sand = Color(0xFFF1DCAD),
      amber = Color(0xFFECAA45),
      muted = Color(0xFF6C7C73),
      line = Color(0xFFE2E6DC),
      mint = Color(0xFFE6F0E7);
}

ThemeData buildAtlasTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'NotoSansSC',
  scaffoldBackgroundColor: AtlasColors.background,
  fontFamilyFallback: const [
    'PingFang SC',
    'Noto Sans CJK SC',
    'Microsoft YaHei',
  ],
  colorScheme: ColorScheme.fromSeed(
    seedColor: AtlasColors.forest,
    surface: AtlasColors.background,
    primary: AtlasColors.forest,
    onSurface: AtlasColors.ink,
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      height: 1.25,
      color: AtlasColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: AtlasColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AtlasColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AtlasColors.ink,
    ),
    bodyLarge: TextStyle(fontSize: 18, height: 1.65, color: AtlasColors.ink),
    bodyMedium: TextStyle(fontSize: 16, height: 1.5, color: AtlasColors.ink),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: const BorderSide(color: AtlasColors.line),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AtlasColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AtlasColors.line),
    ),
    contentPadding: const EdgeInsets.all(18),
  ),
);
