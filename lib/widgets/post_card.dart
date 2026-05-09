import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../constants/app_colors.dart';
import '../widgets/heart_anim_button.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../controllers/home_controller.dart';
import '../screens/report_screen.dart';
import '../widgets/share_post_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showLargeHeart = false;

  void _showReportScreen(BuildContext context) {
    Get.to(
      () => ReportScreen(tipo: 'post', objetivoId: widget.post.id),
      fullscreenDialog: true,
      transition: Transition.downToUp,
    );
  }

  void _confirmDelete(BuildContext context, HomeController controller) {
    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: AppColors.containerBg.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.error.withOpacity(0.2), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.error,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '¿Eliminar publicación?',
                  style: GoogleFonts.inter(
                    color: AppColors.textHeader,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Esta acción borrará permanentemente tu publicación y no podrás recuperarla.',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          controller.deletePost(widget.post.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Eliminar permanentemente',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textHeader,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, HomeController controller) {
    final TextEditingController editController = TextEditingController(text: widget.post.caption);

    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: AppColors.containerBg.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: AppColors.accent.withOpacity(0.1), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Editar descripción',
                      style: GoogleFonts.inter(
                        color: AppColors.textHeader,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: TextField(
                    controller: editController,
                    maxLines: 5,
                    style: GoogleFonts.inter(color: AppColors.textHeader, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '¿Qué estás pensando?',
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        child: Text(
                          'Cancelar',
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          final newText = editController.text.trim();
                          Get.back();
                          if (newText != widget.post.caption) {
                            controller.editPost(widget.post.id, newText);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Guardar cambios',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPostOptions(BuildContext context, HomeController controller) {
    final isOwnPost = widget.post.usuario.id == controller.currentUserId.value;

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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwnPost) ...[
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textHeader,
                ),
                title: Text(
                  'Editar publicación',
                  style: GoogleFonts.inter(color: AppColors.textHeader),
                ),
                onTap: () {
                  Get.back();
                  _showEditDialog(context, controller);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: Text(
                  'Eliminar',
                  style: GoogleFonts.inter(color: AppColors.error),
                ),
                onTap: () {
                  Get.back();
                  _confirmDelete(context, controller);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(
                  Icons.person_remove_outlined,
                  color: AppColors.error,
                ),
                title: Text(
                  'Dejar de seguir',
                  style: GoogleFonts.inter(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Get.back();
                  controller.toggleFollow(
                    widget.post.usuario.id,
                    widget.post.usuario.nombre,
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.textHeader,
                ),
                title: Text(
                  'Ver perfil',
                  style: GoogleFonts.inter(color: AppColors.textHeader),
                ),
                onTap: () {
                  Get.back();
                  // TODO: Navegar al perfil
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.report_problem_outlined,
                  color: AppColors.error,
                ),
                title: Text(
                  'Reportar',
                  style: GoogleFonts.inter(color: AppColors.error),
                ),
                onTap: () {
                  Get.back();
                  _showReportScreen(context);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.textHeader),
              title: const Text('Cancelar'),
              onTap: () => Get.back(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postId: widget.post.id),
    );
  }

  void _handleDoubleTap(HomeController controller) {
    final isLiked = widget.post.likes.contains(controller.currentUserId.value);
    if (!isLiked) {
      controller.toggleLike(widget.post.id);
    }

    // Siempre mostramos la animación al hacer doble tap, estilo Instagram
    setState(() => _showLargeHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showLargeHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    widget.post.usuario.avatarUrl?.replaceAll('/svg', '/png') ??
                        'https://api.dicebear.com/7.x/avataaars/png?seed=${widget.post.usuario.nombre}',
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.post.usuario.nombre,
                  style: GoogleFonts.inter(
                    color: AppColors.textHeader,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => _showPostOptions(context, controller),
                ),
              ],
            ),
          ),

          // Post Image with Double Tap
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: GestureDetector(
                onDoubleTap: () => _handleDoubleTap(controller),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(
                          widget.post.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            color: AppColors.bg,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textMuted,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Imagen no disponible',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Large Heart Animation
                    if (_showLargeHeart)
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: value,
                              child: Icon(
                                Icons.favorite_rounded,
                                color: AppColors.textHeader.withOpacity(0.5),
                                size: 200,
                                shadows: const [
                                  Shadow(color: Colors.black26, blurRadius: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

          // Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                // Likes
                GetX<HomeController>(
                  builder: (controller) {
                    final isLiked = widget.post.likes.contains(
                      controller.currentUserId.value,
                    );
                    return Row(
                      children: [
                        HeartAnimButton(
                          isLiked: isLiked,
                          onTap: () => controller.toggleLike(widget.post.id),
                        ),
                        if (widget.post.likes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Text(
                              Post.formatCount(widget.post.likes.length),
                              style: GoogleFonts.inter(
                                color: AppColors.textHeader,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Comments
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: AppColors.textHeader,
                        size: 26,
                      ),
                      if (widget.post.commentsCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Text(
                            Post.formatCount(widget.post.commentsCount),
                            style: GoogleFonts.inter(
                              color: AppColors.textHeader,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    Get.bottomSheet(
                      SharePostBottomSheet(post: widget.post),
                      isScrollControlled: true,
                    );
                  },
                  child: const Icon(
                    Icons.send_rounded,
                    color: AppColors.textHeader,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),

          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 2.0,
              ),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.post.usuario.nombre} ',
                      style: GoogleFonts.inter(
                        color: AppColors.textHeader,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: widget.post.caption,
                      style: GoogleFonts.inter(
                        color: AppColors.textHeader,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Time Ago
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            child: Text(
              widget.post.timeAgo,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
