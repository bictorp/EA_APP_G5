import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/unimatch_profile.dart';
import '../services/unimatch_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class UnimatchController extends GetxController {
  final UnimatchService _unimatchService = UnimatchService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  var isLoading = true.obs;
  var isSwiping = false.obs;
  var hasAcceptedTerms = false.obs;
  var profiles = <UnimatchProfile>[].obs;
  var matches = <dynamic>[].obs;

  var localOnboardingPhotos = <XFile>[].obs;
  var isUploadingOnboarding = false.obs;

  var currentUser = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    checkTermsAndLoad();
  }

  /// Verifica si el usuario ha aceptado los términos de Unimatch
  Future<void> checkTermsAndLoad() async {
    try {
      isLoading.value = true;
      final userProfile = await _authService.checkSession();
      if (userProfile) {
        final userJson = await _storageService.getUserData();
        if (userJson != null) {
          final decoded = jsonDecode(userJson);
          currentUser.value = decoded;
          hasAcceptedTerms.value = decoded['hasAcceptedUnimatchTerms'] ?? false;
        }
      }
      if (hasAcceptedTerms.value) {
        await loadProfiles();
      }
    } catch (e) {
      print('Error al verificar sesión en UnimatchController: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Cargar perfiles desde el backend
  Future<void> loadProfiles() async {
    try {
      isLoading.value = true;
      final fetched = await _unimatchService.discoverProfiles(limit: 20);
      profiles.assignAll(fetched);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar los perfiles de UniMatch',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Registrar swipe (like o dislike)
  Future<void> handleSwipe(int index, String type) async {
    if (index < 0 || index >= profiles.length) return;
    final profile = profiles[index];

    try {
      final result = await _unimatchService.recordSwipe(
        toUserId: profile.id,
        type: type,
      );

      // Si hay match, mostrar un popup o modal especial
      if (result['matched'] == true) {
        _showMatchDialog(profile);
      }

      // Si quedan pocos perfiles en la lista, cargar más para que sea infinito
      if (profiles.length - index <= 3) {
        final fetched = await _unimatchService.discoverProfiles(limit: 20);
        if (fetched.isNotEmpty) {
          profiles.addAll(fetched);
        }
      }
    } catch (e) {
      print('Error al procesar swipe: $e');
    }
  }

  /// Aceptar los términos de UniMatch y subir fotos obligatorias de onboarding
  Future<void> uploadOnboardingPhotosAndAcceptTerms() async {
    if (localOnboardingPhotos.isEmpty) {
      Get.snackbar(
        'Error',
        'Sube al menos 1 foto para empezar',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    try {
      isUploadingOnboarding.value = true;
      isLoading.value = true;

      // 1. Subir fotos
      for (final xfile in localOnboardingPhotos) {
        await _unimatchService.uploadUnimatchPhoto(xfile);
      }

      // 2. Aceptar términos
      final success = await _unimatchService.acceptTerms();
      if (success) {
        final userJson = await _storageService.getUserData();
        if (userJson != null) {
          final decoded = jsonDecode(userJson);
          decoded['hasAcceptedUnimatchTerms'] = true;
          await _storageService.saveUserData(jsonEncode(decoded));
        }
        hasAcceptedTerms.value = true;
        await loadProfiles();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al configurar UniMatch: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isUploadingOnboarding.value = false;
      isLoading.value = false;
    }
  }

  /// Muestra un Dialog premium de Match al estilo Tinder
  void _showMatchDialog(UnimatchProfile matchedUser) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: const Color(0xFFEC4899).withOpacity(0.5),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animación o Icono de fuego/corazón
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
                ).createShader(bounds),
                child: const Text(
                  '¡Es un Match!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tú y ${matchedUser.nombre} os habéis dado un like mutuo.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              
              // Avatares de los usuarios cruzados
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar del usuario actual
                  Transform.translate(
                    offset: const Offset(15, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF7C3AED), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundImage: NetworkImage(
                          currentUser.value?['avatarUrl'] != null && currentUser.value!['avatarUrl'].toString().isNotEmpty
                              ? currentUser.value!['avatarUrl']
                              : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
                        ),
                      ),
                    ),
                  ),
                  // Avatar de la otra persona
                  Transform.translate(
                    offset: const Offset(-15, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEC4899), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEC4899).withOpacity(0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundImage: NetworkImage(
                          matchedUser.avatarUrl != null && matchedUser.avatarUrl!.isNotEmpty
                              ? matchedUser.avatarUrl!
                              : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 35),
              
              // Botón de Enviar Mensaje
              ElevatedButton(
                onPressed: () {
                  Get.back(); // Cerrar Dialog
                  Get.find<AuthService>().checkSession(); // Opcional refrescar
                  // Redirigir a la pestaña de mensajes (índice 3 en MainScreen)
                  Get.find<GetxController>().update(); // En MainController
                  // Alternativamente, redirigir a chat:
                  Get.offAllNamed('/home'); // O a la vista principal
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Enviar Mensaje',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              
              // Botón de seguir buscando
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Seguir buscando',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
