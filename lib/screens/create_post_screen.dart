import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/theme_controller.dart';

class CreatePostScreen extends StatelessWidget {
  CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el controlador que ya fue inicializado en el flujo previo
    final CreatePostController controller = Get.find<CreatePostController>();
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textHeader),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Nueva publicación',
            style: GoogleFonts.inter(
              color: AppColors.textHeader,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            Obx(() => TextButton(
                  onPressed: controller.isLoading.value ? null : () => controller.submitPost(),
                  child: Text(
                    'Compartir',
                    style: GoogleFonts.inter(
                      color: controller.isLoading.value ? AppColors.textMuted : AppColors.textLink,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vista previa de la imagen ya procesada
              Obx(() => Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width - 40, // Formato cuadrado
                decoration: BoxDecoration(
                  color: AppColors.containerBg,
                  borderRadius: BorderRadius.circular(16),
                  image: controller.selectedImage.value != null
                      ? DecorationImage(
                          image: kIsWeb 
                              ? NetworkImage(controller.selectedImage.value!.path) as ImageProvider
                              : FileImage(File(controller.selectedImage.value!.path)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: controller.selectedImage.value != null 
                  ? Stack(
                      children: [
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: ElevatedButton.icon(
                            onPressed: () => controller.reEditImage(),
                            icon: Icon(Icons.edit, size: 18),
                            label: Text('Editar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(child: Text("Sin imagen", style: TextStyle(color: AppColors.textMuted))),
              )),
              
              SizedBox(height: 24),
              
              // Campo de descripción (Pie de foto)
              Text(
                'Descripción',
                style: GoogleFonts.inter(
                  color: AppColors.textHeader,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: controller.captionController,
                maxLines: 4,
                style: GoogleFonts.inter(color: AppColors.textMain),
                autofocus: true, // Abrir teclado directamente para escribir la descripción
                decoration: InputDecoration(
                  hintText: 'Escribe un pie de foto...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.containerBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              
              SizedBox(height: 32),
              
              Obx(() => controller.isLoading.value
                  ? Center(child: CircularProgressIndicator(color: AppColors.textLink))
                  : const SizedBox.shrink()),
            ],
          ),
        ),
      );
    });
  }
}
