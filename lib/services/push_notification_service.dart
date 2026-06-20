import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/api_constants.dart';
import '../firebase_options.dart';
import 'auth_service.dart';

/// Manejador global para notificaciones en segundo plano (Terminated o Background).
/// Debe ser una función top-level (fuera de cualquier clase) y estar anotada con @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegurar que los bindings de Flutter estén listos si necesitas acceder a plugins nativos
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Notificación recibida en Background/Terminated: ${message.messageId}");
  // Aquí puedes procesar datos de la notificación, pero no puedes pintar interfaces gráficas directamente.
}

class PushNotificationService {
  late final FirebaseMessaging _fcm;
  final AuthService _authService = AuthService();

  /// Inicializa Firebase y configura todos los listeners de FCM.
  Future<void> initialize() async {
    // 1. Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    _fcm = FirebaseMessaging.instance;

    // 2. Registrar el Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Configurar los Listeners en los distintos estados
    _setupNotificationListeners();

    // 4. Capturar y guardar el FCM Token si el usuario ya está logueado
    await checkAndUploadToken();
  }

  /// Solicita permisos nativos al usuario (especialmente importante en iOS y Android 13+)
  Future<void> requestPermissions() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permisos de notificaciones concedidos por el usuario.');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('Permisos de notificaciones concedidos de manera provisional.');
    } else {
      print('Permisos de notificaciones denegados por el usuario.');
    }
  }

  /// Obtiene el FCM token único del dispositivo de forma asíncrona.
  Future<String?> getFCMToken() async {
    try {
      // En iOS, es recomendable esperar a tener el token APNs antes de pedir el token FCM
      if (Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          print('Esperando por el APNs token...');
          // Opcional: Reintentar brevemente si es necesario
        }
      }
      
      String? token = await _fcm.getToken();
      print('FCM Token obtenido: $token');
      return token;
    } catch (e) {
      print('Error al obtener FCM Token: $e');
      return null;
    }
  }

  /// Comprueba si el usuario está autenticado y sube el FCM token al servidor.
  Future<void> checkAndUploadToken() async {
    final isLoggedIn = await _authService.checkSession();
    if (!isLoggedIn) {
      print('Usuario no logueado. Saltando el envío del FCM token.');
      return;
    }

    String? fcmToken = await getFCMToken();
    if (fcmToken != null) {
      await sendTokenToBackend(fcmToken);
    }

    // Escuchar actualizaciones dinámicas del token en caso de que Firebase lo refresque
    _fcm.onTokenRefresh.listen((newToken) async {
      print('FCM Token refrescado automáticamente por Firebase: $newToken');
      await sendTokenToBackend(newToken);
    });
  }

  /// Envía el FCM Token a la API central usando la instancia centralizada de Dio
  Future<bool> sendTokenToBackend(String fcmToken) async {
    try {
      // Usamos AuthService.dio que ya tiene configurado el AuthInterceptor (inyecta Bearer JWT y maneja refrescos)
      final response = await AuthService.dio.put(
        '${ApiConstants.baseUrl}/usuarios/fcm-token',
        data: {'fcmToken': fcmToken},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('FCM Token actualizado correctamente en el backend.');
        return true;
      }
      print('FCM Token no pudo ser actualizado. Status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error al enviar el FCM Token al backend: $e');
      return false;
    }
  }

  /// Configuración de los listeners de mensajería para Foreground y Background/Opened
  void _setupNotificationListeners() {
    // --- 1. FOREGROUND (App en primer plano) ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notificación recibida en FOREGROUND!');
      print('Título: ${message.notification?.title}');
      print('Cuerpo: ${message.notification?.body}');
      print('Datos adicionales (Data): ${message.data}');

      // Mostrar un elemento interactivo en pantalla como SnackBar usando GetX (o Snackbars/Dialogs estándar)
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'Nueva Notificación',
          message.notification!.body ?? '',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.indigo.withOpacity(0.9),
          colorText: Colors.white,
          margin: const EdgeInsets.all(15),
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.notifications_active, color: Colors.white),
          mainButton: message.data.isNotEmpty 
              ? TextButton(
                  onPressed: () {
                    _handleNotificationNavigation(message.data);
                  },
                  child: const Text('VER', style: TextStyle(color: Colors.yellowAccent)),
                )
              : null,
        );
      }
    });

    // --- 2. BACKGROUND (App minimizada, el usuario pulsa sobre la notificación) ---
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('El usuario abrió la app desde la notificación (Background)!');
      _handleNotificationNavigation(message.data);
    });

    // --- 3. TERMINATED (App cerrada por completo, el usuario pulsa sobre la notificación) ---
    // Este caso se evalúa al arrancar la app
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('La app fue abierta desde un estado TERMINATED a través de una notificación!');
        _handleNotificationNavigation(message.data);
      }
    });
  }

  /// Maneja la redirección o navegación según el payload `data` recibido en la notificación.
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    print('Datos de redirección: $data');
    
    // Ejemplo de navegación modular usando GetX
    // if (data.containsKey('route')) {
    //   Get.toNamed(data['route'], arguments: data);
    // }
  }
}
