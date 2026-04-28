import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';

class LoginController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Future<void> login() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = await _authService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (user != null) {
        Get.snackbar(
          'Éxito',
          'Bienvenido ${user.nombre}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.1),
          colorText: Get.theme.colorScheme.primary,
          margin: const EdgeInsets.all(16),
        );
        // Get.offAll(() => const HomeScreen()); // Redirigir usando GetX
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
