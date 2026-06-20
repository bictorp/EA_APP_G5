import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/profile_controller.dart';
import '../constants/app_colors.dart';
import 'settings_screen.dart';
import '../utils/ui_utils.dart';
import '../controllers/theme_controller.dart';
import '../controllers/home_controller.dart';
import '../services/user_service.dart';
import '../widgets/safe_circle_avatar.dart';
import '../models/unimatch_profile.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final String tag = (userId == null || userId!.isEmpty) ? 'me' : userId!;
    final themeController = Get.find<ThemeController>();
    
    final ProfileController controller = Get.put(
      ProfileController(userId: userId),
      tag: tag,
    );

    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Container(
          width: MediaQuery.of(context).size.width, // Fuerza ancho total
          decoration: BoxDecoration(
            gradient: isDark
                ? RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      Color(0xFF2D0E4D),
                      Color(0xFF0F172A),
                      Color(0xFF000000),
                    ],
                  )
                : null,
            color: isDark ? null : AppColors.bg,
          ),
          child: SafeArea(
            child: Obx(() {
              if (controller.isLoading.value && controller.user.value == null) {
                return Center(child: CircularProgressIndicator(color: AppColors.btnStart));
              }

              final user = controller.user.value;
              if (user == null) {
                return Center(child: Text('no_user_data'.tr, style: TextStyle(color: AppColors.textHeader)));
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadUserData(),
                color: AppColors.accent,
                backgroundColor: AppColors.bg,
                child: CustomScrollView(
                  physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    _buildAppBar(user, controller),
                    _buildProfileHeader(user, controller),
                    _buildAcademicInfo(user),
                    _buildSectionTabs(controller),
                    _buildContent(controller),
                  ],
                ),
              );
            }),
          ),
        ),
      );
    });
  }

  Widget _buildAppBar(dynamic user, ProfileController controller) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textHeader),
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: AppColors.bg.withOpacity(0.7),
          ),
        ),
      ),
      actions: [
        if (controller.isMe)
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.textHeader),
            onPressed: () => Get.to(() => SettingsScreen()),
          )
        else
          IconButton(
            icon: Icon(Icons.report_problem_outlined, color: AppColors.textHeader),
            onPressed: () {
              UIUtils.showReportBottomSheet(
                targetId: controller.userId!,
                tipo: 'user',
                title: 'this_profile'.tr,
              );
            },
          ),
      ],
    );
  }

  Widget _buildProfileHeader(dynamic user, ProfileController controller) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode.value;

    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(user, controller),
            SizedBox(height: 24),
            
            // Username con restricción de ancho
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark ? [Colors.white, Color(0xFFCBD5E1)] : [AppColors.textHeader, AppColors.textMuted],
                ).createShader(bounds),
                child: Text(
                  user.nombre,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeader,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            
            // Stats Row con MainAxisSize.min
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, 
              children: [
                _buildStatItem(controller.postCount.value.toString(), 'posts'.tr),
                SizedBox(width: 25),
                GestureDetector(
                  onTap: () {
                    final targetId = (controller.userId == null || controller.userId!.isEmpty)
                        ? Get.find<HomeController>().currentUserId.value
                        : controller.userId!;
                    if (targetId.isNotEmpty) {
                      Get.bottomSheet(
                        _UserListBottomSheet(
                          title: 'followers'.tr,
                          userId: targetId,
                          isFollowers: true,
                        ),
                      );
                    }
                  },
                  child: _buildStatItem(controller.followersCount.value.toString(), 'followers'.tr),
                ),
                SizedBox(width: 25),
                GestureDetector(
                  onTap: () {
                    final targetId = (controller.userId == null || controller.userId!.isEmpty)
                        ? Get.find<HomeController>().currentUserId.value
                        : controller.userId!;
                    if (targetId.isNotEmpty) {
                      Get.bottomSheet(
                        _UserListBottomSheet(
                          title: 'following'.tr,
                          userId: targetId,
                          isFollowers: false,
                        ),
                      );
                    }
                  },
                  child: _buildStatItem(controller.followingCount.value.toString(), 'following'.tr),
                ),
              ],
            ),
            SizedBox(height: 24),
            
            _buildActionButton(controller),
            
            SizedBox(height: 20),
            
            if (user.descripcion != null && user.descripcion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  user.descripcion!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            
            Text(
              user.email,
              style: GoogleFonts.inter(
                color: AppColors.accent,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic user, ProfileController controller) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode.value;
    final bgCol = isDark ? Color(0xFF0F172A) : AppColors.bg;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgCol,
          shape: BoxShape.circle,
        ),
        child: SafeCircleAvatar(
          radius: 60,
          url: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? (user.avatarUrl!.contains('?') 
                ? '${user.avatarUrl!}&t=${controller.avatarTimestamp.value}' 
                : '${user.avatarUrl!}?t=${controller.avatarTimestamp.value}')
              : null,
          name: user.nombre,
        ),
      ),
    );
  }

  Widget _buildActionButton(ProfileController controller) {
    final themeController = Get.find<ThemeController>();
    final isDark = themeController.isDarkMode.value;

    return ElevatedButton(
      onPressed: () {
        if (controller.isMe) {
          controller.editProfile();
        } else if (controller.isFollowing.value) {
          UIUtils.showUnfollowBottomSheet(
            userId: controller.userId!,
            nombre: controller.user.value?.nombre ?? 'este usuario',
            onConfirm: () => controller.toggleFollow(),
          );
        } else {
          controller.toggleFollow();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: controller.isMe 
            ? (isDark ? Colors.white.withOpacity(0.05) : AppColors.border)
            : (controller.isFollowing.value 
                ? (isDark ? Colors.white.withOpacity(0.05) : AppColors.border)
                : AppColors.accent),
        foregroundColor: controller.isMe 
            ? (isDark ? Color(0xFFA78BFA) : AppColors.textHeader)
            : (controller.isFollowing.value 
                ? (isDark ? Color(0xFF94A3B8) : AppColors.textMuted)
                : Colors.white),
        elevation: controller.isFollowing.value || controller.isMe ? 0 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: controller.isFollowing.value || controller.isMe 
                ? (isDark ? Colors.white.withOpacity(0.1) : AppColors.border)
                : Colors.transparent
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      ),
      child: Text(
        controller.isMe 
            ? 'edit_profile'.tr 
            : (controller.isFollowing.value ? 'following_action'.tr : 'follow'.tr),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textHeader,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicInfo(dynamic user) {
    final uniName = _getName(user.universidad);
    final gradoName = _getName(user.grado);
    final asignaturas = user.asignaturas as List<dynamic>;

    if (uniName == null && gradoName == null && asignaturas.isEmpty) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: AppColors.border),
            SizedBox(height: 14),
            if (uniName != null) _buildAcademicRow(Icons.school_outlined, uniName, true),
            if (gradoName != null) _buildAcademicRow(Icons.edit_note_rounded, gradoName, false),
            if (asignaturas.isNotEmpty) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: asignaturas.map((a) {
                  final name = _getName(a);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: Text(
                      name ?? '',
                      style: GoogleFonts.inter(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicRow(IconData icon, String text, bool isMain) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontSize: isMain ? 15 : 13,
                fontWeight: isMain ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs(ProfileController controller) {
    final showTabs = controller.isMe || controller.unimatchPhotos.isNotEmpty;
    
    if (!showTabs) {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'posts_title'.tr,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 40, height: 2, color: AppColors.accent),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Obx(() {
        final active = controller.activeTab.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Tab 1: PUBLICACIONES
              GestureDetector(
                onTap: () => controller.activeTab.value = 0,
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'posts_title'.tr.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: active == 0 
                                ? const Color(0xFF7C3AED) 
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      Container(
                        height: 2,
                        color: active == 0 ? const Color(0xFF7C3AED) : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 30),
              // Tab 2: UniMatch
              GestureDetector(
                onTap: () => controller.activeTab.value = 1,
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_outlined,
                              size: 18,
                              color: active == 1 ? const Color(0xFFEC4899) : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'UniMatch',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: active == 1 
                                    ? const Color(0xFFEC4899) 
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 2,
                        color: active == 1 ? const Color(0xFFEC4899) : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContent(ProfileController controller) {
    return Obx(() {
      final showTabs = controller.isMe || controller.unimatchPhotos.isNotEmpty;
      final active = showTabs ? controller.activeTab.value : 0;
      
      if (active == 0) {
        return _buildPhotoGrid(controller);
      } else {
        return _buildUnimatchGrid(controller);
      }
    });
  }

  Widget _buildUnimatchGrid(ProfileController controller) {
    final List<UnimatchPhoto> photos = controller.unimatchPhotos;
    final isMe = controller.isMe;
    final totalCount = isMe ? photos.length + 1 : photos.length;

    if (totalCount == 0) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Center(child: Text('no_photos'.tr, style: TextStyle(color: AppColors.textMuted))),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (isMe && index == 0) {
              return GestureDetector(
                onTap: () => _pickAndUploadUnimatchPhoto(controller),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Center(
                    child: Icon(Icons.add_a_photo_outlined, color: Colors.white60, size: 28),
                  ),
                ),
              );
            }

            final photoIndex = isMe ? index - 1 : index;
            final photo = photos[photoIndex];

            return Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.broken_image_outlined, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
                if (isMe)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _showDeleteConfirmation(controller, photo.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                      ),
                    ),
                  ),
              ],
            );
          },
          childCount: totalCount,
        ),
      ),
    );
  }

  Future<void> _pickAndUploadUnimatchPhoto(ProfileController controller) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        final success = await controller.uploadUnimatchPhoto(image);
        if (success) {
          Get.snackbar(
            'Éxito',
            'Foto de UniMatch subida correctamente',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.accent.withOpacity(0.8),
            colorText: Colors.white,
          );
        } else {
          Get.snackbar(
            'Error',
            'No se pudo subir la foto de UniMatch',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.redAccent.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Error al seleccionar imagen: $e');
    }
  }

  void _showDeleteConfirmation(ProfileController controller, String photoId) {
    Get.defaultDialog(
      title: 'Eliminar Foto',
      middleText: '¿Estás seguro de que quieres eliminar esta foto de UniMatch?',
      textConfirm: 'Eliminar',
      textCancel: 'Cancelar',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () async {
        Get.back(); // close dialog
        final success = await controller.deleteUnimatchPhoto(photoId);
        if (success) {
          Get.snackbar(
            'Éxito',
            'Foto eliminada',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.accent.withOpacity(0.8),
            colorText: Colors.white,
          );
        }
      },
    );
  }

  Widget _buildPhotoGrid(ProfileController controller) {
    if (controller.userPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: Text('no_posts'.tr, style: TextStyle(color: AppColors.textMuted))),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = controller.userPosts[index];
            return GestureDetector(
              onTap: () {
                Get.toNamed('/post-detail', arguments: post);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                    ? Hero(
                        tag: 'post_${post.id}',
                        child: Image.network(post.imageUrl!, fit: BoxFit.cover),
                      )
                    : Container(color: AppColors.border),
              ),
            );
          },
          childCount: controller.userPosts.length,
        ),
      ),
    );
  }

  String? _getName(dynamic obj) {
    if (obj == null) return null;
    if (obj is String) return obj;
    if (obj is Map) return obj['nombre'];
    return null;
  }
}

