import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../controllers/notification_controller.dart';
import '../models/notification.dart';
import 'profile_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    
    // Actualizar lista automáticamente al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchNotifications();
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Notificaciones',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.markAllRead(),
            child: const Text(
              'Leer todo',
              style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border_rounded, size: 80, color: Colors.white.withOpacity(0.05)),
                const SizedBox(height: 16),
                Text(
                  'Aún no hay nada por aquí',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          color: AppColors.accent,
          backgroundColor: AppColors.containerBg,
          child: ListView.builder(
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return _NotificationItem(notification: notification);
            },
          ),
        );
      }),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? AppColors.containerBg.withOpacity(0.4) 
            : AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead 
              ? Colors.white.withOpacity(0.05) 
              : AppColors.accent.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar con Badge de tipo
          GestureDetector(
            onTap: () => Get.to(() => ProfileScreen(userId: notification.sender.id)),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(notification.sender.avatarUrl ?? ''),
                  backgroundColor: AppColors.surface,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.containerBg, width: 2),
                    ),
                    child: Icon(
                      _getIconForType(notification.type),
                      size: 10,
                      color: _getColorForType(notification.type),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Texto de la notificación
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => ProfileScreen(userId: notification.sender.id)),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      children: [
                        TextSpan(
                          text: notification.sender.nombre,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: ' ${_getNotificationText(notification.type)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(notification.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),

          // Miniatura del Post (si aplica)
          if (notification.post != null && (notification.post!['imageUrl']?.isNotEmpty ?? false))
            GestureDetector(
              onTap: () {
                // Navegar al detalle del post (necesitaremos el ID)
                final postId = notification.post!['_id'] ?? notification.post!['id'];
                if (postId != null) {
                  Get.toNamed('/post-detail', arguments: postId);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  notification.post!['imageUrl'],
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Botón de Seguimiento
          if (notification.type == NotificationType.follow)
            Obx(() {
              final controller = Get.find<NotificationController>();
              final following = controller.isFollowing(notification.sender.id);
              
              return GestureDetector(
                onTap: () => controller.toggleFollow(notification.sender.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: following ? Colors.transparent : AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: following ? Colors.white.withOpacity(0.2) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (following)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      Text(
                        following ? 'Siguiendo' : 'Seguir',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            
          if (notification.type == NotificationType.followRequest)
            const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accent, size: 20),
        ],
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.like: return Icons.favorite;
      case NotificationType.comment: return Icons.comment;
      case NotificationType.follow: return Icons.person_add_rounded;
      case NotificationType.followRequest: return Icons.lock_clock;
      case NotificationType.followAccepted: return Icons.check_circle;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.like: return Colors.redAccent;
      case NotificationType.comment: return Colors.blueAccent;
      default: return AppColors.accent;
    }
  }

  String _getNotificationText(NotificationType type) {
    switch (type) {
      case NotificationType.like: return "le ha dado me gusta a tu publicación.";
      case NotificationType.comment: return "ha comentado tu publicación.";
      case NotificationType.follow: return "ha comenzado a seguirte.";
      case NotificationType.followRequest: return "te ha enviado una solicitud de seguimiento.";
      case NotificationType.followAccepted: return "ha aceptado tu solicitud.";
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) return 'hace ${difference.inDays} días';
    if (difference.inHours > 0) return 'hace aproximadamente ${difference.inHours} horas';
    if (difference.inMinutes > 0) return 'hace ${difference.inMinutes} minutos';
    return 'hace un momento';
  }
}
