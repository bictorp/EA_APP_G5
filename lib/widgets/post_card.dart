import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../constants/app_colors.dart';
import '../controllers/home_controller.dart';
import 'heart_anim_button.dart';
import 'comments_bottom_sheet.dart';
import '../screens/report_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showLargeHeart = false;

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(postId: widget.post.id),
    );
  }

  void _showReportScreen(BuildContext context) {
    Get.to(
      () => ReportScreen(tipo: 'post', objetivoId: widget.post.id),
      fullscreenDialog: true,
      transition: Transition.downToUp,
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Tu publicación',
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              const Divider(color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.textHeader),
                title: Text('Editar publicación', style: GoogleFonts.inter(color: AppColors.textHeader)),
                onTap: () {
                  Get.back();
                  // TODO: Editar
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('Eliminar', style: GoogleFonts.inter(color: AppColors.error)),
                onTap: () {
                  Get.back();
                  // TODO: Eliminar
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.person_remove_outlined, color: AppColors.error),
                title: Text('Dejar de seguir', style: GoogleFonts.inter(color: AppColors.error, fontWeight: FontWeight.w600)),
                onTap: () {
                  Get.back();
                  controller.toggleFollow(widget.post.usuario.id, widget.post.usuario.nombre);
                },
              ),
              ListTile(
                leading: const Icon(Icons.account_circle_outlined, color: AppColors.textHeader),
                title: Text('Ver perfil', style: GoogleFonts.inter(color: AppColors.textHeader)),
                onTap: () {
                  Get.back();
                  // TODO: Navegar al perfil
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem_outlined, color: AppColors.error),
                title: Text('Reportar', style: GoogleFonts.inter(color: AppColors.error)),
                onTap: () {
                  Get.back();
                  _showReportScreen(context);
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
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
    final HomeController controller = Get.find<HomeController>();

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(widget.post.usuario.avatarUrl?.replaceAll('/svg', '/png') ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${widget.post.usuario.nombre}'),
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
                  icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                  onPressed: () => _showPostOptions(context, controller),
                ),
              ],
            ),
          ),

          // Post Image with Double Tap
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            GestureDetector(
              onDoubleTap: () => _handleDoubleTap(controller),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
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
                            Icon(Icons.broken_image_outlined, color: AppColors.textMuted, size: 40),
                            SizedBox(height: 8),
                            Text('Imagen no disponible', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                          ],
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

          // Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                GetX<HomeController>(
                  builder: (controller) {
                    final isLiked = widget.post.likes.contains(controller.currentUserId.value);
                    return HeartAnimButton(
                      isLiked: isLiked,
                      onTap: () => controller.toggleLike(widget.post.id),
                    );
                  },
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textHeader, size: 26),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.send_rounded, color: AppColors.textHeader, size: 26),
              ],
            ),
          ),

          // Likes Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Text(
              '${widget.post.likes.length} likes',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),

          // Caption
          if (widget.post.caption != null && widget.post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
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

          // Comments Count
          if (widget.post.commentsCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
              child: GestureDetector(
                onTap: () => _showComments(context),
                child: Text(
                  'Ver los ${widget.post.commentsCount} comentarios',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
