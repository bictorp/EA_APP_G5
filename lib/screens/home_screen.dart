import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../controllers/home_controller.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.put(HomeController());

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
            onPressed: () => Get.toNamed('/create-post'),
            icon: const Icon(Icons.add_box_outlined, color: AppColors.textHeader),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded, color: AppColors.textHeader),
          ),

        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.textLink));
        }

        if (controller.posts.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchPosts,
            color: AppColors.textLink,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const Icon(Icons.feed_outlined, color: Colors.white24, size: 80),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'No hay publicaciones',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Sigue a algunos usuarios para ver sus posts aquí.',
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchPosts,
          color: AppColors.textLink,
          backgroundColor: AppColors.containerBg,
          child: CustomScrollView(
            controller: controller.scrollController,
            slivers: [
              // Feed
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return PostCard(post: controller.posts[index]);
                  },
                  childCount: controller.posts.length,
                ),
              ),
              
              // Loading More Indicator
              Obx(() => SliverToBoxAdapter(
                child: controller.isLoadingMore.value
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textLink)),
                      )
                    : const SizedBox(height: 50),
              )),
            ],
          ),
        );
      }),
    );
  }
}
