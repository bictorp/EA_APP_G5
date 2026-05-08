import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/post_service.dart';
import '../services/upload_service.dart';
import '../constants/app_colors.dart';
import 'home_controller.dart';

class CreatePostController extends GetxController {
  final PostService _postService = PostService();
  final UploadService _uploadService = UploadService();
  
  final TextEditingController captionController = TextEditingController();
  
  var isLoading = false.obs;
  var selectedImage = Rxn<XFile>();

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        await _cropImage(pickedFile);
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo seleccionar la imagen',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _cropImage(XFile imgFile) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imgFile.path,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Recortar foto',
              toolbarColor: AppColors.bg,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9
              ],
          ),
          IOSUiSettings(
            title: 'Recortar foto',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        selectedImage.value = XFile(croppedFile.path);
      } else {
        selectedImage.value = imgFile;
      }
    } catch (e) {
      print("Error cropping image: $e");
      // Fallback if cropper is not supported on Web without proper index.html
      selectedImage.value = imgFile;
    }
  }

  Future<void> submitPost() async {
    final String caption = captionController.text.trim();

    if (selectedImage.value == null) {
      Get.snackbar(
        'Error',
        'Por favor, selecciona o toma una foto',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      
      // Upload image to Cloudinary
      final String? uploadedUrl = await _uploadService.uploadImage(selectedImage.value!);
      
      if (uploadedUrl == null) {
        Get.snackbar(
          'Error',
          'No se pudo subir la imagen',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      final result = await _postService.createPost(uploadedUrl, caption);
      
      if (result != null) {
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
    captionController.dispose();
    super.onClose();
  }
}
