import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../utils/ui_utils.dart';
import '../constants/app_colors.dart';
import '../controllers/notification_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/notification.dart';
import 'profile_screen.dart';
import '../widgets/safe_circle_avatar.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final themeController = Get.find<ThemeController>();
    
    // Actualizar lista automáticamente al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchNotifications();
    });

    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textHeader, size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'notifications'.tr,
            style: GoogleFonts.inter(
              color: AppColors.textHeader,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.person_add_alt_1_rounded, color: AppColors.textHeader, size: 24),
                  onPressed: () => showFollowRequestsBottomSheet(),
                ),
                if (controller.pendingRequestsCount.value > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 10,
                        minHeight: 10,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 8),
          ],
        ),
        body: Obx(() {
          final mainNotifications = controller.notifications.where((n) => n.type != NotificationType.followRequest).toList();

          if (controller.isLoading.value && mainNotifications.isEmpty) {
            return Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (mainNotifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 80, color: AppColors.textHeader.withOpacity(0.05)),
                  SizedBox(height: 16),
                  Text(
                    'no_notifications'.tr,
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16),
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
              itemCount: mainNotifications.length,
              itemBuilder: (context, index) {
                final notification = mainNotifications[index];
                return _NotificationItem(notification: notification);
              },
            ),
          );
        }),
      );
    });
  }

  static void showFollowRequestsBottomSheet() {
    final context = Get.context;
    if (context == null) return;
    
    final controller = Get.find<NotificationController>();
    final themeController = Get.find<ThemeController>();

    Get.bottomSheet(
      Obx(() {
        final requests = controller.notifications.where((n) => n.type == NotificationType.followRequest).toList();
        final isDark = themeController.isDarkMode.value;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Text(
                '${'follow_requests'.tr} (${requests.length})',
                style: GoogleFonts.inter(
                  color: AppColors.textHeader,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 20),

              if (requests.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_off_rounded, size: 60, color: AppColors.textMuted.withOpacity(0.1)),
                      SizedBox(height: 16),
                      Text(
                        'no_pending_requests'.tr,
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: requests.length,
                    separatorBuilder: (context, index) => Divider(color: AppColors.border, height: 24),
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return Row(
                        children: [
                          SafeCircleAvatar(
                            radius: 20,
                            url: req.sender.avatarUrl,
                            name: req.sender.nombre,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              req.sender.nombre,
                              style: TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => controller.respondToFollowRequest(req.sender.id, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('accept'.tr, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => controller.respondToFollowRequest(req.sender.id, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text('reject'.tr, style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              SizedBox(height: 20),
            ],
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
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
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
                ? AppColors.border
                : AppColors.accent.withOpacity(0.6),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Avatar con Badge de tipo
            GestureDetector(
              onTap: () => Get.to(() => ProfileScreen(userId: notification.sender.id), preventDuplicates: false),
              child: Stack(
                children: [
                  SafeCircleAvatar(
                    radius: 24,
                    url: notification.sender.avatarUrl,
                    name: notification.sender.nombre,
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
            SizedBox(width: 12),
            
            // Texto de la notificación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Get.to(() => ProfileScreen(userId: notification.sender.id), preventDuplicates: false),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(color: AppColors.textMain, fontSize: 14),
                        children: [
                          TextSpan(
                            text: notification.sender.nombre,
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' ${_getNotificationText(notification.type)}'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 8),

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
                  onTap: () {
                    if (following) {
                      UIUtils.showUnfollowBottomSheet(
                        userId: notification.sender.id,
                        nombre: notification.sender.nombre,
                        onConfirm: () => controller.toggleFollow(notification.sender.id),
                      );
                    } else {
                      controller.toggleFollow(notification.sender.id);
                    }
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: following ? Colors.transparent : AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: following ? AppColors.border : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (following)
                          Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.check, color: AppColors.textHeader, size: 14),
                          ),
                        Text(
                          following ? 'following_action'.tr : 'follow'.tr,
                          style: TextStyle(
                            color: following ? AppColors.textHeader : Colors.white,
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      final controller = Get.find<NotificationController>();
                      controller.respondToFollowRequest(notification.sender.id, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'accept'.tr,
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final controller = Get.find<NotificationController>();
                      controller.respondToFollowRequest(notification.sender.id, false);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'reject'.tr,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    });
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
      case NotificationType.like: return "notif_like".tr;
      case NotificationType.comment: return "notif_comment".tr;
      case NotificationType.follow: return "notif_follow".tr;
      case NotificationType.followRequest: return "notif_follow_req".tr;
      case NotificationType.followAccepted: return "notif_follow_accept".tr;
    }
  }
}

// Helpers top-level para que ambas clases los vean
String _formatTime(DateTime time) {
  final now = DateTime.now();
  final difference = now.difference(time);
  
  if (difference.inDays > 0) return 'ago_days'.trParams({'days': '${difference.inDays}'});
  if (difference.inHours > 0) return 'ago_hours'.trParams({'hours': '${difference.inHours}'});
  if (difference.inMinutes > 0) return 'ago_minutes'.trParams({'minutes': '${difference.inMinutes}'});
  return 'just_now'.tr;
}
