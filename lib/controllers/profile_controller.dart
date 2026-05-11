import 'dart:convert';
import 'package:get/get.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';

class ProfileController extends GetxController {
  final StorageService _storageService = StorageService();
  final PostService _postService = PostService();
  final UserService _userService = UserService();

  var user = Rxn<User>();
  var userPosts = <Post>[].obs;
  var isLoading = true.obs;

  var followersCount = 0.obs;
  var followingCount = 0.obs;
  var postCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;
      final userDataStr = await _storageService.getUserData();
      final token = await _storageService.getAccessToken();
      
      if (userDataStr != null && token != null) {
        final Map<String, dynamic> userData = jsonDecode(userDataStr);
        final String userId = userData['_id'] ?? '';
        
        // Fetch fresh user data from API using getMe() for own profile
        final freshData = await _userService.getMe();
        if (freshData != null) {
          user.value = User.fromJson(freshData, token);
        } else {
          user.value = User.fromJson(userData, token);
        }

        // Fetch counts
        final followers = await _userService.getFollowers(userId);
        final following = await _userService.getFollowing(userId);
        
        followersCount.value = followers.length;
        followingCount.value = following.length;

        // Fetch posts
        // For now, using following feed as a fallback if getPostsByUserId is not implemented
        // But let's assume we want to show the posts in the profile
        final result = await _postService.getFollowingFeed();
        userPosts.assignAll(result['posts']);
        postCount.value = userPosts.length;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void editProfile() {
    Get.toNamed('/profile/edit');
  }
}
