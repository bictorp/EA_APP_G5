import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/main_controller.dart';
import '../controllers/chat_controller.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'unimatch_screen.dart';
import '../constants/app_colors.dart';

import '../controllers/theme_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Widget> get _pages => [
    HomeScreen(),
    SearchScreen(),
    UnimatchScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    // Usamos GetBuilder para un control total y evitar bucles Obx
    return GetBuilder<MainController>(
      init: MainController(),
      builder: (controller) {
        return Obx(() {
          // Access themeMode to trigger rebuild when isDarkMode changes
          final _ = themeController.isDarkMode.value;
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: IndexedStack(
              index: controller.selectedIndex,
              children: _pages,
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: BottomNavigationBar(
                currentIndex: controller.selectedIndex,
                onTap: controller.changePage,
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.bg,
                selectedItemColor: AppColors.accent,
                unselectedItemColor: AppColors.textMuted.withOpacity(0.5),
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: [
                  BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
                  BottomNavigationBarItem(icon: Icon(Icons.style_rounded), label: 'Match'),
                  BottomNavigationBarItem(
                    icon: GetBuilder<ChatController>(
                      builder: (chatCtrl) {
                        final unread = chatCtrl.totalUnreadCount.value;
                        return Badge(
                          label: Text(unread > 999 ? '999+' : '$unread'),
                          isLabelVisible: unread > 0,
                          backgroundColor: AppColors.accent,
                          textColor: Colors.white,
                          child: Icon(Icons.chat_bubble_outline_rounded),
                        );
                      },
                    ),
                    label: 'Chats',
                  ),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
