import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../controllers/create_post_controller.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  void _showPicker(BuildContext context, CreatePostController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.containerBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white),
                  title: const Text('Galería', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    controller.pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white),
                title: const Text('Cámara', style: TextStyle(color: Colors.white)),
                onTap: () {
                  controller.pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    );
  }

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
            GestureDetector(
              onTap: () => _showPicker(context, controller),
              child: Obx(() => Container(
                width: double.infinity,
                height: 300,
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
                child: controller.selectedImage.value == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo, size: 50, color: Colors.white54),
                          const SizedBox(height: 12),
                          Text(
                            'Toca para seleccionar o tomar foto',
                            style: GoogleFonts.inter(color: Colors.white54),
                          )
                        ],
                      )
                    : null,
              )),
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
