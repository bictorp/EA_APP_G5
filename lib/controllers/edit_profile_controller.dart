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
    final ProfileController profileController = Get.find<ProfileController>();
    final user = profileController.user.value;
    
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
      
      final ProfileController profileController = Get.find<ProfileController>();
      final currentUser = profileController.user.value;
      
      if (currentUser == null) return;

      final Map<String, dynamic> updateData = {
        'nombre': nameController.text.trim(),
        'email': emailController.text.trim(),
        'avatarUrl': avatarUrlController.text.trim(),
        'descripcion': bioController.text.trim(),
      };

      final updatedData = await _userService.updateUser(currentUser.id, updateData);
      
      if (updatedData != null) {
        // Update local storage
        final token = await _storageService.getAccessToken();
        if (token != null) {
          final newUser = User.fromJson(updatedData, token);
          await _storageService.saveUserData(jsonEncode(updatedData));
          
          // Update profile controller
          profileController.user.value = newUser;
          
          Get.back();
          Get.snackbar(
            'Éxito',
            'Perfil actualizado correctamente',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.white,
          );
        }
      } else {
        Get.snackbar(
          'Error',
          'No se pudo actualizar el perfil',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
          colorText: Colors.white,
        );
      }
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
