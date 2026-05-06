import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/comment.dart';
import '../services/post_service.dart';

class CommentsController extends GetxController {
  final String postId;
  final PostService _postService = PostService();

  var comments = <Comment>[].obs;
  var isLoading = true.obs;
  final TextEditingController textController = TextEditingController();

  CommentsController(this.postId);

  @override
  void onInit() {
    super.onInit();
    fetchComments();
  }

  Future<void> fetchComments() async {
    try {
      isLoading.value = true;
      final result = await _postService.getComments(postId);
      comments.assignAll(result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendComment() async {
    if (textController.text.trim().isEmpty) return;

    final texto = textController.text.trim();
    textController.clear();

    final newComment = await _postService.addComment(postId, texto);
    if (newComment != null) {
      comments.add(newComment);
    }
  }

  Future<void> deleteComment(String commentId) async {
    final success = await _postService.deleteComment(commentId);
    if (success) {
      comments.removeWhere((c) => c.id == commentId);
      Get.snackbar(
        'Comentario eliminado',
        'Tu comentario ha sido borrado.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'No se pudo eliminar el comentario.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    textController.dispose();
    super.onClose();
  }
}
