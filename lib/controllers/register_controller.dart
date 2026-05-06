import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class RegisterController extends GetxController {
  final AuthService _authService = AuthService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      errorMessage.value = 'Por favor, rellena todos los campos';
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      errorMessage.value = 'Las contraseñas no coinciden';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final success = await _authService.register(
        nameController.text,
        emailController.text,
        passwordController.text,
      );

      if (success) {
        Get.back(); // Regresar al login
        Get.snackbar(
          'Éxito',
          'Usuario registrado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withAlpha(200),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
