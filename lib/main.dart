import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/create_post_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/post_detail_screen.dart';
import 'services/auth_service.dart';
import 'services/socket_service.dart';
import 'package:camera/camera.dart';
import 'controllers/chat_controller.dart';
import 'services/report_service.dart';
import 'controllers/theme_controller.dart';
import 'controllers/language_controller.dart';
import 'locales/app_translations.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Error inicializando cámaras: $e");
  }
  
  final AuthService authService = AuthService();
  final bool isLoggedIn = await authService.checkSession();

  // Inyectamos servicios básicos siempre
  Get.put(AuthService(), permanent: true);
  Get.put(ReportService(), permanent: true);
  await Get.putAsync(() => ThemeController().init(), permanent: true);
  await Get.putAsync(() => LanguageController().init(), permanent: true);

  if (isLoggedIn) {
    await SocketService().connect();
    Get.put(ChatController(), permanent: true);
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  
  MyApp({super.key, this.isLoggedIn = false});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();

    return Obx(() => GetMaterialApp(
      title: 'Univy App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      translations: AppTranslations(),
      locale: languageController.locale,
      fallbackLocale: const Locale('es'),
      initialRoute: isLoggedIn ? '/home' : '/login',
      getPages: [
        GetPage(name: '/', page: () => isLoggedIn ? MainScreen() : LoginScreen()),
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegisterScreen()),
        GetPage(name: '/home', page: () => MainScreen()),
        GetPage(name: '/create-post', page: () => CreatePostScreen()),
        GetPage(name: '/profile/edit', page: () => EditProfileScreen()),
        GetPage(name: '/post-detail', page: () => PostDetailScreen()),
      ],
      debugShowCheckedModeBanner: false,
    ));
  }
}
