import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import '../constants/app_colors.dart';
import '../services/post_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/theme_controller.dart';

class PostDetailScreen extends StatefulWidget {
  final Post? post;
  final String? postId;

  PostDetailScreen({super.key, this.post, this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  Post? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _post = widget.post;
      _isLoading = false;
    } else if (Get.arguments is Post) {
      _post = Get.arguments as Post;
      _isLoading = false;
    } else if (widget.postId != null || Get.arguments != null) {
      _fetchPost(widget.postId ?? Get.arguments.toString());
    }
  }

  Future<void> _fetchPost(String id) async {
    try {
      final response = await PostService().getComments(id); 
      // Note: Backend getPostById usually returns the post with comments.
      // Let's check PostService to see if there's a better method.
      // For now, I'll use a direct dio call or add a method to PostService.
      
      // I'll add a method getPostById to PostService first.
      final postData = await _postService.getPostById(id);
      if (postData != null) {
        setState(() {
          _post = postData;
          _isLoading = false;
        });
      } else {
        Get.back();
        Get.snackbar('Error', 'No se pudo cargar la publicación');
      }
    } catch (e) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final isDark = themeController.isDarkMode.value;
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textHeader),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Publicación',
            style: GoogleFonts.inter(
              color: AppColors.textHeader,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _post == null 
            ? Center(child: Text('No se encontró la publicación', style: TextStyle(color: AppColors.textHeader)))
            : SingleChildScrollView(
                child: PostCard(post: _post!),
              ),
      );
    });
  }
}
