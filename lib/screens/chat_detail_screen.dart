import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../constants/app_colors.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _chatController.loadConversation(widget.contactId);
    
    // Auto-scroll to bottom when messages change
    ever(_chatController.messages, (_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
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
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (_chatController.isLoading.value && _chatController.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                }

                final messages = _chatController.messages;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg.remitenteId == _chatController.currentUserId;
                    
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              }),
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
              backgroundImage: widget.contactAvatar != null ? NetworkImage(widget.contactAvatar!) : null,
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
      ],
    );
  }

  void _showDeleteDialog() {
    final bool canDeleteForEveryone = _chatController.selectedMessageIds.every((id) {
      final msg = _chatController.messages.firstWhere((m) => m.id == id);
      return msg.remitenteId == _chatController.currentUserId && !msg.eliminadoParaTodos;
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

  Widget _buildMessageBubble(Message msg, bool isMe) {
    return Obx(() {
      final bool isSelected = _chatController.selectedMessageIds.contains(msg.id);
      
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
                  else
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
    });
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
}
