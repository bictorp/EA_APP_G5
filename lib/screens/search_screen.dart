import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../services/user_service.dart';
import '../services/post_service.dart';
import '../models/post.dart';  
import '../widgets/post_card.dart';
import '../widgets/user_card.dart';
import '../widgets/filter_modal.dart';
import '../controllers/theme_controller.dart';

class SearchScreen extends StatefulWidget {
  SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final UserService _userService = UserService();
  final PostService _postService = PostService(); // Initialize PostService
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  // Search Results State
  List<dynamic> users = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasTyped = false;
  bool hasNextPage = false;
  int page = 1;

  // Discovery Posts State
  List<Post> discoveryPosts = [];
  bool isLoadingDiscovery = false;

  // Filter Data State
  List<String> selectedFilters = [];
  List<dynamic> universidades = [];
  List<dynamic> grados = [];
  List<dynamic> asignaturas = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadDiscoveryFeed(); // Load posts on startup
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Fetch the discovery posts
  Future<void> _loadDiscoveryFeed() async {
    setState(() => isLoadingDiscovery = true);
    final result = await _postService.getDiscoveryFeed(page: 1, limit: 20);
    setState(() {
      discoveryPosts = result['posts'] ?? [];
      isLoadingDiscovery = false;
    });
  }

void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(Duration(milliseconds: 400), () {
      final bool isSearchEmpty = value.trim().isEmpty && selectedFilters.isEmpty;
      
      if (isSearchEmpty) {
        setState(() {
          users = [];
          hasTyped = false; // Resetting this is key
          hasNextPage = false;
          page = 1;
        });
        // Optionally refresh discovery feed when returning to idle state
        _loadDiscoveryFeed(); 
        return;
      }
      
      performSearch(1, isNewSearch: true);
    });
  }

  // Also update the filter callback to handle empty selections
  void _openFilters() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterModal(
        selected: selectedFilters,
        onApply: (ids, fetchedUnis, fetchedGrados, fetchedAsigs) {
          setState(() {
            selectedFilters = ids;
            universidades = fetchedUnis;
            grados = fetchedGrados;
            asignaturas = fetchedAsigs;
          });

          // Check if clearing filters makes the search "empty"
          if (_searchController.text.trim().isEmpty && ids.isEmpty) {
            setState(() {
              users = [];
              hasTyped = false;
              hasNextPage = false;
            });
            _loadDiscoveryFeed();
          } else {
            performSearch(1, isNewSearch: true);
          }
        },
      ),
    );
  }

  Future<void> performSearch(int pageNum, {bool isNewSearch = false}) async {
    if (isLoading || isLoadingMore) return;
    if (!isNewSearch && !hasNextPage) return;

    setState(() {
      if (isNewSearch) {
        isLoading = true;
      } else {
        isLoadingMore = true;
      }
    });

    try {
      final result = await _userService.searchUsers(
        query: _searchController.text,
        allIds: selectedFilters,
        allUnis: universidades,
        allGrados: grados,
        allAsignaturas: asignaturas,
        page: pageNum,
      );

      if (result != null) {
        final List docs = result['docs'] ?? [];
        final bool more = result['hasNextPage'] ?? false;

        setState(() {
          users = isNewSearch ? docs : [...users, ...docs];
          hasNextPage = more;
          page = pageNum;
          hasTyped = true;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo realizar la búsqueda',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final bool isIdle = _searchController.text.trim().isEmpty && selectedFilters.isEmpty;
    if (isIdle) {
      await _loadDiscoveryFeed();
    } else {
      await performSearch(1, isNewSearch: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        hasNextPage &&
        !isLoadingMore) {
      performSearch(page + 1);
    }
  }


  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openFilters,
            child: Container(
              height: 56, width: 56,
              decoration: BoxDecoration(color: AppColors.containerBg, borderRadius: BorderRadius.circular(16)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.tune_rounded, color: AppColors.textHeader),
                  if (selectedFilters.isNotEmpty)
                    Positioned(top: 10, right: 10, child: CircleAvatar(radius: 9, backgroundColor: AppColors.textLink, child: Text(selectedFilters.length.toString(), style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.containerBg, borderRadius: BorderRadius.circular(16)),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(color: AppColors.textHeader),
                decoration: InputDecoration(
                  hintText: 'Buscar usuarios...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // DISCOVERY GRID VIEW
    Widget _buildDiscoveryFeed() {
  if (isLoadingDiscovery && discoveryPosts.isEmpty) {
    return Center(child: CircularProgressIndicator(color: AppColors.textLink));
  }

  return RefreshIndicator(
    onRefresh: _handleRefresh,
    color: AppColors.textLink,
    backgroundColor: AppColors.bg,
    child: GridView.builder(
      physics: AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(2),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: discoveryPosts.length,
      itemBuilder: (context, index) {
        final post = discoveryPosts[index];
        
        return GestureDetector(
          onTap: () {
            Get.to(
              () => Scaffold(
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
                    style: GoogleFonts.inter(color: AppColors.textHeader, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                body: SingleChildScrollView(
                  child: PostCard(post: post),
                ),
              ),
              transition: Transition.cupertino,
            );
          },
          child: Hero(
            tag: 'post_${post.id}', 
            child: Image.network(
              post.imageUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.containerBg,
                child: Icon(Icons.broken_image, color: AppColors.textMuted),
              ),
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildResults() {
    // Determine if we are in "Idle/Discovery" mode
    final bool isIdle = _searchController.text.trim().isEmpty && selectedFilters.isEmpty;

    if (isIdle) {
      return _buildDiscoveryFeed();
    }

    // While searching/loading
    if (isLoading && users.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.textLink));
    }

    // Search gave 0 results
    if (users.isEmpty && hasTyped) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.textLink,
        backgroundColor: AppColors.bg,
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Text(
                'No se encontraron usuarios',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    // Show User Results
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.textLink,
      backgroundColor: AppColors.bg,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
        controller: _scrollController,
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      itemCount: users.length + 1,
      itemBuilder: (context, index) {
        if (index == users.length) {
          return isLoadingMore 
            ? Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(color: AppColors.textLink)),
              )
            : const SizedBox.shrink();
        }
        return UserCard(user: users[index], onTap: () {});
      },
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(() {
      final _ = themeController.isDarkMode.value;
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          elevation: 0,
          title: Text('Explorar', style: GoogleFonts.inter(color: AppColors.textHeader, fontWeight: FontWeight.w800, fontSize: 22)),
        ),
        body: Column(
          children: [
            SizedBox(height: 8),
            _buildSearchBar(),
            SizedBox(height: 12),
            Expanded(child: _buildResults()),
          ],
        ),
      );
    });
  }
}