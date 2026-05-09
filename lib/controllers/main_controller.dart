import 'package:get/get.dart';
import 'profile_controller.dart';

class MainController extends GetxController {
  int selectedIndex = 0;

  void changePage(int index) {
    if (selectedIndex == index) return;
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
