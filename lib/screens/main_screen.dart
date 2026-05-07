import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../constants/app_colors.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MainController controller = Get.put(MainController());

    final List<Widget> pages = [
      const HomeScreen(),
      const SearchScreen(),
      const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Add Post', style: TextStyle(color: Colors.white)))),
      const Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Notifications', style: TextStyle(color: Colors.white)))),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() => IndexedStack(
        index: controller.selectedIndex.value,
        children: pages,
      )),
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.changePage,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white38,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Add'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Chats'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      )),
    );
  }
}
