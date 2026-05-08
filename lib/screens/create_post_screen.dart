import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../controllers/create_post_controller.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CreatePostController controller = Get.put(CreatePostController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textHeader),
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
                    color: controller.isLoading.value ? Colors.white24 : AppColors.textLink,
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
            Text(
              'Enlace de la foto',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.urlController,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'https://ejemplo.com/imagen.jpg',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                filled: true,
                fillColor: AppColors.containerBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Descripción',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller.captionController,
              maxLines: 5,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribe un pie de foto...',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                filled: true,
                fillColor: AppColors.containerBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 32),
            Obx(() => controller.isLoading.value
                ? const Center(child: CircularProgressIndicator(color: AppColors.textLink))
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
