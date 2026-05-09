import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../constants/app_colors.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mensajes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
      ),
      body: GetBuilder<ChatController>(
        builder: (controller) {
          if (controller.isContactsLoading.value && controller.contacts.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          if (controller.contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.textMuted.withOpacity(0.2)),
                  const SizedBox(height: 20),
                  const Text('No tienes conversaciones aún', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchContacts(),
            color: AppColors.accent,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: controller.contacts.length,
              separatorBuilder: (context, index) => Divider(color: AppColors.border.withOpacity(0.1), height: 1),
              itemBuilder: (context, index) {
                final contact = controller.contacts[index];
                final String contactId = contact['_id'];
                final String name = contact['nombre'] ?? 'Usuario';
                final String? avatarUrl = contact['avatarUrl'];

                return ListTile(
                  onTap: () => Get.to(() => ChatDetailScreen(contactId: contactId, contactName: name)),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white70) : null,
                  ),
                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    contact['lastMessage'] != null 
                      ? (contact['lastMessage'].length > 25 
                          ? '${contact['lastMessage'].substring(0, 25)}...' 
                          : contact['lastMessage'])
                      : 'Toca para chatear', 
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: GetBuilder<ChatController>(
                    id: 'unread_$contactId',
                    builder: (ctrl) {
                      final count = ctrl.unreadCounts[contactId] ?? 0;
                      if (count == 0) return const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20);
                      return Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                        child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

