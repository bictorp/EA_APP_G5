import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import '../constants/app_colors.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MainController controller = Get.put(MainController());

    final List<Widget> pages = [
      const HomeScreen(),
      const SearchScreen(),
      const Scaffold(backgroundColor: AppColors.bg, body: Center(child: Text('Modo Tinder / Conocer gente', style: TextStyle(color: AppColors.textHeader)))),
      const Scaffold(backgroundColor: AppColors.bg, body: Center(child: Text('Chats / Notificaciones', style: TextStyle(color: Colors.white)))),
      const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Profile', style: TextStyle(color: Colors.white)))),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: pages,
      )),
      bottomNavigationBar: Obx(() => Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changePage,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.bg,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted.withOpacity(0.5),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.style_rounded), label: 'Match'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chats'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      )),
    );
  }
}
