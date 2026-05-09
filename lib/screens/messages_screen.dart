import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../constants/app_colors.dart';
import 'chat_detail_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.put(ChatController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Mensajes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.bg,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => controller.fetchContacts(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.contacts.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.accent));
        }

        if (controller.contacts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textMuted.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No tienes contactos mutuos todavía',
                  style: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sigue a personas que te sigan para chatear',
                  style: TextStyle(color: AppColors.textMuted.withOpacity(0.3), fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: controller.contacts.length,
          separatorBuilder: (context, index) => Divider(color: AppColors.border.withOpacity(0.2), height: 1),
          itemBuilder: (context, index) {
            final contact = controller.contacts[index];
            final String name = contact['nombre'] ?? 'Usuario';
            final String? avatarUrl = contact['avatarUrl'];
            final String contactId = contact['_id'];

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surface,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, color: Colors.white70) : null,
              ),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Toca para chatear', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              onTap: () {
                Get.to(() => ChatDetailScreen(
                  contactId: contactId,
                  contactName: name,
                  contactAvatar: avatarUrl,
                ));
              },
            );
          },
        );
      }),
    );
  }
}
