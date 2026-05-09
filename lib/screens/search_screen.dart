import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../services/user_service.dart';
import '../widgets/user_card.dart';
import '../widgets/filter_modal.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final UserService _userService = UserService();
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

  // Filter Data State
  List<String> selectedFilters = [];
  List<dynamic> universidades = [];
  List<dynamic> grados = [];
  List<dynamic> asignaturas = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (value.trim().isEmpty && selectedFilters.isEmpty) {
        setState(() {
          users = [];
          hasTyped = false;
          hasNextPage = false;
        });
        return;
      }
      performSearch(1, isNewSearch: true);
    });
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
      Get.snackbar(
        'Error',
        'No se pudo realizar la búsqueda',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
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
          performSearch(1, isNewSearch: true);
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Filter Toggle Button
          GestureDetector(
            onTap: _openFilters,
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: AppColors.containerBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.tune_rounded, color: Colors.white),
                  if (selectedFilters.isNotEmpty)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.textLink,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            selectedFilters.length.toString(),
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text Search Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.containerBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar usuarios...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
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

  Widget _buildOnboarding() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.containerBg,
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                size: 60,
                color: Colors.white24,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Encuentra estudiantes',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Busca personas por universidad, grado o asignaturas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (!hasTyped && selectedFilters.isEmpty) {
      return _buildOnboarding();
    }

    if (isLoading && users.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textLink),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron usuarios',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      itemCount: users.length + 1,
      itemBuilder: (context, index) {
        if (index == users.length) {
          if (isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.textLink),
              ),
            );
          }
          if (!hasNextPage && users.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No hay más resultados',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return UserCard(
          user: users[index],
          onTap: () {
            // TODO: Navigate to Profile
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Explorar',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildSearchBar(),
          const SizedBox(height: 12),
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }
}