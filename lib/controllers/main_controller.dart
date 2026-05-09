import 'package:get/get.dart';

class MainController extends GetxController {
  int selectedIndex = 0;

  void changePage(int index) {
    if (selectedIndex == index) return;
    selectedIndex = index;
    update();
  }
}
