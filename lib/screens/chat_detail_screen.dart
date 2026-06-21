import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/chat_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/message.dart';
import '../constants/app_colors.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';
import '../utils/ui_utils.dart';
import '../widgets/safe_circle_avatar.dart';

class ChatDetailScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String? contactAvatar;

  ChatDetailScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    this.contactAvatar,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  String? _highlightedMessageId;

  @override
  void initState() {
    super.initState();
    _chatController.loadConversation(widget.contactId);
  }

  @override
  void dispose() {
    _chatController.closeConversation();
    _textController.dispose();
    _scrollController.dispose();
    _messageKeys.clear();
    super.dispose();
  }

  void _scrollToMessage(String messageId) async {
    final key = _messageKeys[messageId];
    if (key != null && key.currentContext != null) {
      // 1. Resaltar el mensaje
      setState(() {
        _highlightedMessageId = messageId;
      });

      // 2. Hacer scroll
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );

      // 3. Quitar el resaltado tras 1.5 segundos
      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    } else {
      Get.snackbar(
        'far_message_title'.tr,
        'far_message_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black54,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    }
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      _chatController.sendMessage(widget.contactId, _textController.text.trim());
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String myId = _chatController.currentUserId.value ?? '';
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final _ = themeController.isDarkMode.value;
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GetBuilder<ChatController>(
                    builder: (controller) {
                      if (controller.isMessagesLoading && controller.messages.isEmpty) {
                        return Center(child: CircularProgressIndicator(color: AppColors.accent));
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        reverse: true,
                        cacheExtent: 5000,
                        itemCount: controller.messages.length,
                        itemBuilder: (context, index) {
                          final msg = controller.messages[index];
                          final isMe = msg.remitenteId == myId;
                          final isSelected = controller.selectedMessageIds.contains(msg.id);
                          
                          final key = _messageKeys.putIfAbsent(msg.id, () => GlobalKey());
                          
                          return Container(
                            key: key,
                            child: _buildMessageBubble(msg, isMe, isSelected, myId),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            _buildInput(),
          ],
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bg,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textHeader),
      leading: Obx(() => _chatController.isSelectionMode.value
          ? IconButton(
              icon: Icon(Icons.close),
              onPressed: () => _chatController.clearSelection(),
            )
          : BackButton()),
      titleSpacing: 0,
      title: Obx(() {
        if (_chatController.isSelectionMode.value) {
          return Text('${_chatController.selectedMessageIds.length}',
              style: TextStyle(color: AppColors.textHeader, fontSize: 18));
        }
        return Row(
          children: [
            SafeCircleAvatar(
              radius: 16,
              url: widget.contactAvatar?.replaceAll('/svg', '/png'),
              name: widget.contactName,
            ),
            SizedBox(width: 10),
            Text(widget.contactName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHeader)),
          ],
        );
      }),
      actions: [
        Obx(() {
          if (_chatController.isSelectionMode.value) {
            return IconButton(
              icon: Icon(Icons.delete, color: AppColors.textHeader),
              onPressed: () => _showDeleteDialog(),
            );
          }
          return const SizedBox.shrink();
        }),
        IconButton(
          icon: Icon(Icons.more_vert, color: AppColors.textHeader),
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
        title: Text('delete_message'.tr, style: TextStyle(color: AppColors.textHeader)),
        content: Text('delete_messages_confirm'.tr, style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.accent)),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text('delete_for_me'.tr, style: TextStyle(color: AppColors.accent)),
            onPressed: () {
              _chatController.deleteMessages('me', widget.contactId);
              Get.back();
            },
          ),
          if (canDeleteForEveryone)
            TextButton(
              child: Text('delete_for_all'.tr, style: TextStyle(color: AppColors.accent)),
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
    final contact = _chatController.contacts.firstWhereOrNull((c) => c['_id'] == widget.contactId);
    final isGroup = contact != null ? (contact['isGroup'] ?? false) : false;

    return Dismissible(
      key: Key('reply_${msg.id}'),
      direction: msg.eliminadoParaTodos ? DismissDirection.none : DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _chatController.replyingTo.value = msg;
          return false;
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 30),
        child: Icon(Icons.reply, color: AppColors.accent),
      ),
      child: GestureDetector(
        onLongPress: msg.eliminadoParaTodos ? null : () {
          _chatController.toggleSelection(msg.id);
          _showEmojiPicker(msg.id);
        },
        onTap: _chatController.isSelectionMode.value && !msg.eliminadoParaTodos
            ? () => _chatController.toggleSelection(msg.id)
            : null,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: double.infinity,
          color: _highlightedMessageId == msg.id 
              ? AppColors.accent.withOpacity(0.3) 
              : (isSelected ? AppColors.accent.withOpacity(0.15) : Colors.transparent),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe && isGroup) ...[
                  SafeCircleAvatar(
                    radius: 14,
                    url: msg.remitenteAvatar?.replaceAll('/svg', '/png'),
                    name: msg.remitenteNombre ?? 'Usuario',
                  ),
                  SizedBox(width: 8),
                ],
                Flexible(
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: msg.post != null 
                            ? EdgeInsets.zero 
                            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: (msg.eliminadoParaTodos || msg.post != null)
                              ? Colors.transparent
                              : (isMe ? AppColors.accent : AppColors.incomingBubble),
                          border: (msg.eliminadoParaTodos && msg.post == null)
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
                            if (!isMe && isGroup && msg.remitenteNombre != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  msg.remitenteNombre!,
                                  style: GoogleFonts.inter(
                                    color: Colors.deepOrangeAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                            if (msg.parentMessage != null) ...[
                              GestureDetector(
                                onTap: () => _scrollToMessage(msg.parentMessage!.id),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.black.withOpacity(0.15) : AppColors.bg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border(
                                      left: BorderSide(
                                        color: isMe ? Colors.white.withOpacity(0.5) : AppColors.accent,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.parentMessage!.remitenteId == myId 
                                            ? 'you'.tr 
                                            : (msg.parentMessage!.remitenteNombre ?? widget.contactName),
                                        style: GoogleFonts.inter(
                                          color: isMe ? Colors.white.withOpacity(0.9) : AppColors.accent,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        msg.parentMessage!.contenido,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: isMe ? Colors.white.withOpacity(0.6) : AppColors.textMuted,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (msg.post != null) _buildPostPreview(msg.post!, myId, isMe: isMe, hasComment: msg.contenido.isNotEmpty),
                            if (msg.post != null && msg.contenido.isNotEmpty) SizedBox(height: 4),
                            if (msg.eliminadoParaTodos)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.block, size: 14, color: AppColors.textMuted.withOpacity(0.7)),
                                  SizedBox(width: 5),
                                  Text(
                                    msg.contenido,
                                    style: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 13, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              )
                            else if (msg.contenido.isNotEmpty)
                              Container(
                                padding: msg.post != null 
                                    ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
                                    : EdgeInsets.zero,
                                decoration: msg.post != null
                                    ? BoxDecoration(
                                        color: isMe ? AppColors.accent : AppColors.incomingBubble,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                                          bottomRight: Radius.circular(isMe ? 4 : 16),
                                        ),
                                      )
                                    : null,
                                child: Text(
                                  msg.contenido,
                                  style: TextStyle(color: isMe ? Colors.white : AppColors.textHeader, fontSize: 15),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (!msg.eliminadoParaTodos)
                        Padding(
                          padding: EdgeInsets.only(
                            left: isMe ? 0 : 4,
                            right: isMe ? 4 : 0,
                            bottom: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(msg.createdAt),
                                style: TextStyle(
                                  color: AppColors.textMuted.withOpacity(0.6),
                                  fontSize: 9,
                                ),
                              ),
                              SizedBox(width: 4),
                              _buildReactionsBadge(msg),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostPreview(dynamic post, String myId, {required bool isMe, bool hasComment = false}) {
    final bool isAuthorPublic = post.usuario.privado == false;
    final bool isFollowing = (post.usuario.seguidores as List?)?.contains(myId) ?? false;
    final bool isMyOwnPost = post.usuario.id == myId;
    final bool canSeePost = isAuthorPublic || isFollowing || isMyOwnPost;

    if (!canSeePost) {
      return Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(hasComment ? 16 : (isMe ? 16 : 4)),
            bottomRight: Radius.circular(hasComment ? 16 : (isMe ? 4 : 16)),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.5), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'private_post'.tr,
                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => Get.to(() => PostDetailScreen(post: post)),
      child: Container(
        width: 220,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(hasComment ? 16 : (isMe ? 16 : 4)),
            bottomRight: Radius.circular(hasComment ? 16 : (isMe ? 4 : 16)),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del Autor
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  SafeCircleAvatar(
                    radius: 9,
                    url: post.usuario.avatarUrl,
                    name: post.usuario.nombre ?? 'Usuario',
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.usuario.nombre ?? 'Usuario',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Imagen de la publicación
            if (post.imageUrl != null && post.imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(post.imageUrl, fit: BoxFit.cover),
              ),
              
            // Pie de la publicación (Caption)
            if (post.caption != null && post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  post.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.5), width: 0.5)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() {
              final replyingTo = _chatController.replyingTo.value;
              if (replyingTo == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            replyingTo.remitenteId == _chatController.currentUserId.value ? 'you'.tr : widget.contactName,
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            replyingTo.contenido,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                      onPressed: () => _chatController.replyingTo.value = null,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(color: AppColors.textHeader),
                    decoration: InputDecoration(
                      hintText: 'write_message'.tr,
                      hintStyle: TextStyle(color: AppColors.textMuted),
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
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: AppColors.accent),
                  onPressed: _sendMessage,
                ),
              ],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person_outline, color: AppColors.textHeader),
              title: Text('view_profile'.tr, style: TextStyle(color: AppColors.textHeader)),
              onTap: () {
                Get.back();
                Get.to(() => ProfileScreen(userId: widget.contactId), preventDuplicates: false);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              title: Text('clear_chat'.tr, style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Get.back();
                _confirmClearChat();
              },
            ),
            ListTile(
              leading: Icon(Icons.report_gmailerrorred_outlined, color: AppColors.textHeader),
              title: Text('report'.tr, style: TextStyle(color: AppColors.textHeader)),
              onTap: () {
                Get.back();
                final lastMsg = _chatController.messages.isNotEmpty ? _chatController.messages.first : null;
                if (lastMsg != null) {
                  UIUtils.showReportBottomSheet(
                    targetId: lastMsg.id,
                    tipo: 'chat',
                    title: 'conversation_with'.trParams({'name': widget.contactName}),
                  );
                } else {
                  UIUtils.showReportBottomSheet(
                    targetId: widget.contactId,
                    tipo: 'user',
                    title: 'user_with_name'.trParams({'name': widget.contactName}),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.close, color: AppColors.textMuted),
              title: Text('cancel'.tr, style: TextStyle(color: AppColors.textMuted)),
              onTap: () => Get.back(),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmClearChat() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('clear_chat_confirm_title'.tr, style: TextStyle(color: Colors.white)),
        content: Text('clear_chat_confirm_msg'.tr, style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr, style: TextStyle(color: Colors.white))),
          TextButton(
            onPressed: () {
              Get.back();
              _chatController.clearChat(widget.contactId);
            },
            child: Text('clear'.tr, style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker(String messageId) {
    final List<String> commonEmojis = ['❤️', '👍', '😂', '😮', '😢', '🙏'];
    final List<String> allEmojis = [
      '🔥', '✨', '💯', '👏', '🙌', '🎉', '🤩', '🤔', '🤐', '😴', '💩', '💀',
      '🚀', '⭐', '🎈', '🎁', '🍔', '🍦', '🍕', '🍺', '⚽', '🏀', '🎮', '🎸',
      '🌈', '⚡', '💡', '🔔', '📌', '📍', '✅', '❌', '⚠️', '🆘', '🛑', '🏁'
    ];

    bool isExpanded = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ...commonEmojis.map((emoji) => GestureDetector(
                        onTap: () {
                          Get.back();
                          _chatController.reactToMessage(messageId, emoji, widget.contactId);
                        },
                        child: Text(
                          emoji, 
                          style: TextStyle(
                            fontSize: 28, 
                            color: emoji == '❤️' ? Colors.red : null
                          )
                        ),
                      )),
                      // Botón expandir
                      if (!isExpanded)
                        GestureDetector(
                          onTap: () => setSheetState(() => isExpanded = true),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                            child: Icon(Icons.add, color: Colors.white, size: 22),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isExpanded) ...[
                  Divider(color: Colors.white10, height: 40, thickness: 1),
                  SizedBox(
                    height: 250,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: allEmojis.length,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          Get.back();
                          _chatController.reactToMessage(messageId, allEmojis[index], widget.contactId);
                        },
                        child: Center(
                          child: Text(allEmojis[index], style: TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                  ),
                ],
                Divider(color: Colors.white10, height: 32, thickness: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    leading: Icon(Icons.report_gmailerrorred_outlined, color: Colors.white70),
                    title: Text('report_message'.tr, style: TextStyle(color: Colors.white70)),
                    onTap: () {
                      Get.back();
                      UIUtils.showReportBottomSheet(
                        targetId: messageId,
                        tipo: 'chat',
                        title: 'message'.tr,
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
      isScrollControlled: true,
    ).then((_) {
      _chatController.clearSelection();
    });
  }

  Widget _buildReactionsBadge(Message msg) {
    if (msg.reactions == null || msg.reactions!.isEmpty) return const SizedBox.shrink();

    final Map<String, int> emojiCounts = {};
    for (var r in msg.reactions!) {
      emojiCounts[r.emoji] = (emojiCounts[r.emoji] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: emojiCounts.entries.map((entry) {
          final isHeart = entry.key == '❤️' || entry.key == '♥️';
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              '${entry.key}${entry.value > 1 ? entry.value : ""}',
              style: TextStyle(
                fontSize: 13, 
                color: isHeart ? Colors.red : Colors.white
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
