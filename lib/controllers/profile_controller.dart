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
  final String? userId;

  ProfileController({
    this.userId,
  });

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
    final token = await _storageService.getAccessToken();
    if (token == null) return;

    String targetUserId;
    bool isMe = false;

    if (userId != null) {
      targetUserId = userId!;
    } else {
      // Get current user ID from local storage
      final userDataStr = await _storageService.getUserData();
      if (userDataStr == null) return;
      final Map<String, dynamic> userData = jsonDecode(userDataStr);
      targetUserId = userData['_id'] ?? '';
      isMe = true;
    }

    final freshData = await _userService.getUserById(targetUserId);
    if (freshData != null) {
      user.value = User.fromJson(freshData, token);
    }

    final followers = await _userService.getFollowers(targetUserId);
    final following = await _userService.getFollowing(targetUserId);
    followersCount.value = followers.length;
    followingCount.value = following.length;

    final result = await _postService.getPostsByUserId(targetUserId);

    userPosts.assignAll(result['posts']);
    postCount.value = userPosts.length;

  } catch (e) {
    print("Error loading profile: $e");
  } finally {
    isLoading.value = false;
  }
}

  void editProfile() {
    Get.toNamed('/profile/edit');
  }
}
