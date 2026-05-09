import 'dart:convert';
import 'package:get/get.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import 'home_controller.dart';

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
  var isFollowing = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    // Si es mi perfil, podemos reaccionar cuando el ID esté disponible
    if (userId == null || userId!.isEmpty) {
      final homeController = Get.find<HomeController>();
      
      // Escuchar cambios por si se carga después de inicializar este controlador
      ever(homeController.currentUserId, (String id) {
        if (id.isNotEmpty && user.value == null) {
          loadUserData();
        }
      });
      
      if (homeController.currentUserId.value.isNotEmpty) {
        loadUserData();
      }
    } else {
      loadUserData();
    }
  }

  bool get isMe {
    final homeController = Get.find<HomeController>();
    final currentId = homeController.currentUserId.value;
    return userId == null || userId == currentId || userId == '';
  }

  Future<void> loadUserData() async {
    try {
      isLoading.value = true;
      final token = await _storageService.getAccessToken();
      if (token == null) return;

      final homeController = Get.find<HomeController>();
      String currentId = homeController.currentUserId.value;

      String targetUserId = (userId == null || userId!.isEmpty) ? currentId : userId!;
      
      if (targetUserId.isEmpty) {
        print("Waiting for targetUserId to be populated...");
        return;
      }

      final freshData = await _userService.getUserById(targetUserId);
      if (freshData != null) {
        user.value = User.fromJson(freshData, token);
        
        // Aseguramos tener el ID actual
        if (currentId.isEmpty) {
          await homeController.loadUser(); // Intentar cargar si está vacío
          currentId = homeController.currentUserId.value;
        }

        // Priorizar el followStatus que devuelve el backend específicamente para el usuario actual
        if (freshData['followStatus'] != null) {
          isFollowing.value = freshData['followStatus'] == 'ACCEPTED';
        }
      }

      final followers = await _userService.getFollowers(targetUserId);
      final following = await _userService.getFollowing(targetUserId);
      
      followersCount.value = followers.length;
      followingCount.value = following.length;

      // Si no tenemos followStatus, usamos la lista como fallback
      if (freshData?['followStatus'] == null) {
        isFollowing.value = followers.contains(currentId);
      }

      final result = await _postService.getPostsByUserId(targetUserId);
      userPosts.assignAll(result['posts']);
      postCount.value = userPosts.length;

    } catch (e) {
      print("Error loading profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFollow() async {
    if (userId == null || userId!.isEmpty || isMe) return;

    final success = await _postService.toggleFollow(userId!);
    if (success) {
      isFollowing.value = !isFollowing.value;
      if (isFollowing.value) {
        followersCount.value++;
      } else {
        followersCount.value--;
      }
    }
  }

  void editProfile() {
    Get.toNamed('/profile/edit');
  }
}
