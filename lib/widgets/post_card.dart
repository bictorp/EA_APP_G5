import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../services/post_service.dart';
import '../controllers/profile_controller.dart';
import '../constants/app_colors.dart';
import '../widgets/heart_anim_button.dart';
import '../widgets/large_heart_anim.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../controllers/home_controller.dart';
import '../controllers/saved_posts_controller.dart';
import '../screens/profile_screen.dart';
import '../widgets/share_post_bottom_sheet.dart';
import '../utils/ui_utils.dart';
import 'safe_circle_avatar.dart';

class PostCard extends StatefulWidget {
  final Post post;

  PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _showLargeHeart = false;
  late Post _localPost;

  @override
  void initState() {
    super.initState();
    _localPost = widget.post;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post != oldWidget.post) {
      _localPost = widget.post;
    }
  }

  HomeController? get _ctrl {
    if (Get.isRegistered<HomeController>()) return Get.find<HomeController>();
    return null;
  }

  String get _myId {
    if (_ctrl != null) return _ctrl!.currentUserId.value;
    return '';
  }

  bool get _isLiked => _localPost.likes.any((u) => u.id == _myId);

  Future<void> _toggleLike() async {
    final myId = _myId;
    if (myId.isEmpty) return;

    final bool currentlyLiked = _isLiked;
    final List<User> newLikes = List<User>.from(_localPost.likes);
    if (currentlyLiked) {
      newLikes.removeWhere((u) => u.id == myId);
    } else {
      newLikes.add(User(id: myId, nombre: '', email: '', accessToken: ''));
    }

    setState(() {
      _localPost = _localPost.copyWith(likes: newLikes);
    });

    try {
      final updatedPost = await PostService().toggleLike(_localPost.id);
      if (updatedPost != null) {
        setState(() {
          _localPost = updatedPost;
        });
        _updateControllersWithPost(updatedPost);
      } else {
        _revertLike(currentlyLiked, myId);
      }
    } catch (e) {
      _revertLike(currentlyLiked, myId);
    }
  }

  void _revertLike(bool currentlyLiked, String myId) {
    final List<User> revertedLikes = List<User>.from(_localPost.likes);
    if (currentlyLiked) {
      revertedLikes.add(User(id: myId, nombre: '', email: '', accessToken: ''));
    } else {
      revertedLikes.removeWhere((u) => u.id == myId);
    }
    setState(() {
      _localPost = _localPost.copyWith(likes: revertedLikes);
    });
  }

  Future<void> _handleBookmarkTap() async {
    final bool currentSaved = _localPost.isSaved;
    setState(() {
      _localPost = _localPost.copyWith(isSaved: !currentSaved);
    });

    try {
      final success = await PostService().toggleSavePost(_localPost.id);
      if (success) {
        final updatedPost = _localPost.copyWith(isSaved: !currentSaved);
        _updateControllersWithPost(updatedPost);
      } else {
        setState(() {
          _localPost = _localPost.copyWith(isSaved: currentSaved);
        });
      }
    } catch (e) {
      setState(() {
        _localPost = _localPost.copyWith(isSaved: currentSaved);
      });
    }
  }

  void _updateControllersWithPost(Post updatedPost) {
    if (Get.isRegistered<HomeController>()) {
      final homeCtrl = Get.find<HomeController>();
      final idx = homeCtrl.posts.indexWhere((p) => p.id == updatedPost.id);
      if (idx != -1) {
        homeCtrl.posts[idx] = updatedPost;
        homeCtrl.posts.refresh();
      }
    }
    if (Get.isRegistered<SavedPostsController>()) {
      final savedCtrl = Get.find<SavedPostsController>();
      final idx = savedCtrl.posts.indexWhere((p) => p.id == updatedPost.id);
      if (idx != -1) {
        if (!updatedPost.isSaved) {
          savedCtrl.posts.removeAt(idx);
        } else {
          savedCtrl.posts[idx] = updatedPost;
        }
        savedCtrl.posts.refresh();
      }
    }
    final String postAuthorId = updatedPost.usuario.id;
    final String profileTag = postAuthorId.isEmpty ? 'me' : postAuthorId;
    if (Get.isRegistered<ProfileController>(tag: profileTag)) {
      final profileCtrl = Get.find<ProfileController>(tag: profileTag);
      final idx = profileCtrl.userPosts.indexWhere((p) => p.id == updatedPost.id);
      if (idx != -1) {
        profileCtrl.userPosts[idx] = updatedPost;
        profileCtrl.userPosts.refresh();
      }
    }
    if (Get.isRegistered<ProfileController>(tag: 'me')) {
      final profileCtrl = Get.find<ProfileController>(tag: 'me');
      final idx = profileCtrl.userPosts.indexWhere((p) => p.id == updatedPost.id);
      if (idx != -1) {
        profileCtrl.userPosts[idx] = updatedPost;
        profileCtrl.userPosts.refresh();
      }
    }
  }

  Future<void> _refreshPostData() async {
    try {
      final updatedPost = await PostService().getPostById(_localPost.id);
      if (updatedPost != null) {
        setState(() {
          _localPost = updatedPost;
        });
        _updateControllersWithPost(updatedPost);
      }
    } catch (e) {
      // Ignore
    }
  }

  void _handleDoubleTap() {
    if (!_isLiked) _toggleLike();
    setState(() => _showLargeHeart = true);
  }

  void _showComments(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(postId: _localPost.id),
    );
    _refreshPostData();
  }

  void _showShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SharePostBottomSheet(post: _localPost),
    );
  }

  void _showOptions(BuildContext context) {
    final ctrl = _ctrl;
    final bool isOwnPost = _localPost.usuario.id == _myId;

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: AppColors.containerBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            
            // Ver Perfil
            ListTile(
              leading: Icon(Icons.account_circle_outlined, color: AppColors.textHeader),
              title: Text('view_profile'.tr, style: TextStyle(color: AppColors.textHeader)),
              onTap: () {
                Get.back();
                Get.to(() => ProfileScreen(userId: _localPost.usuario.id), preventDuplicates: false);
              },
            ),

            // Compartir
            ListTile(
              leading: Icon(Icons.send_outlined, color: AppColors.textHeader),
              title: Text('share'.tr, style: TextStyle(color: AppColors.textHeader)),
              onTap: () {
                Get.back();
                _showShareSheet(context);
              },
            ),

            // Editar (Si es mío)
            if (isOwnPost && ctrl != null)
              ListTile(
                leading: Icon(Icons.edit_outlined, color: AppColors.textHeader),
                title: Text('edit_post'.tr, style: TextStyle(color: AppColors.textHeader)),
                onTap: () {
                  Get.back();
                  _showEditDialog(context, ctrl);
                },
              ),

            // Dejar de seguir (Si no es mío)
            if (!isOwnPost && ctrl != null)
              ListTile(
                leading: Icon(Icons.person_remove_outlined, color: AppColors.error),
                title: Text('${'unfollow_user'.tr} ${_localPost.usuario.nombre}', 
                  style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Get.back();
                  _confirmUnfollow(context, ctrl);
                },
              ),

            // Reportar (Si no es mío)
            if (!isOwnPost)
              ListTile(
                leading: Icon(Icons.report_problem_outlined, color: AppColors.error),
                title: Text('report_post'.tr, style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Get.back();
                  UIUtils.showReportBottomSheet(
                    targetId: _localPost.id,
                    tipo: 'post',
                    title: 'this_post'.tr,
                  );
                },
              ),

            // Eliminar (Si es mío)
            if (isOwnPost && ctrl != null)
              ListTile(
                leading: Icon(Icons.delete_outline, color: AppColors.error),
                title: Text('delete_post'.tr, style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Get.back();
                  _confirmDelete(context, ctrl);
                },
              ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, HomeController ctrl) {
    final TextEditingController editCtrl = TextEditingController(text: _localPost.caption);
    
    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'edit_description'.tr,
                  style: GoogleFonts.inter(
                    color: AppColors.textHeader,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Get.back();
                    ctrl.editPost(_localPost.id, editCtrl.text.trim());
                  },
                  child: Text(
                    'save'.tr,
                    style: GoogleFonts.inter(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: AppColors.border, height: 24),
            
            // Input Field
            TextField(
              controller: editCtrl,
              maxLines: 5,
              style: GoogleFonts.inter(color: AppColors.textHeader),
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'what_are_you_thinking'.tr,
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.containerBg.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _confirmUnfollow(BuildContext context, HomeController ctrl) {
    UIUtils.showUnfollowBottomSheet(
      userId: _localPost.usuario.id,
      nombre: _localPost.usuario.nombre,
      onConfirm: () => ctrl.toggleFollow(_localPost.usuario.id, _localPost.usuario.nombre),
    );
  }

  void _confirmDelete(BuildContext context, HomeController ctrl) {
    UIUtils.showDeletePostBottomSheet(
      onConfirm: () => ctrl.deletePost(_localPost.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Get.to(() => ProfileScreen(userId: _localPost.usuario.id), preventDuplicates: false),
                  child: SafeCircleAvatar(
                    radius: 18,
                    url: _localPost.usuario.avatarUrl,
                    name: _localPost.usuario.nombre,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Get.to(() => ProfileScreen(userId: _localPost.usuario.id), preventDuplicates: false),
                    child: Text(
                      _localPost.usuario.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.textHeader, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Icon(Icons.more_horiz, color: AppColors.textMuted),
                  onPressed: () => _showOptions(context),
                ),
              ],
            ),
          ),

          // MEDIA
          if (_localPost.imageUrl?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onDoubleTap: _handleDoubleTap,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          _localPost.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(color: Colors.white10),
                        ),
                        LargeHeartAnim(
                          isVisible: _showLargeHeart,
                          onFinished: () => setState(() => _showLargeHeart = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ACTION BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // LIKE ACTION
                GestureDetector(
                  onTap: _toggleLike,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HeartAnimButton(
                        isLiked: _isLiked,
                        size: 24,
                        onTap: _toggleLike,
                        color: _isLiked ? Colors.redAccent : AppColors.textHeader,
                      ),
                      SizedBox(width: 6),
                      Text(
                        Post.formatCount(_localPost.likes.length),
                        style: GoogleFonts.inter(
                          color: AppColors.textHeader,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                
                // COMMENT ACTION
                GestureDetector(
                  onTap: () => _showComments(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textHeader, size: 22),
                      SizedBox(width: 6),
                      Text(
                        Post.formatCount(_localPost.commentsCount),
                        style: GoogleFonts.inter(
                          color: AppColors.textHeader,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                
                // SHARE ACTION
                GestureDetector(
                  onTap: () => _showShareSheet(context),
                  child: Icon(Icons.send_rounded, color: AppColors.textHeader, size: 20),
                ),
                // Pushes the bookmark icon button entirely to the right side
                const Spacer(),
                //BOOKMARK ACTION
                GestureDetector(
                  onTap: _handleBookmarkTap,
                  child: Icon(
                    _localPost.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _localPost.isSaved ? AppColors.accent : AppColors.textHeader,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // CAPTION
          if (_localPost.caption?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_localPost.usuario.nombre} ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      _localPost.caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // FOOTER
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Text(
              _localPost.timeAgo,
              style: TextStyle(color: AppColors.textMuted.withOpacity(0.5), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
