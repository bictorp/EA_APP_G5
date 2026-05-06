import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

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
      isLoading.value = true;
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
    // Optimistic update
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final oldPost = posts[index];
    final bool isLiked = oldPost.likes.contains(currentUserId.value);
    
    // Create new list of likes for UI
    final List<String> newLikes = List.from(oldPost.likes);
    if (isLiked) {
      newLikes.remove(currentUserId.value);
    } else {
      newLikes.add(currentUserId.value);
    }

    // Update local state immediately
    posts[index] = Post(
      id: oldPost.id,
      usuario: oldPost.usuario,
      imageUrl: oldPost.imageUrl,
      caption: oldPost.caption,
      likes: newLikes,
      commentsCount: oldPost.commentsCount,
      createdAt: oldPost.createdAt,
    );

    // Call API
    final updatedPost = await _postService.toggleLike(postId);
    if (updatedPost == null) {
      // Revert if failed
      posts[index] = oldPost;
    } else {
      // Sync with real data from server
      posts[index] = updatedPost;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
