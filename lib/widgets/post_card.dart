import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../constants/app_colors.dart';
import '../controllers/home_controller.dart';
import 'heart_anim_button.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showLargeHeart = false;

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.containerBg.withOpacity(0.4),
        border: const Border.symmetric(
          horizontal: BorderSide(color: AppColors.borderWhite, width: 0.5),
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, color: Colors.white70),
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
                        color: Colors.white.withOpacity(0.05),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                            SizedBox(height: 8),
                            Text('Imagen no disponible', style: TextStyle(color: Colors.white24, fontSize: 12)),
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
                              color: Colors.white.withOpacity(0.5),
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
                const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 16),
                const Icon(Icons.send_rounded, color: Colors.white, size: 26),
              ],
            ),
          ),

          // Likes Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Text(
              '${widget.post.likes.length} likes',
              style: GoogleFonts.inter(
                color: Colors.white,
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: widget.post.caption,
                      style: GoogleFonts.inter(
                        color: Colors.white,
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
              child: Text(
                'Ver los ${widget.post.commentsCount} comentarios',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
