import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../controllers/home_controller.dart';
import '../controllers/create_post_controller.dart';
import '../controllers/notification_controller.dart';
import '../widgets/post_card.dart';
import 'notifications_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aseguramos que el controlador esté disponible
    final HomeController controller = Get.put(HomeController());
    final NotificationController notificationController = Get.put(NotificationController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.titleStart, AppColors.titleEnd],
          ).createShader(bounds),
          child: Text(
            'UNIVY',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -1.0,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.to(() => const MapScreen()),
            icon: const Icon(Icons.map_outlined, color: AppColors.textHeader),
          ),
          IconButton(
            onPressed: () {
              final CreatePostController createPostController = Get.put(CreatePostController());
              createPostController.startMediaFlow();
            },
            icon: const Icon(Icons.add_box_outlined, color: AppColors.textHeader),
          ),
          Obx(() => IconButton(
            onPressed: () => Get.to(() => const NotificationsScreen()),
            icon: Badge(
              isLabelVisible: notificationController.hasUnread.value,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.favorite_border_rounded, color: AppColors.textHeader),
            ),
          )),
        ],
      ),
      body: Obx(() {
        // Estado de carga inicial
        if (controller.isLoading.value && controller.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.textLink));
        }

        // Estado vacío
        if (controller.posts.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchPosts,
            color: AppColors.textLink,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                const Icon(Icons.feed_outlined, color: Colors.white10, size: 80),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'No hay publicaciones',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Sigue a gente para ver su contenido.',
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }

        // Lista de Posts
        return RefreshIndicator(
          onRefresh: controller.fetchPosts,
          color: AppColors.textLink,
          backgroundColor: AppColors.containerBg,
          child: CustomScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return PostCard(post: controller.posts[index]);
                  },
                  childCount: controller.posts.length,
                ),
              ),
              
              // Indicador de carga inferior (sin Obx anidado)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: controller.isLoadingMore.value
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textLink))
                      : const SizedBox(height: 20),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
