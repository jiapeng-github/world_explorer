import 'package:flutter/material.dart';

abstract final class AtlasPalette {
  static const canvas = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const ink = Color(0xFF12243A);
  static const navy = Color(0xFF12395B);
  static const blue = Color(0xFF265F91);
  static const orange = Color(0xFFFF9A3D);
  static const orangeSoft = Color(0xFFFFF0DF);
  static const muted = Color(0xFF53677D);
  static const line = Color(0xFFDDE5EE);
  static const sea = Color(0xFFDCEEF7);
  static const land = Color(0xFFEDF1DE);
  static const success = Color(0xFF2B6B55);
  static const error = Color(0xFFA33D3D);
}

ThemeData atlasTheme() {
  const text = TextTheme(
    headlineLarge: TextStyle(
      fontSize: 36,
      height: 1.22,
      fontWeight: FontWeight.w800,
    ),
    headlineMedium: TextStyle(
      fontSize: 30,
      height: 1.3,
      fontWeight: FontWeight.w800,
    ),
    headlineSmall: TextStyle(
      fontSize: 26,
      height: 1.3,
      fontWeight: FontWeight.w800,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      height: 1.4,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      height: 1.4,
      fontWeight: FontWeight.w700,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(fontSize: 18, height: 1.65),
    bodyMedium: TextStyle(fontSize: 16, height: 1.55),
    bodySmall: TextStyle(fontSize: 14, height: 1.5),
    labelLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSansSC',
    fontFamilyFallback: const ['PingFang SC', 'Microsoft YaHei'],
    scaffoldBackgroundColor: AtlasPalette.canvas,
    colorScheme: const ColorScheme.light(
      primary: AtlasPalette.navy,
      secondary: AtlasPalette.orange,
      surface: AtlasPalette.surface,
      onSurface: AtlasPalette.ink,
      error: AtlasPalette.error,
      outline: AtlasPalette.line,
    ),
    textTheme: text.apply(
      bodyColor: AtlasPalette.ink,
      displayColor: AtlasPalette.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AtlasPalette.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSansSC',
        color: AtlasPalette.ink,
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AtlasPalette.line,
      thickness: 1,
      space: 1,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: AtlasPalette.navy,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AtlasPalette.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size(52, 54),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        foregroundColor: AtlasPalette.navy,
        side: const BorderSide(color: AtlasPalette.navy),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AtlasPalette.canvas,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AtlasPalette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AtlasPalette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AtlasPalette.blue, width: 2),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
  );
}
