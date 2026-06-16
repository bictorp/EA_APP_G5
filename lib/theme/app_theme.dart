import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDarkEnd,
    primaryColor: AppColors.inputFocus,
    
    // Aplicamos la fuente Inter globalmente usando GoogleFonts
    textTheme: GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.textMain),
        bodyMedium: TextStyle(color: AppColors.textMuted),
      ),
    ),
    
    colorScheme: ColorScheme.dark(
      primary: AppColors.inputFocus,
      secondary: AppColors.btnEnd,
      surface: AppColors.bgDarkMid,
      onSurface: AppColors.textMain,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Color(0xFFF8F9FC),
    primaryColor: Color(0xFF8A2BE2),
    
    textTheme: GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(color: Color(0xFF1A1B23), fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Color(0xFF1A1B23)),
        bodyMedium: TextStyle(color: Color(0xFF64748B)),
      ),
    ),
    
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF8A2BE2),
      secondary: Color(0xFF7C3AED),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1B23),
    ),
  );
}
