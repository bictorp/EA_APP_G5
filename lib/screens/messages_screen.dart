import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../constants/app_colors.dart';
import 'chat_detail_screen.dart';
import 'assistant_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 26),
            onPressed: () => Get.to(() => const AssistantScreen()),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            color: AppColors.surface,
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'new_chat') {
                _showNewChatSheet(context, Get.find<ChatController>());
              } else if (value == 'join_group') {
                Get.snackbar(
                  'Próximamente',
                  'La funcionalidad de unirse a grupos estará disponible pronto',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF1E293B),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(15),
                  duration: const Duration(seconds: 3),
                );
              } else if (value == 'create_group') {
                Get.snackbar(
                  'Próximamente',
                  'La creación de grupos se implementará en una futura actualización',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF1E293B),
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(15),
                  duration: const Duration(seconds: 3),
                );
              }
              print('Seleccionado: $value');
            },
            itemBuilder: (BuildContext context) => [
              _buildPopupItem('Iniciar Chat', Icons.chat_outlined, 'new_chat'),
              _buildPopupItem('Unirse a Grupo', Icons.group_add_outlined, 'join_group'),
              _buildPopupItem('Crear Grupo', Icons.groups_outlined, 'create_group'),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GetBuilder<ChatController>(
        builder: (controller) {
          if (controller.isContactsLoading && controller.contacts.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          // Filtrar solo chats con mensajes (chats activos)
          final activeContacts = controller.contacts.where((c) => c['lastMessage'] != null).toList();

          if (activeContacts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => controller.fetchContacts(),
              color: AppColors.accent,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.textMuted.withOpacity(0.2)),
                  const SizedBox(height: 20),
                  const Center(child: Text('No tienes conversaciones activas', style: TextStyle(color: AppColors.textMuted, fontSize: 16))),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => _showNewChatSheet(context, controller),
                      child: const Text('Iniciar una nueva', style: TextStyle(color: AppColors.accent)),
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
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    backgroundImage: avatarUrl != null 
                        ? NetworkImage(avatarUrl.replaceAll('/svg', '/png')) 
                        : null,
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

  void _showNewChatSheet(BuildContext context, ChatController controller) {
    // Lista inicial de candidatos
    final List<dynamic> allCandidates = controller.contacts.where((c) => c['lastMessage'] == null).toList();
    String searchQuery = ""; // Declarada aquí para persistir entre reconstrucciones del sheet
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
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
                const SizedBox(height: 20),
                const Text(
                  'Iniciar nuevo chat',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Divider(color: Colors.white.withOpacity(0.1), thickness: 1),
                const SizedBox(height: 15),
                
                // Buscador
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.containerBg.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withOpacity(0.2)),
                  ),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar amigos...',
                      hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
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
                const SizedBox(height: 20),

                if (filteredCandidates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 48, color: AppColors.textMuted.withOpacity(0.3)),
                        const SizedBox(height: 10),
                        Text(
                          searchQuery.isEmpty ? 'No hay nuevos contactos disponibles' : 'No se encontraron resultados',
                          style: const TextStyle(color: AppColors.textMuted),
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
                          leading: CircleAvatar(
                            backgroundImage: contact['avatarUrl'] != null 
                                ? NetworkImage(contact['avatarUrl']) 
                                : null,
                            child: contact['avatarUrl'] == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(
                            contact['nombre'] ?? 'Usuario',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text('Disponible para chatear', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

