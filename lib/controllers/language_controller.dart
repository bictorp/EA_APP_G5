import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';

class LanguageController extends GetxController {
  final StorageService _storageService = StorageService();
  
  // Observable string representing the current language code
  var currentLanguage = 'es'.obs;

  final List<String> supportedLanguages = ['es', 'ca', 'en'];

  Future<LanguageController> init() async {
    final savedLanguage = await _storageService.getLanguage();
    if (savedLanguage != null && supportedLanguages.contains(savedLanguage)) {
      currentLanguage.value = savedLanguage;
    } else {
      // Intentamos usar el idioma del dispositivo si está soportado, si no, español por defecto
      final deviceLoc = Get.deviceLocale?.languageCode;
      if (deviceLoc != null && supportedLanguages.contains(deviceLoc)) {
        currentLanguage.value = deviceLoc;
      } else {
        currentLanguage.value = 'es';
      }
    }
    return this;
  }

  Locale get locale => Locale(currentLanguage.value);

  Future<void> changeLanguage(String langCode) async {
    if (supportedLanguages.contains(langCode)) {
      currentLanguage.value = langCode;
      Get.updateLocale(Locale(langCode));
      await _storageService.saveLanguage(langCode);
    }
  }
}
