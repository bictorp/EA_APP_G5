import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../constants/app_colors.dart';
import '../widgets/heart_anim_button.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../controllers/home_controller.dart';
import '../screens/profile_screen.dart';
import '../widgets/share_post_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showLargeHeart = false;

  // Getter seguro: si HomeController no está registrado, devuelve null
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
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showLargeHeart = false);
    });
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
            if (ctrl != null && widget.post.usuario.id == _myId)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
                onTap: () { Get.back(); ctrl.deletePost(widget.post.id); },
              )
            else
              ListTile(
                leading: const Icon(Icons.account_circle_outlined, color: Colors.white),
                title: const Text('Ver perfil', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Get.back();
                  Get.to(() => ProfileScreen(userId: widget.post.usuario.id));
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
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
          // ── HEADER ───────────────────────────────────────────────
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

          // ── MEDIA ────────────────────────────────────────────────
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
                        if (_showLargeHeart)
                          const Icon(Icons.favorite, color: Colors.white, size: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── ACTION BAR ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Botón Like + Contador
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
                
                // Botón Comentarios + Contador
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
                
                // Botón Enviar
                GestureDetector(
                  onTap: () => _showShareSheet(context),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
                
                const Spacer(),
              ],
            ),
          ),

          // ── CAPTION ──────────────────────────────────────────────
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

          // ── FOOTER ───────────────────────────────────────────────
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
