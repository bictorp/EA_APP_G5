import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'bug_report_screen.dart';
import '../controllers/theme_controller.dart';
import '../controllers/language_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;

      return Scaffold(
        backgroundColor: isDark ? Color(0xFF0F172A) : Color(0xFFF8F9FC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'settings'.tr,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Color(0xFF1A1B23),
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Color(0xFF1A1B23)),
            onPressed: () => Get.back(),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.5,
              colors: isDark
                  ? [
                      Color(0xFF1E1B4B),
                      Color(0xFF0F172A),
                      Color(0xFF000000),
                    ]
                  : [
                      Color(0xFFEEF2F6),
                      Color(0xFFF8F9FC),
                      Color(0xFFE2E8F0),
                    ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              physics: BouncingScrollPhysics(),
              children: [
                _buildSettingsSection(
                  title: 'appearance'.tr,
                  isDark: isDark,
                  children: [
                    _buildSettingsToggle(
                      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      title: 'dark_mode'.tr,
                      color: Color(0xFFC084FC),
                      value: isDark,
                      onChanged: (val) {
                        themeController.toggleTheme(val);
                      },
                      isDark: isDark,
                    ),
                    _buildSettingsItem(
                      icon: Icons.language_rounded,
                      title: 'language'.tr,
                      color: Color(0xFFC084FC),
                      onTap: () => _showLanguageDialog(context, isDark, languageController),
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildSettingsSection(
                  title: 'general'.tr,
                  isDark: isDark,
                  children: [
                    _buildSettingsItem(
                      icon: Icons.bug_report_rounded,
                      title: 'report_bug'.tr,
                      color: Color(0xFF6366F1), // Indigo color
                      onTap: () => Get.to(() => BugReportScreen()),
                      isDark: isDark,
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildSettingsSection(
                  title: 'account'.tr,
                  isDark: isDark,
                  children: [
                    _buildSettingsItem(
                      icon: Icons.logout_rounded,
                      title: 'logout'.tr,
                      color: Color(0xFFEF4444),
                      onTap: () => _showLogoutDialog(context, isDark),
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: isDark ? Color(0xFF94A3B8) : Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsToggle({
    required IconData icon,
    required String title,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white : Color(0xFF1A1B23),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Color(0xFF1A1B23),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, bool isDark, LanguageController langController) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFC084FC).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: Color(0xFFC084FC),
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'select_language'.tr,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Color(0xFF1A1B23),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 20),
              _buildLanguageOption(
                label: 'spanish'.tr,
                isSelected: langController.currentLanguage.value == 'es',
                onTap: () {
                  langController.changeLanguage('es');
                  Get.back();
                },
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildLanguageOption(
                label: 'catalan'.tr,
                isSelected: langController.currentLanguage.value == 'ca',
                onTap: () {
                  langController.changeLanguage('ca');
                  Get.back();
                },
                isDark: isDark,
              ),
              SizedBox(height: 8),
              _buildLanguageOption(
                label: 'english'.tr,
                isSelected: langController.currentLanguage.value == 'en',
                onTap: () {
                  langController.changeLanguage('en');
                  Get.back();
                },
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final highlightColor = Color(0xFFC084FC);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? highlightColor.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? highlightColor.withOpacity(0.3) 
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected 
                      ? highlightColor 
                      : (isDark ? Colors.white : Color(0xFF1A1B23)),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: highlightColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'logout_confirm_title'.tr,
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white : Color(0xFF1A1B23),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'logout_confirm_msg'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: isDark ? Color(0xFF94A3B8) : Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white : Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.back(); // close dialog
                        final authService = AuthService();
                        await authService.logout();
                        Get.offAllNamed('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'logout'.tr,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
