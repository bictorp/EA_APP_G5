import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/storage_service.dart';

class SavedPostsController extends GetxController {
  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();
  final ScrollController scrollController = ScrollController();

  var posts = <Post>[].obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var hasNextPage = true.obs;
  var errorMessage = ''.obs;
  var currentPage = 1;
  var currentUserId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUser();
    fetchSavedPosts();
    
    // Equivalent to the IntersectionObserver sentinel logic
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        fetchMoreSavedPosts();
      }
    });
  }

  Future<void> loadUser() async {
    final userData = await _storageService.getUserData();
    if (userData != null) {
      final user = jsonDecode(userData);
      currentUserId.value = user['_id'] ?? '';
    }
  }

  Future<void> fetchSavedPosts() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentPage = 1;
      
      final result = await _postService.getSavedPostsFeed(page: currentPage);
      
      posts.assignAll(result['posts']);
      hasNextPage.value = result['hasNextPage'];
    } catch (e) {
      errorMessage.value = 'error_message'.tr; // Handles your web's error state
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMoreSavedPosts() async {
    if (isLoadingMore.value || !hasNextPage.value) return;

    try {
      isLoadingMore.value = true;
      currentPage++;
      
      final result = await _postService.getSavedPostsFeed(page: currentPage);
      
      posts.addAll(result['posts']);
      hasNextPage.value = result['hasNextPage'];
    } catch (e) {
      currentPage--; 
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> toggleSave(String postId) async {
    final success = await _postService.toggleSavePost(postId);
    if (success) {
      posts.removeWhere((p) => p.id == postId);
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}