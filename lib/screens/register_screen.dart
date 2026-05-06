import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../controllers/register_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/error_banner.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RegisterController controller = Get.put(RegisterController());

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo con Gradiente Radial (Space Theme)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  AppColors.bgDarkStart,
                  AppColors.bgDarkMid,
                  AppColors.bgDarkEnd,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // 2. Contenido centrado con Glassmorphism
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: AppColors.containerBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderWhite, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Título con Gradiente y fuente Inter
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.titleStart, AppColors.titleEnd],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            'UNIVY',
                            style: GoogleFonts.inter(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu cuenta',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 40),

                        Obx(() => ErrorBanner(
                          message: controller.errorMessage.value,
                          onClose: () => controller.errorMessage.value = '',
                        )),

                        CustomTextField(
                          label: 'Nombre completo',
                          controller: controller.nameController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Correo electrónico',
                          controller: controller.emailController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Contraseña',
                          controller: controller.passwordController,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Confirmar Contraseña',
                          controller: controller.confirmPasswordController,
                          isPassword: true,
                        ),
                        const SizedBox(height: 32),
                        
                        Obx(() => CustomButton(
                          text: 'Registrarse',
                          onPressed: controller.register,
                          isLoading: controller.isLoading.value,
                        )),
                        
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes cuenta?',
                              style: GoogleFonts.inter(color: AppColors.textMuted),
                            ),
                            TextButton(
                              onPressed: () => Get.back(),
                              child: Text(
                                'Inicia Sesión',
                                style: GoogleFonts.inter(
                                  color: AppColors.textLink,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
