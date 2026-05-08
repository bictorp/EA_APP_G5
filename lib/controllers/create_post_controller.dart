import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/post_service.dart';
import '../constants/app_colors.dart';
import 'home_controller.dart';

class CreatePostController extends GetxController {
  final PostService _postService = PostService();
  
  final TextEditingController urlController = TextEditingController();
  final TextEditingController captionController = TextEditingController();
  
  var isLoading = false.obs;

  Future<void> submitPost() async {
    final String imageUrl = urlController.text.trim();
    final String caption = captionController.text.trim();

    if (imageUrl.isEmpty) {
      Get.snackbar(
        'Error',
        'Por favor, introduce una URL de imagen',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      final result = await _postService.createPost(imageUrl, caption);
      
      if (result != null) {
        // Refrescar el home si existe el controlador
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().fetchPosts();
        }
        
        Get.back();
        Get.snackbar(
          'Éxito',
          'Publicación creada correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'No se pudo crear la publicación',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    urlController.dispose();
    captionController.dispose();
    super.onClose();
  }
}
