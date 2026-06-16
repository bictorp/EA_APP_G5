import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/camera_screen.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:photofilters/photofilters.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'dart:io';
import '../services/post_service.dart';
import '../services/upload_service.dart';
import '../constants/app_colors.dart';
import 'home_controller.dart';
import '../controllers/theme_controller.dart';

class CreatePostController extends GetxController {
  final PostService _postService = PostService();
  final UploadService _uploadService = UploadService();
  
  final TextEditingController captionController = TextEditingController();
  
  var isLoading = false.obs;
  var selectedImage = Rxn<XFile>();

  final ImagePicker _picker = ImagePicker();

  Future<void> startMediaFlow() async {
    try {
      final XFile? pickedFile = await Get.to(() => CameraScreen());
      if (pickedFile != null) {
        await _cropImage(pickedFile);
      } else {
        // Si el usuario cancela la cámara/galería, volvemos atrás
        if (selectedImage.value == null) {
          Get.back();
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo abrir la cámara',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

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

  Future<void> reEditImage() async {
    if (selectedImage.value != null) {
      await _cropImage(selectedImage.value!);
    }
  }

  Future<void> _cropImage(XFile imgFile) async {
    if (kIsWeb) {
      print("Saltando recorte en Web para evitar errores de inicialización");
      await _applyFilters(imgFile);
      return;
    }
    try {
      final themeController = Get.find<ThemeController>();
      final isDark = themeController.isDarkMode.value;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imgFile.path,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Recortar foto',
              toolbarColor: AppColors.bg,
              toolbarWidgetColor: AppColors.textHeader,
              activeControlsWidgetColor: AppColors.accent,
              backgroundColor: AppColors.bg,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              hideBottomControls: true, // Ocultamos todo para máxima limpieza
          ),
          IOSUiSettings(
            title: 'Recortar foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        XFile croppedXFile = XFile(croppedFile.path);
        await _applyFilters(croppedXFile);
      } else {
        // Si cancela el recorte en móvil, cancelamos todo. 
        // Pero en Web, como el cropper a veces falla, intentamos seguir con los filtros si ya teníamos la imagen.
        if (kIsWeb) {
          await _applyFilters(imgFile);
        }
      }
    } catch (e) {
      print("Error cropping image: $e");
      // Si falla el cropper (común en web si no está configurado), saltamos a filtros
      await _applyFilters(imgFile);
    }
  }

  Future<void> _applyFilters(XFile file) async {
    if (kIsWeb) {
      print("Saltando filtros en Web por incompatibilidad de plataforma");
      selectedImage.value = file;
      return;
    }
    try {
      String fileName = basename(file.path);
      var imageBytes = await file.readAsBytes();
      var decodedImage = img.decodeImage(imageBytes);
      
      if (decodedImage == null) return;

      final themeController = Get.find<ThemeController>();
      final isDark = themeController.isDarkMode.value;

      Map? imagefile = await Navigator.push(
        Get.context!,
        MaterialPageRoute(
          builder: (context) => Theme(
            data: ThemeData(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primaryColor: AppColors.accent,
              scaffoldBackgroundColor: AppColors.bg,
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.bg,
                foregroundColor: AppColors.textHeader,
                elevation: 0,
              ),
              colorScheme: isDark
                  ? ColorScheme.dark(
                      primary: AppColors.accent,
                      secondary: AppColors.accent,
                      surface: AppColors.containerBg,
                      background: AppColors.bg,
                    )
                  : ColorScheme.light(
                      primary: AppColors.accent,
                      secondary: AppColors.accent,
                      surface: AppColors.containerBg,
                      background: AppColors.bg,
                    ),
            ),
            child: PhotoFilterSelector(
              appBarColor: AppColors.bg,
              title: Text("Aplicar filtros", style: TextStyle(color: AppColors.textHeader)),
              image: decodedImage,
              filters: presetFiltersList,
              filename: fileName,
              loader: Center(child: CircularProgressIndicator()),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );

      if (imagefile != null && imagefile.containsKey('image_filtered')) {
        File filteredFile = imagefile['image_filtered'];
        selectedImage.value = XFile(filteredFile.path);
      } else {
        // Si no aplica filtros, nos quedamos con la recortada
        selectedImage.value = file;
      }

      // Una vez procesada la imagen, vamos a la pantalla de descripción
      if (Get.currentRoute != '/create-post') {
        Get.toNamed('/create-post');
      }
    } catch (e) {
      print("Error applying filters: $e");
      selectedImage.value = file;
      if (Get.currentRoute != '/create-post') {
        Get.toNamed('/create-post');
      }
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
