import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/custom_text_field.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileController());
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      return Scaffold(
        backgroundColor: AppColors.bg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textHeader),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Editar Perfil',
            style: GoogleFonts.inter(
              color: AppColors.textHeader,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: Stack(
          children: [
            // Background Radial Gradient
            if (isDark)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.5,
                      colors: [
                        Color(0xFF1E1B4B),
                        Color(0xFF0F172A),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),
            
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    // Glassmorphic Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : AppColors.containerBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.08) : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Avatar section
                              Center(
                                child: GestureDetector(
                                  onTap: () => controller.pickImage(),
                                  child: Stack(
                                    children: [
                                      Obx(() {
                                        final avatarUrl = controller.previewAvatarUrl.value;
                                        final selectedXFile = controller.selectedXFile.value;
                                        final selectedBytes = controller.selectedImageBytes.value;
                                        
                                        Widget childWidget;
                                        if (selectedXFile != null) {
                                          if (kIsWeb && selectedBytes != null) {
                                            childWidget = Image.memory(selectedBytes, fit: BoxFit.cover, width: 100, height: 100);
                                          } else {
                                            childWidget = Image.file(File(selectedXFile.path), fit: BoxFit.cover, width: 100, height: 100);
                                          }
                                        } else if (avatarUrl.isNotEmpty) {
                                          childWidget = Image.network(
                                            avatarUrl,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                            errorBuilder: (context, error, stackTrace) => _buildFallbackWidget(controller.previewName.value),
                                          );
                                        } else {
                                          childWidget = _buildFallbackWidget(controller.previewName.value);
                                        }

                                        return CircleAvatar(
                                          radius: 50,
                                          backgroundColor: AppColors.accent,
                                          child: ClipOval(
                                            child: childWidget,
                                          ),
                                        );
                                      }),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 32),

                              // Fields
                              CustomTextField(
                                label: 'Nombre completo',
                                controller: controller.nameController,
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              SizedBox(height: 24),

                              CustomTextField(
                                label: 'Correo electrónico',
                                controller: controller.emailController,
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              SizedBox(height: 24),

                              // Bio Field (Textarea style)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                                    child: Text(
                                      'Biografía',
                                      style: GoogleFonts.inter(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  TextField(
                                    controller: controller.bioController,
                                    maxLines: 4,
                                    style: GoogleFonts.inter(color: AppColors.textMain),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppColors.inputBg,
                                      hintText: 'Cuéntanos sobre ti...',
                                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: AppColors.inputBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: AppColors.inputFocus, width: 1.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),

                              // Asignaturas Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                                    child: Text(
                                      'Asignaturas',
                                      style: GoogleFonts.inter(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.inputBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.inputBorder),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        // TODO: Implement subjects modal
                                        Get.snackbar(
                                          'Próximamente',
                                          'La edición de asignaturas estará disponible pronto',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                          colorText: AppColors.textMain,
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        alignment: Alignment.centerLeft,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Gestionar mis asignaturas',
                                              style: GoogleFonts.inter(
                                                color: AppColors.textMain,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Icon(Icons.chevron_right_rounded, color: AppColors.accent),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 40),

                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Get.back(),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: BorderSide(color: AppColors.border),
                                        ),
                                      ),
                                      child: Text(
                                        'Cancelar',
                                        style: GoogleFonts.inter(
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Obx(() => ElevatedButton(
                                      onPressed: controller.isLoading.value ? null : () => controller.saveProfile(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ).copyWith(
                                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                                          if (states.contains(WidgetState.disabled)) return AppColors.accent.withOpacity(0.5);
                                          return null;
                                        }),
                                      ),
                                      child: controller.isLoading.value
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              'Guardar',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    )),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFallbackWidget(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      alignment: Alignment.center,
      color: AppColors.accent,
      width: 100,
      height: 100,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
