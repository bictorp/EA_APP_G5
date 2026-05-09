import 'package:flutter/material.dart';

class AppColors {
  // Brand / Primary (Atenea)
  static const Color accent = Color(0xFFC084FC); // Purple from Web
  static const Color accentBg = Color(0x26C084FC); // 15% opacity
  static const Color accentBorder = Color(0x80C084FC); // 50% opacity

  // Backgrounds
  static const Color bg = Color(0xFF16171D); // Web dark bg
  static const Color containerBg = Color(0xFF1F2028); // Web code-bg / card bg
  static const Color socialBg = Color(0x802F303A); // Web social-bg
  static const Color surface = Color(0xFF1F2028); // Alias for containerBg

  // Text
  static const Color textHeader = Color(0xFFF3F4F6); // Web text-h
  static const Color textMuted = Color(0xFF9CA3AF); // Web text
  static const Color textLink = Color(0xFFC084FC); // Same as accent

  // Borders
  static const Color border = Color(0xFF2E303A); // Web border
  static const Color borderWhite = Color(0x1AFFFFFF); // 10% white for subtle separators

  // Status
  static const Color error = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF10B981);

  // --- Aliases for legacy components ---
  static const Color bgDarkStart = bg;
  static const Color bgDarkMid = containerBg;
  static const Color bgDarkEnd = bg;
  
  static const Color textMain = textHeader;
  
  static const Color inputBg = containerBg;
  static const Color inputBorder = border;
  static const Color inputFocus = accent;
  
  static const Color btnStart = accent;
  static const Color btnEnd = Color(0xFF8B5CF6);

  // Gradients
  static const Color titleStart = Color(0xFFC084FC);
  static const Color titleEnd = Color(0xFF8B5CF6);
}
