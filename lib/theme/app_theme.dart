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
      const TextTheme(
        displayLarge: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: AppColors.textMain),
        bodyMedium: TextStyle(color: AppColors.textMuted),
      ),
    ),
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.inputFocus,
      secondary: AppColors.btnEnd,
      surface: AppColors.bgDarkMid,
      onSurface: AppColors.textMain,
    ),
  );

  static final ThemeData lightTheme = darkTheme; 
}
