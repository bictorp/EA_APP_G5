import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/saved_posts_controller.dart';
import '../widgets/post_card.dart';
import '../constants/app_colors.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Injects the controller dynamically when this screen opens
    final controller = Get.put(SavedPostsController());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Tus posts guardados',
          style: GoogleFonts.inter(
            color: AppColors.textHeader,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.textHeader),
      ),
      body: Obx(() {
        // 1. Loading State
        if (controller.isLoading.value) {
          return Center(
            child: Text('Cargando...', style: TextStyle(color: AppColors.textMuted)),
          );
        }

        // 2. Error State
        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Text(
              controller.errorMessage.value,
              style: TextStyle(color: AppColors.error),
            ),
          );
        }

        // 3. Empty State
        if (controller.posts.isEmpty) {
          return Center(
            child: Text('No hay posts guardados', style: TextStyle(color: AppColors.textMuted)),
          );
        }

        // 4. Content List State (with infinite scroll sentinel)
        return RefreshIndicator(
          onRefresh: controller.fetchSavedPosts,
          color: AppColors.accent,
          child: ListView.builder(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.posts.length + 1,
            itemBuilder: (context, index) {
              // If it's the last index, render the loading/end sentinel layout
              if (index == controller.posts.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: controller.isLoadingMore.value
                        ? Text('Cargando...', style: TextStyle(color: AppColors.textMuted))
                        : (!controller.hasNextPage.value
                            ? Text('No hay más posts guardados', style: TextStyle(color: AppColors.textMuted))
                            : const SizedBox.shrink()),
                  ),
                );
              }

              // Return standard PostCard widget
              return PostCard(post: controller.posts[index]);
            },
          ),
        );
      }),
    );
  }
}