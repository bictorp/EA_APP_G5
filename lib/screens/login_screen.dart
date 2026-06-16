import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../controllers/login_controller.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/error_banner.dart';

import '../screens/register_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());

    return Scaffold(
      body: Stack(
        children: [
          // 1. Fondo con Gradiente Radial (Space Theme)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                          shaderCallback: (bounds) => LinearGradient(
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
                        SizedBox(height: 8),
                        Text(
                          'Bienvenido de nuevo',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 40),

                        Obx(() => ErrorBanner(
                          message: controller.errorMessage.value,
                          onClose: () => controller.errorMessage.value = '',
                        )),

                        CustomTextField(
                          label: 'Correo electrónico',
                          controller: controller.emailController,
                        ),
                        SizedBox(height: 20),
                        CustomTextField(
                          label: 'Contraseña',
                          controller: controller.passwordController,
                          isPassword: true,
                        ),
                        SizedBox(height: 32),
                        
                        Obx(() => CustomButton(
                          text: 'Iniciar Sesión',
                          onPressed: controller.login,
                          isLoading: controller.isLoading.value,
                        )),
                        
                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿No tienes cuenta?',
                              style: GoogleFonts.inter(color: AppColors.textMuted),
                            ),
                            TextButton(
                              onPressed: () => Get.to(() => RegisterScreen()),
                              child: Text(
                                'Regístrate',
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
