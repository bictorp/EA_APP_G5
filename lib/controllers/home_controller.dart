import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/auth_service.dart';

class HomeController extends GetxController {
  final PostService _postService = PostService();
  final AuthService _authService = AuthService();
  final ScrollController scrollController = ScrollController();

  var posts = <Post>[].obs;
  var isLoading = true.obs;
  var isLoadingMore = false.obs;
  var hasNextPage = true.obs;
  var currentPage = 1;

  @override
  void onInit() {
    super.onInit();
    fetchPosts();
    
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
        fetchMorePosts();
      }
    });
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

  Future<void> logout() async {
    await _authService.logout();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
