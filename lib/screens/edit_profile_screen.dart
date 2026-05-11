import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../controllers/edit_profile_controller.dart';
import '../widgets/custom_text_field.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Editar Perfil',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Radial Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
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
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
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
                                      
                                      ImageProvider? imageProvider;
                                      if (selectedXFile != null) {
                                        if (kIsWeb && selectedBytes != null) {
                                          imageProvider = MemoryImage(selectedBytes);
                                        } else {
                                          // En móvil usamos FileImage para archivos locales
                                          imageProvider = FileImage(File(selectedXFile.path));
                                        }
                                      } else if (avatarUrl.isNotEmpty) {
                                        // Añadimos un parámetro de tiempo para evitar problemas de caché al actualizar
                                        imageProvider = NetworkImage(avatarUrl);
                                      }

                                      return CircleAvatar(
                                        radius: 50,
                                        backgroundColor: AppColors.accent,
                                        backgroundImage: imageProvider,
                                        child: imageProvider == null
                                            ? Text(
                                                controller.previewName.value.isNotEmpty 
                                                    ? controller.previewName.value[0].toUpperCase() 
                                                    : '?',
                                                style: const TextStyle(
                                                  fontSize: 40, 
                                                  fontWeight: FontWeight.bold, 
                                                  color: Colors.white,
                                                ),
                                              )
                                            : null,
                                      );
                                    }),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
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
                            const SizedBox(height: 32),

                            // Fields
                            CustomTextField(
                              label: 'Nombre completo',
                              controller: controller.nameController,
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            const SizedBox(height: 24),

                            CustomTextField(
                              label: 'Correo electrónico',
                              controller: controller.emailController,
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            const SizedBox(height: 24),

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
                                  style: GoogleFonts.inter(color: Colors.white),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    hintText: 'Cuéntanos sobre ti...',
                                    hintStyle: GoogleFonts.inter(color: Colors.white38),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

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
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      // TODO: Implement subjects modal
                                      Get.snackbar(
                                        'Próximamente',
                                        'La edición de asignaturas estará disponible pronto',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.white10,
                                        colorText: Colors.white,
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
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),

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
                                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancelar',
                                      style: GoogleFonts.inter(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
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
                                        ? const SizedBox(
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
  }
}
