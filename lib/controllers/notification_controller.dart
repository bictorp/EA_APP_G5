import 'dart:convert';
import 'package:get/get.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../constants/app_colors.dart';
import 'package:flutter/material.dart';

class NotificationController extends GetxController {
  final NotificationService _service = NotificationService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final SocketService _socketService = SocketService();
  
  var notifications = <NotificationModel>[].obs;
  var myFollowing = <String>[].obs;
  var isLoading = true.obs;
  var hasUnread = false.obs;
  var currentPage = 1;
  var hasNextPage = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFollowing();
    fetchNotifications();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _socketService.off('new_notification'); // Limpiar previos
    _socketService.on('new_notification', (data) {
      if (data != null) {
        print('[Socket] Nueva notificación recibida en tiempo real');
        final newNotification = NotificationModel.fromJson(data);
        
        // Evitar duplicados por ID
        if (notifications.any((n) => n.id == newNotification.id)) {
          print('[Socket] Notificación duplicada ignorada: ${newNotification.id}');
          return;
        }
        
        // Insertar al inicio y refrescar el observable
        notifications.insert(0, newNotification);
        notifications.refresh();
        
        hasUnread.value = true;
        
        Get.snackbar(
          'Nueva interacción',
          'Alguien ha interactuado con tu contenido',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.accent.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          icon: const Icon(Icons.favorite, color: Colors.white),
        );
      }
    });
  }

  @override
  void onClose() {
    _socketService.off('new_notification');
    super.onClose();
  }

  Future<void> _loadFollowing() async {
    final userData = await _storageService.getUserData();
    if (userData != null) {
      final userMap = jsonDecode(userData);
      final myId = userMap['_id'];
      if (myId != null) {
        final following = await _userService.getFollowing(myId);
        myFollowing.assignAll(following);
      }
    }
  }

  bool isFollowing(String userId) {
    return myFollowing.contains(userId);
  }

  Future<void> toggleFollow(String userId) async {
    final success = await _userService.toggleFollow(userId);
    if (success) {
      if (myFollowing.contains(userId)) {
        myFollowing.remove(userId);
      } else {
        myFollowing.add(userId);
      }
    }
  }

  Future<void> fetchNotifications() async {
    try {
      if (notifications.isEmpty) isLoading.value = true;
      currentPage = 1;
      final result = await _service.getNotifications(page: currentPage);
      
      notifications.assignAll(result['notifications'] as List<NotificationModel>);
      hasNextPage.value = result['hasNextPage'];
      
      _checkUnread();
      
      // Marcar como leídas automáticamente al cargar la sección
      if (hasUnread.value) {
        markAllRead();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMore() async {
    if (!hasNextPage.value) return;
    
    currentPage++;
    final result = await _service.getNotifications(page: currentPage);
    notifications.addAll(result['notifications'] as List<NotificationModel>);
    hasNextPage.value = result['hasNextPage'];
  }

  void _checkUnread() {
    hasUnread.value = notifications.any((n) => !n.isRead);
  }

  Future<void> markAllRead() async {
    final success = await _service.markAllAsRead();
    if (success) {
      // Update local state
      for (var i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          final n = notifications[i];
          notifications[i] = NotificationModel(
            id: n.id,
            recipient: n.recipient,
            sender: n.sender,
            type: n.type,
            post: n.post,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
      }
      hasUnread.value = false;
    }
  }
}
