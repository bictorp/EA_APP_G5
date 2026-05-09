import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../constants/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String? contactAvatar;

  const ChatDetailScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    this.contactAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatController _chatController = Get.find<ChatController>();
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _chatController.loadConversation(widget.contactId);
    
    // Auto-scroll to bottom when messages change
    _worker = ever(_chatController.messages, (_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    _chatController.sendMessage(widget.contactId, _textController.text.trim());
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_chatController.isSelectionMode.value,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _chatController.isSelectionMode.value) {
          _chatController.clearSelection();
        } else if (didPop) {
          _chatController.closeConversation();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: GetBuilder<ChatController>(
                builder: (controller) {
                  final myId = controller.currentUserId.value;
                  if (myId == null) return const Center(child: CircularProgressIndicator(color: AppColors.accent));

                  final messages = controller.messages.where((m) => 
                    (m.remitenteId == widget.contactId && m.destinatarioId == myId) ||
                    (m.remitenteId == myId && m.destinatarioId == widget.contactId)
                  ).toList();

                  if (controller.isMessagesLoading && messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                        final msg = messages[index];
                        final bool isMe = msg.remitenteId == myId;
                        final bool isSelected = controller.selectedMessageIds.contains(msg.id);
                        return _buildMessageBubble(msg, isMe, isSelected, myId);
                      },
                  );
                },
              ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: Obx(() => _chatController.isSelectionMode.value
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _chatController.clearSelection(),
            )
          : const BackButton()),
      titleSpacing: 0,
      title: Obx(() {
        if (_chatController.isSelectionMode.value) {
          return Text('${_chatController.selectedMessageIds.length}',
              style: const TextStyle(color: Colors.white, fontSize: 18));
        }
        return Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.contactAvatar != null 
                  ? NetworkImage(widget.contactAvatar!.replaceAll('/svg', '/png')) 
                  : null,
              child: widget.contactAvatar == null ? const Icon(Icons.person, size: 20) : null,
            ),
            const SizedBox(width: 10),
            Text(widget.contactName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        );
      }),
      actions: [
        Obx(() {
          if (_chatController.isSelectionMode.value) {
            return IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _showDeleteDialog(),
            );
          }
          return const SizedBox.shrink();
        }),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showChatOptionsSheet(),
        ),
      ],
    );
  }

  void _showDeleteDialog() {
    final bool canDeleteForEveryone = _chatController.selectedMessageIds.every((id) {
      final msg = _chatController.messages.firstWhere((m) => m.id == id);
      return msg.remitenteId == _chatController.currentUserId.value && !msg.eliminadoParaTodos;
    });

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Eliminar mensaje', style: TextStyle(color: Colors.white)),
        content: Text(
          _chatController.selectedMessageIds.length > 1
              ? '¿Deseas eliminar estos mensajes?'
              : '¿Deseas eliminar este mensaje?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.accent)),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: const Text('ELIMINAR PARA MÍ', style: TextStyle(color: AppColors.accent)),
            onPressed: () {
              _chatController.deleteMessages('me', widget.contactId);
              Get.back();
            },
          ),
          if (canDeleteForEveryone)
            TextButton(
              child: const Text('ELIMINAR PARA TODOS', style: TextStyle(color: AppColors.accent)),
              onPressed: () {
                _chatController.deleteMessages('everyone', widget.contactId);
                Get.back();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isMe, bool isSelected, String myId) {
    return GestureDetector(
      onLongPress: msg.eliminadoParaTodos ? null : () => _chatController.toggleSelection(msg.id),
      onTap: _chatController.isSelectionMode.value && !msg.eliminadoParaTodos
          ? () => _chatController.toggleSelection(msg.id)
          : null,
      child: Container(
        width: double.infinity,
        color: isSelected ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.eliminadoParaTodos
                  ? Colors.transparent
                  : (isMe ? AppColors.accent : AppColors.surface),
              border: msg.eliminadoParaTodos
                  ? Border.all(color: AppColors.textMuted.withOpacity(0.3))
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.post != null) _buildPostPreview(msg.post!, myId),
                if (msg.post != null && msg.contenido.isNotEmpty) const SizedBox(height: 8),
                if (msg.eliminadoParaTodos)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.block, size: 14, color: AppColors.textMuted.withOpacity(0.7)),
                      const SizedBox(width: 5),
                      Text(
                        msg.contenido,
                        style: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                    ],
                  )
                else if (msg.contenido.isNotEmpty)
                  Text(
                    msg.contenido,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                if (!msg.eliminadoParaTodos) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(msg.createdAt),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostPreview(dynamic post, String myId) {
    // Lógica de privacidad
    final bool isAuthorPublic = post.usuario.privado == false;
    final bool isFollowing = (post.usuario.seguidores as List?)?.contains(myId) ?? false;
    final bool isMyOwnPost = post.usuario.id == myId;

    final bool canSeePost = isAuthorPublic || isFollowing || isMyOwnPost;

    if (!canSeePost) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textMuted.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Publicación privada',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Get.to(() => PostDetailScreen(post: post));
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del post
            if (post.imageUrl != null && post.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  post.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            // Info del autor
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: NetworkImage(post.usuario.avatarUrl ?? ''),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.usuario.nombre ?? 'Usuario',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5), width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.accent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white),
              title: const Text('Ver perfil', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                Get.to(() => ProfileScreen(userId: widget.contactId));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              title: const Text('Vaciar chat', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Get.back();
                _confirmClearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_gmailerrorred_outlined, color: Colors.white),
              title: const Text('Reportar', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                Get.snackbar('Reportar', 'Función no disponible por ahora',
                    colorText: Colors.white, backgroundColor: Colors.black45);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.textMuted),
              title: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
              onTap: () => Get.back(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmClearChat() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Vaciar chat?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Se eliminarán todos los mensajes de esta conversación para ti. Esta acción no se puede deshacer.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _chatController.clearChat(widget.contactId);
            },
            child: const Text('Vaciar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
