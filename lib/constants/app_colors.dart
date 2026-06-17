import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class AppColors {
  static bool get _isDark {
    try {
      return Get.find<ThemeController>().isDarkMode.value;
    } catch (_) {
      return true; // Default to dark mode if not initialized
    }
  }

  // Brand / Primary (Atenea)
  static const Color accent = Color(0xFF8A2BE2); // New BlueViolet #8A2BE2
  static const Color accentBg = Color(0x268A2BE2); // 15% opacity
  static const Color accentBorder = Color(0x808A2BE2); // 50% opacity

  // Backgrounds
  static Color get bg => _isDark ? Color(0xFF16171D) : Color(0xFFF8F9FC); // Web light / dark bg
  static Color get containerBg => _isDark ? Color(0xFF1F2028) : Color(0xFFFFFFFF); // Web card bg
  static Color get socialBg => _isDark ? Color(0x802F303A) : Color(0x0C000000); 
  static Color get surface => containerBg;
  static Color get incomingBubble => _isDark ? Color(0xFF1F2028) : Color(0xFFE4E6EB);

  // Text
  static Color get textHeader => _isDark ? Color(0xFFF3F4F6) : Color(0xFF1A1B23); 
  static Color get textMuted => _isDark ? Color(0xFF9CA3AF) : Color(0xFF64748B); 
  static const Color textLink = accent; // Same as accent

  // Borders
  static Color get border => _isDark ? Color(0xFF2E303A) : Color(0xFFE2E8F0); 
  static Color get borderWhite => _isDark ? Color(0x1AFFFFFF) : Color(0x0A000000); 

  // Status
  static const Color error = Color(0xFFFF4D4D);
  static const Color success = Color(0xFF10B981);

  // --- Aliases for legacy components ---
  static Color get bgDarkStart => bg;
  static Color get bgDarkMid => containerBg;
  static Color get bgDarkEnd => bg;
  
  static Color get textMain => textHeader;
  
  static Color get inputBg => containerBg;
  static Color get inputBorder => border;
  static const Color inputFocus = accent;
  
  static const Color btnStart = accent;
  static const Color btnEnd = Color(0xFF8A2BE2);

  // Gradients
  static const Color titleStart = Color(0xFF8A2BE2);
  static const Color titleEnd = Color(0xFF7C3AED); // Slightly darker version for gradient depth
}
