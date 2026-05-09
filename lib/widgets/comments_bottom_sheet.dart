import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/comments_controller.dart';
import '../controllers/home_controller.dart';
import '../constants/app_colors.dart';
import '../screens/report_screen.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;

  const CommentsBottomSheet({super.key, required this.postId});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  String? _selectedCommentId;

  void _showReportScreen(BuildContext context, String commentId) {
    Get.to(
      () => ReportScreen(tipo: 'comment', objetivoId: commentId),
      fullscreenDialog: true,
      transition: Transition.downToUp,
    );
  }

  void _confirmDeleteComment(BuildContext context, CommentsController controller, String commentId) {
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
                  child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  '¿Eliminar comentario?',
                  style: GoogleFonts.inter(
                    color: AppColors.textHeader,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Esta acción borrará permanentemente tu comentario.',
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
                          controller.deleteComment(commentId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            side: const BorderSide(color: AppColors.border),
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

  void _showCommentOptions(BuildContext context, CommentsController controller, String commentId, bool isOwnComment) async {
    setState(() {
      _selectedCommentId = commentId;
    });

    await Get.bottomSheet(
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
                  _confirmDeleteComment(context, controller, commentId);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.report_problem_outlined, color: AppColors.error),
                title: const Text('Reportar comentario', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Get.back();
                  _showReportScreen(context, commentId);
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

    if (mounted) {
      setState(() {
        _selectedCommentId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommentsController(widget.postId), tag: widget.postId);
    final homeController = Get.find<HomeController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
          Text(
            'Comentarios',
            style: GoogleFonts.inter(
              color: AppColors.textHeader,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(color: AppColors.border, height: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 0),
                itemCount: controller.comments.length,
                itemBuilder: (context, index) {
                  final comment = controller.comments[index];
                  final isOwnComment = comment.usuario.id == homeController.currentUserId.value;
                  final isSelected = _selectedCommentId == comment.id;

                  return GestureDetector(
                    onLongPress: () => _showCommentOptions(context, controller, comment.id, isOwnComment),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withOpacity(0.05) : Colors.transparent,
                      ),
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
                                  comment.timeAgo,
                                  style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=me'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.containerBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: TextField(
                      controller: controller.textController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(color: AppColors.textHeader, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Añadir un comentario...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
