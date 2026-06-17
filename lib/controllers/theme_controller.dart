import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/storage_service.dart';

class ThemeController extends GetxController {
  final StorageService _storageService = StorageService();
  var isDarkMode = true.obs;

  Future<ThemeController> init() async {
    final savedTheme = await _storageService.getThemeMode();
    if (savedTheme != null) {
      isDarkMode.value = savedTheme == 'dark';
    } else {
      isDarkMode.value = true; // Default to dark mode
    }
    return this;
  }

  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme(bool value) async {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
    await _storageService.saveThemeMode(value ? 'dark' : 'light');
  }
}
