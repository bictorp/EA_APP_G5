import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../controllers/profile_controller.dart';
import '../constants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color(0xFF1E1B4B),
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

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(user, controller),
                _buildProfileHeader(user, controller),
                _buildAcademicInfo(user),
                _buildSectionDivider(),
                _buildPhotoGrid(controller),
              ],
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
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Get.to(() => const SettingsScreen()),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(dynamic user, ProfileController controller) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // Avatar with Gradient Border and Glow
            Container(
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
                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 2,
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
                  radius: 65,
                  backgroundColor: const Color(0xFF0F172A),
                  backgroundImage: user.avatarUrl != null 
                      ? NetworkImage(user.avatarUrl!) 
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                            fontSize: 50,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Username with Gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, Color(0xFFCBD5E1)],
              ).createShader(bounds),
              child: Text(
                user.nombre,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(controller.postCount.value.toString(), 'Posts'),
                const SizedBox(width: 30),
                _buildStatItem(controller.followersCount.value.toString(), 'Followers'),
                const SizedBox(width: 30),
                _buildStatItem(controller.followingCount.value.toString(), 'Following'),
              ],
            ),
            const SizedBox(height: 20),
            
            // Edit Button
            ElevatedButton(
              onPressed: controller.editProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.05),
                foregroundColor: const Color(0xFFA78BFA),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Editar Perfil',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Bio
            if (user.descripcion != null && user.descripcion!.isNotEmpty)
              Text(
                user.descripcion!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.5,
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

  Widget _buildStatItem(String value, String label) {
    return Column(
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
            fontSize: 13,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(color: Colors.white.withOpacity(0.06)),
            const SizedBox(height: 14),
            
            if (uniName != null)
              _buildAcademicRow(Icons.school_outlined, uniName, true),
            
            if (gradoName != null)
              _buildAcademicRow(Icons.edit_note_rounded, gradoName, false),
            
            if (asignaturas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: asignaturas.map((a) {
                  final name = _getName(a);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.25)),
                    ),
                    child: Text(
                      name ?? '',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFC4B5FD),
                        fontSize: 12,
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: isMain ? 20 : 18, color: const Color(0xFFA78BFA)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: const Color(0xFFE2E8F0),
                fontSize: isMain ? 16 : 14,
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
          const SizedBox(height: 30),
          Text(
            'PUBLICACIONES',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xFFA78BFA),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA78BFA).withOpacity(0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(ProfileController controller) {
    if (controller.userPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 64,
                color: const Color(0xFF94A3B8).withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Aún no hay publicaciones',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = controller.userPosts[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: post.imageUrl != null
                    ? Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.white24),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image_outlined, color: Colors.white24),
                      ),
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
