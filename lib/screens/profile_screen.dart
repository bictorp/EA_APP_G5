import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';
import '../utils/ui_utils.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId;

  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final String tag = (userId == null || userId!.isEmpty) ? 'me' : userId!;
    
    final ProfileController controller = Get.put(
      ProfileController(userId: userId),
      tag: tag,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: MediaQuery.of(context).size.width, // Fuerza ancho total
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color(0xFF2D0E4D),
              Color(0xFF0F172A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value && controller.user.value == null) {
              return const Center(child: CircularProgressIndicator(color: AppColors.btnStart));
            }

            final user = controller.user.value;
            if (user == null) {
              return const Center(child: Text('No user data found', style: TextStyle(color: Colors.white)));
            }

            return RefreshIndicator(
              onRefresh: () => controller.loadUserData(),
              color: AppColors.accent,
              backgroundColor: AppColors.bg,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  _buildAppBar(user, controller),
                  _buildProfileHeader(user, controller),
                  _buildAcademicInfo(user),
                  _buildSectionDivider(),
                  _buildPhotoGrid(controller),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAppBar(dynamic user, ProfileController controller) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      actions: [
        if (controller.isMe)
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () => Get.to(() => const SettingsScreen()),
          )
        else
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: Colors.white),
            onPressed: () {
              UIUtils.showReportBottomSheet(
                targetId: controller.userId!,
                tipo: 'user',
                title: 'este perfil',
              );
            },
          ),
      ],
    );
  }

  Widget _buildProfileHeader(dynamic user, ProfileController controller) {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(user, controller),
            const SizedBox(height: 24),
            
            // Username con restricción de ancho
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFCBD5E1)],
                ).createShader(bounds),
                child: Text(
                  user.nombre,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Stats Row con MainAxisSize.min
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, 
              children: [
                _buildStatItem(controller.postCount.value.toString(), 'Posts'),
                const SizedBox(width: 25),
                _buildStatItem(controller.followersCount.value.toString(), 'Followers'),
                const SizedBox(width: 25),
                _buildStatItem(controller.followingCount.value.toString(), 'Following'),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildActionButton(controller),
            
            const SizedBox(height: 20),
            
            if (user.descripcion != null && user.descripcion!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  user.descripcion!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            
            Text(
              user.email,
              style: GoogleFonts.inter(
                color: const Color(0xFFA78BFA),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(dynamic user, ProfileController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          shape: BoxShape.circle,
        ),
        child: CircleAvatar(
          radius: 60,
          backgroundColor: const Color(0xFF0F172A),
          backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
              ? NetworkImage(
                  user.avatarUrl!.contains('?') 
                    ? '${user.avatarUrl!}&t=${controller.avatarTimestamp.value}' 
                    : '${user.avatarUrl!}?t=${controller.avatarTimestamp.value}'
                ) 
              : null,
          child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
              ? Text(
                  user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildActionButton(ProfileController controller) {
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
            ? Colors.white.withOpacity(0.05)
            : (controller.isFollowing.value 
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFF7C3AED)),
        foregroundColor: controller.isMe 
            ? const Color(0xFFA78BFA)
            : (controller.isFollowing.value 
                ? const Color(0xFF94A3B8)
                : Colors.white),
        elevation: controller.isFollowing.value || controller.isMe ? 0 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: controller.isFollowing.value || controller.isMe 
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
      ),
      child: Text(
        controller.isMe 
            ? 'Editar Perfil' 
            : (controller.isFollowing.value ? 'Siguiendo' : 'Seguir'),
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
            color: const Color(0xFFF8FAFC),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF94A3B8),
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
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 14),
            if (uniName != null) _buildAcademicRow(Icons.school_outlined, uniName, true),
            if (gradoName != null) _buildAcademicRow(Icons.edit_note_rounded, gradoName, false),
            if (asignaturas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: asignaturas.map((a) {
                  final name = _getName(a);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.2)),
                    ),
                    child: Text(
                      name ?? '',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFC4B5FD),
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
          Icon(icon, size: 18, color: const Color(0xFFA78BFA)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFFE2E8F0),
                fontSize: isMain ? 15 : 13,
                fontWeight: isMain ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'PUBLICACIONES',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Container(width: 40, height: 2, color: const Color(0xFFA78BFA)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(ProfileController controller) {
    if (controller.userPosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: Text('Aún no hay publicaciones', style: TextStyle(color: Colors.white38))),
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
            final post = controller.userPosts[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                  ? Image.network(post.imageUrl!, fit: BoxFit.cover)
                  : Container(color: Colors.white10),
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
