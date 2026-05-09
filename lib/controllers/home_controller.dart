import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../constants/app_colors.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import'../models/user.dart';

class HomeController extends GetxController {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ScrollController scrollController = ScrollController();

  var posts = <Post>[].obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var hasNextPage = true.obs;
  var currentPage = 1;
  var currentUserId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    fetchPosts();
    
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        fetchMorePosts();
      }
    });
  }

  Future<void> _loadUser() async {
    final userData = await _storageService.getUserData();
    if (userData != null) {
      final user = jsonDecode(userData);
      currentUserId.value = user['_id'] ?? '';
    }
  }

  Future<void> fetchPosts() async {
    try {
      if (posts.isEmpty) {
        isLoading.value = true;
      }
      currentPage = 1;
      final result = await _postService.getFollowingFeed(page: currentPage);
      
      posts.assignAll(result['posts']);
      hasNextPage.value = result['hasNextPage'];
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMorePosts() async {
    if (isLoadingMore.value || !hasNextPage.value) return;

    try {
      isLoadingMore.value = true;
      currentPage++;
      
      final result = await _postService.getFollowingFeed(page: currentPage);
      
      posts.addAll(result['posts']);
      hasNextPage.value = result['hasNextPage'];
    } catch (e) {
      currentPage--; 
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> toggleLike(String postId) async {
  final index = posts.indexWhere((p) => p.id == postId);

  if (index == -1) return;

  final oldPost = posts[index];

  // Verificar si el usuario ya dio like
  final bool isLiked = oldPost.likes.any(
    (user) => user.id == currentUserId.value,
  );

  // Crear copia mutable
  final List<User> newLikes = List<User>.from(oldPost.likes);

  if (isLiked) {
    newLikes.removeWhere(
      (user) => user.id == currentUserId.value,
    );
  } else {
    // Necesitas el usuario actual completo
    final userData = await _storageService.getUserData();

    if (userData != null) {
      final decoded = jsonDecode(userData);

      newLikes.add(
        User.fromJson(decoded, ''),
      );
    }
  }

  // Update optimista
  posts[index] = Post(
    id: oldPost.id,
    usuario: oldPost.usuario,
    imageUrl: oldPost.imageUrl,
    caption: oldPost.caption,
    likes: newLikes,
    commentsCount: oldPost.commentsCount,
    createdAt: oldPost.createdAt,
  );

  try {
    final updatedPost = await _postService.toggleLike(postId);

    if (updatedPost != null) {
      posts[index] = updatedPost;
    } else {
      posts[index] = oldPost;
    }
  } catch (e) {
    posts[index] = oldPost;
  }
}

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> deletePost(String postId) async {
    final success = await _postService.deletePost(postId);
    if (success) {
      posts.removeWhere((p) => p.id == postId);
      Get.snackbar(
        'Publicación eliminada',
        'Tu post ha sido borrado correctamente.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'No se pudo eliminar la publicación.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> toggleFollow(String targetId, String nombre) async {
    final success = await _postService.toggleFollow(targetId);
    if (success) {
      Get.snackbar(
        'Acción realizada',
        'Has cambiado tu estado de seguimiento con $nombre',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.accent.withOpacity(0.8),
        colorText: Colors.white,
      );
      // Opcional: Refrescar el feed para quitar los posts si dejó de seguir
      fetchPosts();
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