class _UserListBottomSheet extends StatefulWidget {
  final String title;
  final String userId;
  final bool isFollowers;

  _UserListBottomSheet({
    required this.title,
    required this.userId,
    required this.isFollowers,
  });

  @override
  State<_UserListBottomSheet> createState() => _UserListBottomSheetState();
}

class _UserListBottomSheetState extends State<_UserListBottomSheet> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final result = widget.isFollowers
          ? await _userService.getFollowersList(widget.userId)
          : await _userService.getFollowingList(widget.userId);
      if (mounted) {
        setState(() {
          _users = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      
      final filteredUsers = _users.where((u) {
        final name = (u['nombre'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              widget.title,
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 16),
            
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: GoogleFonts.inter(color: AppColors.textHeader, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'search'.tr,
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 16),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            else if (filteredUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline_rounded, size: 60, color: AppColors.textMuted.withOpacity(0.15)),
                    SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty 
                          ? 'no_users_found_search'.tr
                          : 'no_users_show'.tr,
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filteredUsers.length,
                  separatorBuilder: (context, index) => Divider(color: AppColors.border, height: 16),
                  itemBuilder: (context, index) {
                    final u = filteredUsers[index];
                    final String uid = u['_id'] ?? u['id'] ?? '';
                    final String name = u['nombre'] ?? '';
                    final String email = u['email'] ?? '';
                    final String? avatarUrl = u['avatarUrl'];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: SafeCircleAvatar(
                        radius: 20,
                        url: avatarUrl,
                        name: name,
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.inter(
                          color: AppColors.textHeader,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Get.back(); // Cierra el bottom sheet
                        if (uid.isNotEmpty) {
                          // Navegar al perfil del usuario clicked
                          Get.to(() => ProfileScreen(userId: uid), preventDuplicates: false);
                        }
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: 20),
          ],
        ),
      );
    });
  }
}
