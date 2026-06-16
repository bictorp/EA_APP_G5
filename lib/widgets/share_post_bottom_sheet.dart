import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/chat_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/post.dart';
import '../constants/app_colors.dart';

class SharePostBottomSheet extends StatefulWidget {
  final Post post;

  SharePostBottomSheet({super.key, required this.post});

  @override
  State<SharePostBottomSheet> createState() => _SharePostBottomSheetState();
}

class _SharePostBottomSheetState extends State<SharePostBottomSheet> {
  final ChatController chatController = Get.find<ChatController>();
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedContactIds = {};
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      return Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Compartir publicación',
                    style: GoogleFonts.inter(
                      color: AppColors.textHeader,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Comentario opcional
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _commentController,
                  style: TextStyle(color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                    contentPadding: const EdgeInsets.all(16),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Buscador de contactos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: TextEditingController(text: _searchQuery)..selection = TextSelection.collapsed(offset: _searchQuery.length),
                  style: TextStyle(color: AppColors.textMain),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar contactos...',
                    hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Lista de contactos
            Expanded(
              child: GetBuilder<ChatController>(
                builder: (controller) {
                  final filteredContacts = controller.contacts.where((c) {
                    final name = (c['nombre'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredContacts.isEmpty) {
                    return Center(
                      child: Text(
                        'No se encontraron contactos',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      final isSelected = _selectedContactIds.contains(contact['_id']);

                      return ListTile(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedContactIds.remove(contact['_id']);
                            } else {
                              _selectedContactIds.add(contact['_id']);
                            }
                          });
                        },
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundImage: contact['avatarUrl'] != null 
                            ? NetworkImage(contact['avatarUrl']) 
                            : null,
                          child: contact['avatarUrl'] == null 
                            ? Icon(Icons.person, color: AppColors.textHeader) 
                            : null,
                        ),
                        title: Text(
                          contact['nombre'] ?? 'Usuario',
                          style: GoogleFonts.inter(color: AppColors.textMain, fontWeight: FontWeight.w600),
                        ),
                        trailing: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.accent : AppColors.textMuted.withOpacity(0.5),
                              width: 2,
                            ),
                            color: isSelected ? AppColors.accent : Colors.transparent,
                          ),
                          child: isSelected 
                            ? Icon(Icons.check, size: 16, color: Colors.white) 
                            : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Botón de Enviar
            Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _selectedContactIds.isEmpty ? null : () async {
                    await chatController.sharePost(
                      widget.post.id, 
                      _selectedContactIds.toList(), 
                      _commentController.text
                    );
                    Get.back();
                    Get.snackbar(
                      '¡Enviado!',
                      'La publicación se ha compartido correctamente',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success.withOpacity(0.8),
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(20),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: AppColors.textMuted.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedContactIds.isEmpty 
                      ? 'Selecciona a alguien' 
                      : 'Enviar a ${_selectedContactIds.length} ${_selectedContactIds.length == 1 ? 'amigo' : 'amigos'}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
