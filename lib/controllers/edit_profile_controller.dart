import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart' as dio_lib;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../constants/api_constants.dart';
import 'profile_controller.dart';

class EditProfileController extends GetxController {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final bioController = TextEditingController();
  
  final ImagePicker _picker = ImagePicker();
  var selectedXFile = Rx<XFile?>(null);
  var selectedImageBytes = Rx<Uint8List?>(null);

  var isLoading = false.obs;
  var previewName = ''.obs;
  var previewAvatarUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    
    // Add listeners for real-time preview
    nameController.addListener(() {
      previewName.value = nameController.text;
    });
  }

  void _loadInitialData() async {
    User? user;
    
    // Try to get user from ProfileController if it exists
    if (Get.isRegistered<ProfileController>()) {
      final ProfileController profileController = Get.find<ProfileController>();
      user = profileController.user.value;
    }
    
    // Fallback: Try to get user from storage if ProfileController is missing or has no user
    if (user == null) {
      final userDataStr = await _storageService.getUserData();
      final token = await _storageService.getAccessToken();
      if (userDataStr != null && token != null) {
        user = User.fromJson(jsonDecode(userDataStr), token);
      }
    }
    
    if (user != null) {
      nameController.text = user.nombre;
      emailController.text = user.email;
      bioController.text = user.descripcion ?? '';
      
      previewName.value = user.nombre;
      previewAvatarUrl.value = user.avatarUrl ?? '';
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        selectedXFile.value = image;
        if (kIsWeb) {
          selectedImageBytes.value = await image.readAsBytes();
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo seleccionar la imagen');
    }
  }

  Future<void> saveProfile() async {
    try {
      isLoading.value = true;
      
      String? uploadedUrl;

      if (selectedXFile.value != null) {
        // 1. Subir la imagen al endpoint de upload existente
        final bytes = await selectedXFile.value!.readAsBytes();
        final uploadData = dio_lib.FormData.fromMap({
          'image': dio_lib.MultipartFile.fromBytes(
            bytes,
            filename: selectedXFile.value!.name,
          ),
        });

        final uploadResponse = await AuthService.dio.post(
          '${ApiConstants.baseUrl}/upload',
          data: uploadData,
        );

        if (uploadResponse.statusCode == 200) {
          uploadedUrl = uploadResponse.data['url'];
        } else {
          throw 'Error al subir la imagen al servidor';
        }
      }

      // 2. Actualizar el perfil con los datos (incluyendo la nueva URL si existe)
      final Map<String, dynamic> updateData = {
        'nombre': nameController.text.trim(),
        'email': emailController.text.trim(),
        'descripcion': bioController.text.trim(),
      };

      if (uploadedUrl != null) {
        updateData['avatarUrl'] = uploadedUrl;
      }

      final updateResult = await _userService.updateUser(updateData);
      
      if (updateResult != null) {
        // Fetch full fresh data from /auth/me (GET) to ensure everything is in sync
        final freshData = await _userService.getMe();
        final finalUserData = freshData ?? updateResult;

        // Update local storage
        final token = await _storageService.getAccessToken();
        if (token != null) {
          await _storageService.saveUserData(jsonEncode(finalUserData));
          
          // Update profile controller if it's active
          if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().loadUserData();
          }
          
          Get.back();
          Get.snackbar(
            'Éxito',
            'Perfil actualizado correctamente',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'No se pudo actualizar el perfil. Verifica los datos.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Ocurrió un error inesperado',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
