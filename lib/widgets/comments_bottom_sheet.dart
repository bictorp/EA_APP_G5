import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/comments_controller.dart';
import '../controllers/home_controller.dart';
import '../constants/app_colors.dart';
import '../screens/report_screen.dart';

class CommentsBottomSheet extends StatelessWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  void _showReportScreen(BuildContext context, String commentId) {
    Get.to(
      () => ReportScreen(tipo: 'comment', objetivoId: commentId),
      fullscreenDialog: true,
      transition: Transition.downToUp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommentsController(postId), tag: postId);
    final homeController = Get.find<HomeController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.bg,
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
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Text(
            'Comentarios',
            style: GoogleFonts.inter(
              color: AppColors.textHeader,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          
          const Divider(color: AppColors.border, height: 24),
          
          // Comments List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }
              
              if (controller.comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: AppColors.textMuted, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no hay comentarios',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
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
                  final isOwnComment = comment.usuario.id == homeController.currentUserId.value;

                  return GestureDetector(
                    onLongPress: () {
                      Get.bottomSheet(
                        Container(
                          decoration: const BoxDecoration(
                            color: AppColors.containerBg,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: Wrap(
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              if (isOwnComment) ...[
                                ListTile(
                                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                                  title: const Text('Eliminar comentario', style: TextStyle(color: AppColors.error)),
                                  onTap: () {
                                    Get.back();
                                    // TODO: Eliminar comentario
                                  },
                                ),
                              ] else ...[
                                ListTile(
                                  leading: const Icon(Icons.report_problem_outlined, color: AppColors.error),
                                  title: const Text('Reportar comentario', style: TextStyle(color: AppColors.error)),
                                  onTap: () {
                                    Get.back();
                                    _showReportScreen(context, comment.id);
                                  },
                                ),
                              ],
                              ListTile(
                                leading: const Icon(Icons.close, color: AppColors.textHeader),
                                title: const Text('Cancelar', style: TextStyle(color: AppColors.textHeader)),
                                onTap: () => Get.back(),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Padding(
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
                                          color: AppColors.textHeader,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      TextSpan(
                                        text: comment.texto,
                                        style: GoogleFonts.inter(
                                          color: AppColors.textHeader,
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
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.favorite_border, color: AppColors.textMuted, size: 14),
                        ],
                      ),
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
              color: AppColors.bg,
              border: const Border(top: BorderSide(color: AppColors.border)),
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
                    style: const TextStyle(color: AppColors.textHeader, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Añadir un comentario...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.sendComment,
                  child: const Text(
                    'Publicar',
                    style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
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
