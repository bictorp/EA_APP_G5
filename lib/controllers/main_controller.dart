import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'profile_controller.dart';
import 'home_controller.dart';
import 'notification_controller.dart';

class MainController extends GetxController {
  int selectedIndex = 0;

  @override
  void onInit() {
    super.onInit();
    // Inicializar controlador de notificaciones globalmente
    Get.put(NotificationController(), permanent: true);
  }

  void changePage(int index) {
    if (selectedIndex == index) {
      // Si ya estamos en Home (index 0) y pulsamos Home, scroll to top
      if (index == 0) {
        try {
          if (Get.isRegistered<HomeController>()) {
            final homeCtrl = Get.find<HomeController>();
            if (homeCtrl.scrollController.hasClients) {
              homeCtrl.scrollController.animateTo(
                0,
                duration: Duration(milliseconds: 600),
                curve: Curves.easeOutQuart,
              );
            }
          }
        } catch (_) {}
      }
      return;
    }
    
    selectedIndex = index;
    
    // Si entramos en el perfil, forzamos refresco de datos
    if (index == 4) {
      try {
        if (Get.isRegistered<ProfileController>(tag: 'me')) {
          Get.find<ProfileController>(tag: 'me').loadUserData();
        }
      } catch (_) {}
    }
    
    update();
  }
}
