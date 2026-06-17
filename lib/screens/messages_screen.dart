import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../controllers/theme_controller.dart';
import '../constants/app_colors.dart';
import 'chat_detail_screen.dart';
import 'assistant_screen.dart';
import '../widgets/safe_circle_avatar.dart';

class MessagesScreen extends StatelessWidget {
  MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final _ = themeController.isDarkMode.value;
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          title: Text('messages'.tr, style: TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.bg,
          elevation: 0,
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(Icons.smart_toy_outlined, color: AppColors.textHeader, size: 26),
              onPressed: () => Get.to(() => AssistantScreen()),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.add, color: AppColors.textHeader, size: 28),
              color: AppColors.surface,
              offset: Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'new_chat') {
                  _showNewChatSheet(context, Get.find<ChatController>());
                } else if (value == 'join_group') {
                  Get.snackbar(
                    'soon'.tr,
                    'join_group_soon'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Color(0xFF1E293B),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(15),
                    duration: Duration(seconds: 3),
                  );
                } else if (value == 'create_group') {
                  Get.snackbar(
                    'soon'.tr,
                    'create_group_soon'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Color(0xFF1E293B),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(15),
                    duration: Duration(seconds: 3),
                  );
                }
                print('Seleccionado: $value');
              },
              itemBuilder: (BuildContext context) => [
                _buildPopupItem('start_chat'.tr, Icons.chat_outlined, 'new_chat'),
                _buildPopupItem('join_group'.tr, Icons.group_add_outlined, 'join_group'),
                _buildPopupItem('create_group'.tr, Icons.groups_outlined, 'create_group'),
              ],
            ),
            SizedBox(width: 8),
          ],
        ),
        body: GetBuilder<ChatController>(
          builder: (controller) {
            if (controller.isContactsLoading && controller.contacts.isEmpty) {
              return Center(child: CircularProgressIndicator(color: AppColors.accent));
            }

            // Filtrar solo chats con mensajes (chats activos)
            final activeContacts = controller.contacts.where((c) => c['lastMessage'] != null).toList();

            if (activeContacts.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => controller.fetchContacts(),
                color: AppColors.accent,
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.textMuted.withOpacity(0.2)),
                    SizedBox(height: 20),
                    Center(child: Text('no_chats'.tr, style: TextStyle(color: AppColors.textMuted, fontSize: 16))),
                    SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => _showNewChatSheet(context, controller),
                        child: Text('start_new_chat'.tr, style: TextStyle(color: AppColors.accent)),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchContacts(),
              color: AppColors.accent,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: activeContacts.length,
                separatorBuilder: (context, index) => Divider(color: AppColors.border.withOpacity(0.1), height: 1),
                itemBuilder: (context, index) {
                  final contact = activeContacts[index];
                  final String contactId = contact['_id'];
                  final String name = contact['nombre'] ?? 'Usuario';
                  final String? avatarUrl = contact['avatarUrl'];

                  return ListTile(
                    onTap: () => Get.to(() => ChatDetailScreen(
                          contactId: contactId, 
                          contactName: name,
                          contactAvatar: avatarUrl,
                        )),
                    leading: SafeCircleAvatar(
                      radius: 20,
                      url: avatarUrl?.replaceAll('/svg', '/png'),
                      name: name,
                    ),
                    title: Text(name, style: TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.w600)),
                    subtitle: () {
                      String? lastMsg = contact['lastMessage'];
                      if (lastMsg == 'Envió una publicación') {
                        lastMsg = 'sent_post_notif'.tr;
                      } else if (lastMsg == 'El mensaje ha sido eliminado') {
                        lastMsg = 'message_deleted_placeholder'.tr;
                      }
                      return Text(
                        lastMsg != null 
                        ? (lastMsg.length > 25 
                            ? '${lastMsg.substring(0, 25)}...' 
                            : lastMsg)
                        : 'tap_to_chat'.tr, 
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    }(),
                    trailing: GetBuilder<ChatController>(
                      id: 'unread_$contactId',
                      builder: (ctrl) {
                        final count = ctrl.unreadCounts[contactId] ?? 0;
                        if (count == 0) return Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20);
                        return Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          child: Text('$count', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
    });
  }

  void _showNewChatSheet(BuildContext context, ChatController controller) {
    // Lista inicial de candidatos
    final List<dynamic> allCandidates = controller.contacts.where((c) => c['lastMessage'] == null).toList();
    String searchQuery = ""; // Declarada aquí para persistir entre reconstrucciones del sheet
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Filtrar candidatos según la búsqueda actual
          final filteredCandidates = allCandidates.where((c) {
            final name = (c['nombre'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Ajuste para el teclado
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'start_new_chat_title'.tr,
                  style: TextStyle(color: AppColors.textHeader, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 15),
                Divider(color: AppColors.borderWhite, thickness: 1),
                SizedBox(height: 15),
                
                // Buscador
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.containerBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withOpacity(0.2)),
                  ),
                  child: TextField(
                    style: TextStyle(color: AppColors.textHeader),
                    decoration: InputDecoration(
                      hintText: 'search_friends'.tr,
                      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                SizedBox(height: 20),

                if (filteredCandidates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.textMuted.withOpacity(0.3)),
                        SizedBox(height: 10),
                        Text(
                          searchQuery.isEmpty ? 'no_new_contacts'.tr : 'no_results'.tr,
                          style: TextStyle(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCandidates.length,
                      itemBuilder: (context, index) {
                        final contact = filteredCandidates[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                          leading: SafeCircleAvatar(
                            radius: 20,
                            url: contact['avatarUrl'],
                            name: contact['nombre'] ?? 'Usuario',
                          ),
                          title: Text(
                            contact['nombre'] ?? 'Usuario',
                            style: TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text('available_to_chat'.tr, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
                          onTap: () {
                            Get.back(); // Cerrar sheet
                            Get.to(() => ChatDetailScreen(
                              contactId: contact['_id'],
                              contactName: contact['nombre'] ?? 'Usuario',
                              contactAvatar: contact['avatarUrl'],
                            ));
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String title, IconData icon, String value) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          SizedBox(width: 12),
          Text(title, style: TextStyle(color: AppColors.textHeader, fontSize: 14)),
        ],
      ),
    );
  }
}

