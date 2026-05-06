import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/comments_controller.dart';
import '../constants/app_colors.dart';

class CommentsBottomSheet extends StatelessWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommentsController(postId), tag: postId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Text(
            'Comentarios',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          const Divider(color: Colors.white10, height: 24),
          
          // Comments List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.textLink));
              }
              
              if (controller.comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no hay comentarios',
                        style: GoogleFonts.inter(color: Colors.white54),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.comments.length,
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(comment.usuario.avatarUrl?.replaceAll('/svg', '/png') ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${comment.usuario.nombre}'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${comment.usuario.nombre} ',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    TextSpan(
                                      text: comment.texto,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hace un momento', // TODO: Format date
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.favorite_border, color: Colors.white38, size: 14),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 12,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=me'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller.textController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Añadir un comentario...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.sendComment,
                  child: const Text(
                    'Publicar',
                    style: TextStyle(color: AppColors.textLink, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
