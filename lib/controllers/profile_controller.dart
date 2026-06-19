import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../models/unimatch_profile.dart';
import '../services/storage_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../services/unimatch_service.dart';
import 'home_controller.dart';

class ProfileController extends GetxController {
  final StorageService _storageService = StorageService();
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  final UnimatchService _unimatchService = UnimatchService();
  final String? userId;

  ProfileController({
    this.userId,
  });

  var user = Rxn<User>();
  var userPosts = <Post>[].obs;
  var unimatchPhotos = <UnimatchPhoto>[].obs;
  var isLoading = true.obs;
  var isLoadingUnimatch = false.obs;
  var activeTab = 0.obs;

  var followersCount = 0.obs;
  var followingCount = 0.obs;
  var postCount = 0.obs;
  var isFollowing = false.obs;
  var avatarTimestamp = DateTime.now().millisecondsSinceEpoch.obs;

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
      avatarTimestamp.value = DateTime.now().millisecondsSinceEpoch;

      await loadUnimatchPhotos();

    } catch (e) {
      print("Error loading profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUnimatchPhotos() async {
    try {
      isLoadingUnimatch.value = true;
      final targetUserId = (userId == null || userId!.isEmpty) ? Get.find<HomeController>().currentUserId.value : userId!;
      if (targetUserId.isEmpty) return;

      List<dynamic> rawPhotos;
      if (isMe) {
        rawPhotos = await _unimatchService.getMyPhotos();
      } else {
        rawPhotos = await _unimatchService.getUserPhotos(targetUserId);
      }
      
      unimatchPhotos.assignAll(rawPhotos.map((p) => UnimatchPhoto.fromJson(p)).toList());
    } catch (e) {
      print("Error loading UniMatch photos: $e");
    } finally {
      isLoadingUnimatch.value = false;
    }
  }

  Future<bool> uploadUnimatchPhoto(XFile file) async {
    try {
      isLoadingUnimatch.value = true;
      final result = await _unimatchService.uploadUnimatchPhoto(file);
      if (result != null) {
        await loadUnimatchPhotos();
        return true;
      }
      return false;
    } catch (e) {
      print("Error uploading UniMatch photo: $e");
      return false;
    } finally {
      isLoadingUnimatch.value = false;
    }
  }

  Future<bool> deleteUnimatchPhoto(String photoId) async {
    try {
      isLoadingUnimatch.value = true;
      final success = await _unimatchService.deleteUnimatchPhoto(photoId);
      if (success) {
        await loadUnimatchPhotos();
        return true;
      }
      return false;
    } catch (e) {
      print("Error deleting UniMatch photo: $e");
      return false;
    } finally {
      isLoadingUnimatch.value = false;
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
