import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import '../controllers/chat_controller.dart';

class LoginController extends GetxController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Escuchar los cambios en la cuenta de Google (especial para el botón de Web)
    AuthService.googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        isLoading.value = true;
        errorMessage.value = '';
        try {
          final GoogleSignInAuthentication googleAuth = await account.authentication;
          final String? idToken = googleAuth.idToken;

          final user = await _authService.loginWithIdToken(idToken);

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
    });
  }

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

  Future<void> loginWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = await _authService.loginWithGoogle();

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
