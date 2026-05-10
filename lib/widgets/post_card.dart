import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../constants/app_colors.dart';
import '../widgets/heart_anim_button.dart';
import '../widgets/large_heart_anim.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../controllers/home_controller.dart';
import '../screens/profile_screen.dart';
import '../widgets/share_post_bottom_sheet.dart';
import '../utils/ui_utils.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showLargeHeart = false;

  HomeController? get _ctrl {
    if (Get.isRegistered<HomeController>()) return Get.find<HomeController>();
    return null;
  }

  String get _myId => _ctrl?.currentUserId.value ?? '';
  bool get _isLiked => widget.post.likes.any((u) => u.id == _myId);

  void _toggleLike() {
    _ctrl?.toggleLike(widget.post.id);
  }

  void _handleDoubleTap() {
    if (!_isLiked) _toggleLike();
    setState(() => _showLargeHeart = true);
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(postId: widget.post.id),
    );
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostBottomSheet(post: widget.post),
    );
  }

  void _showOptions(BuildContext context) {
    final ctrl = _ctrl;
    final bool isOwnPost = widget.post.usuario.id == _myId;

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.containerBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            
            // Ver Perfil
            ListTile(
              leading: const Icon(Icons.account_circle_outlined, color: Colors.white),
              title: const Text('Ver perfil', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                Get.to(() => ProfileScreen(userId: widget.post.usuario.id));
              },
            ),

            // Compartir
            ListTile(
              leading: const Icon(Icons.send_outlined, color: Colors.white),
              title: const Text('Compartir', style: TextStyle(color: Colors.white)),
              onTap: () {
                Get.back();
                _showShareSheet(context);
              },
            ),

            // Editar (Si es mío)
            if (isOwnPost && ctrl != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.white),
                title: const Text('Editar publicación', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.back();
                  _showEditDialog(context, ctrl);
                },
              ),

            // Dejar de seguir (Si no es mío)
            if (!isOwnPost && ctrl != null)
              ListTile(
                leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
                title: Text('Dejar de seguir a ${widget.post.usuario.nombre}', 
                  style: const TextStyle(color: AppColors.error)),
                onTap: () {
                  Get.back();
                  _confirmUnfollow(context, ctrl);
                },
              ),

            // Reportar (Si no es mío)
            if (!isOwnPost)
              ListTile(
                leading: const Icon(Icons.report_problem_outlined, color: AppColors.error),
                title: const Text('Reportar publicación', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Get.back();
                  UIUtils.showReportBottomSheet(
                    targetId: widget.post.id,
                    tipo: 'post',
                    title: 'esta publicación',
                  );
                },
              ),

            // Eliminar (Si es mío)
            if (isOwnPost && ctrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Eliminar publicación', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Get.back();
                  _confirmDelete(context, ctrl);
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, HomeController ctrl) {
    final TextEditingController editCtrl = TextEditingController(text: widget.post.caption);
    
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 10,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editar descripción',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Get.back();
                    ctrl.editPost(widget.post.id, editCtrl.text.trim());
                  },
                  child: Text(
                    'Guardar',
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 24),
            
            // Input Field
            TextField(
              controller: editCtrl,
              maxLines: 5,
              style: GoogleFonts.inter(color: Colors.white),
              autofocus: true,
              decoration: InputDecoration(
                hintText: '¿Qué estás pensando?',
                hintStyle: GoogleFonts.inter(color: Colors.white24),
                filled: true,
                fillColor: AppColors.containerBg.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmUnfollow(BuildContext context, HomeController ctrl) {
    UIUtils.showUnfollowBottomSheet(
      userId: widget.post.usuario.id,
      nombre: widget.post.usuario.nombre,
      onConfirm: () => ctrl.toggleFollow(widget.post.usuario.id, widget.post.usuario.nombre),
    );
  }

  void _confirmDelete(BuildContext context, HomeController ctrl) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.containerBg,
        title: const Text('¿Eliminar publicación?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Get.back();
              ctrl.deletePost(widget.post.id);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => ProfileScreen(userId: widget.post.usuario.id)),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white10,
                    backgroundImage: (widget.post.usuario.avatarUrl?.isNotEmpty ?? false)
                        ? NetworkImage(widget.post.usuario.avatarUrl!)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.to(() => ProfileScreen(userId: widget.post.usuario.id)),
                    child: Text(
                      widget.post.usuario.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
          ),

          // MEDIA
          if (widget.post.imageUrl?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onDoubleTap: _handleDoubleTap,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          widget.post.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.white10),
                        ),
                        LargeHeartAnim(
                          isVisible: _showLargeHeart,
                          onFinished: () => setState(() => _showLargeHeart = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ACTION BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeartAnimButton(
                        isLiked: _isLiked,
                        size: 24,
                        onTap: _toggleLike,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        Post.formatCount(widget.post.likes.length),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        Post.formatCount(widget.post.commentsCount),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _showShareSheet(context),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
                const Spacer(),
              ],
            ),
          ),

          // CAPTION
          if (widget.post.caption?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.post.usuario.nombre} ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      widget.post.caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // FOOTER
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Text(
              widget.post.timeAgo,
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
