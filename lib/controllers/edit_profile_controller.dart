import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import 'profile_controller.dart';

class EditProfileController extends GetxController {
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final avatarUrlController = TextEditingController();
  final bioController = TextEditingController();

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
    avatarUrlController.addListener(() {
      previewAvatarUrl.value = avatarUrlController.text;
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
      avatarUrlController.text = user.avatarUrl ?? '';
      bioController.text = user.descripcion ?? '';
      
      previewName.value = user.nombre;
      previewAvatarUrl.value = user.avatarUrl ?? '';
    }
  }

  Future<void> saveProfile() async {
    try {
      isLoading.value = true;
      
      final Map<String, dynamic> updateData = {
        'nombre': nameController.text.trim(),
        'email': emailController.text.trim(),
        'avatarUrl': avatarUrlController.text.trim(),
        'descripcion': bioController.text.trim(),
      };

      final updateResult = await _userService.updateUser(updateData);
      
      if (updateResult != null) {
        // Fetch full fresh data from /auth/me (GET) to ensure everything is in sync
        final freshData = await _userService.getMe();
        final finalUserData = freshData ?? updateResult;

        // Update local storage
        final token = await _storageService.getAccessToken();
        if (token != null) {
          final newUser = User.fromJson(finalUserData, token);
          await _storageService.saveUserData(jsonEncode(finalUserData));
          
          // Update profile controller if it's active
          if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().user.value = newUser;
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
    avatarUrlController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
