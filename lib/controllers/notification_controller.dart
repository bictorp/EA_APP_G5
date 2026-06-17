import 'dart:convert';
import 'package:get/get.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../screens/notifications_screen.dart';
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
  var pendingRequestsCount = 0.obs;
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
          _getSnackbarTitle(newNotification.type),
          '${newNotification.sender.nombre} ${_getSnackbarMessage(newNotification.type)}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.accent.withOpacity(0.9),
          colorText: Colors.white,
          duration: Duration(seconds: 4),
          icon: Icon(_getSnackbarIcon(newNotification.type), color: Colors.white),
          onTap: (snack) {
            if (newNotification.type == NotificationType.followRequest) {
              // Navegar y abrir el panel de solicitudes
              Get.to(() => NotificationsScreen())?.then((_) {
                // Opcional: acción al volver
              });
              // Pequeño delay para que la pantalla cargue antes de lanzar el bottom sheet
              Future.delayed(Duration(milliseconds: 300), () {
                NotificationsScreen.showFollowRequestsBottomSheet();
              });
            } else {
              Get.to(() => NotificationsScreen());
            }
          },
        );
      }
    });
  }

  String _getSnackbarTitle(NotificationType type) {
    switch (type) {
      case NotificationType.like: return '¡Nuevo Me gusta!';
      case NotificationType.follow: return 'Nuevo seguidor';
      case NotificationType.comment: return 'Nuevo comentario';
      case NotificationType.followRequest: return 'Solicitud de seguimiento';
      case NotificationType.followAccepted: return 'Solicitud aceptada';
    }
  }

  String _getSnackbarMessage(NotificationType type) {
    switch (type) {
      case NotificationType.like: return 'le ha dado me gusta a tu post.';
      case NotificationType.follow: return 'ha comenzado a seguirte.';
      case NotificationType.comment: return 'ha comentado en tu post.';
      case NotificationType.followRequest: return 'quiere seguirte.';
      case NotificationType.followAccepted: return 'ha aceptado tu solicitud.';
    }
  }

  IconData _getSnackbarIcon(NotificationType type) {
    switch (type) {
      case NotificationType.like: return Icons.favorite;
      case NotificationType.follow: return Icons.person_add;
      case NotificationType.comment: return Icons.comment;
      default: return Icons.notifications;
    }
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
      bool nowFollowing = false;
      if (myFollowing.contains(userId)) {
        myFollowing.remove(userId);
        nowFollowing = false;
      } else {
        myFollowing.add(userId);
        nowFollowing = true;
      }
      
      Get.snackbar(
        nowFollowing ? 'Siguiendo' : 'Ya no sigues a este usuario',
        nowFollowing ? 'Ahora verás sus publicaciones en tu feed.' : 'Has dejado de seguir a este usuario.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accent.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> respondToFollowRequest(String followerId, bool accept) async {
    final success = accept 
      ? await _userService.acceptFollowRequest(followerId)
      : await _userService.rejectFollowRequest(followerId);

    if (success) {
      Get.snackbar(
        accept ? 'Solicitud aceptada' : 'Solicitud rechazada',
        accept ? 'Ahora este usuario te sigue.' : 'Has rechazado la solicitud.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accent.withOpacity(0.8),
        colorText: Colors.white,
      );
      // Actualizar la lista para quitar la solicitud
      fetchNotifications();
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
    pendingRequestsCount.value = notifications.where((n) => n.type == NotificationType.followRequest).length;
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
