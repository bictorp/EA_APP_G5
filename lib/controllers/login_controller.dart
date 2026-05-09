import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../controllers/chat_controller.dart';

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
        Get.put(ChatController(), permanent: true);
        Get.offAllNamed('/home');
      }
    } catch (e) {
      errorMessage.value = e.toString();
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
