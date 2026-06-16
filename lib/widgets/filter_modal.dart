import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../constants/app_colors.dart';
import '../services/grado_service.dart';
import '../services/universidad_service.dart';
import '../controllers/theme_controller.dart';

enum FilterTab {
  universidades,
  grados,
  asignaturas,
}

class FilterModal extends StatefulWidget {
  final List<String> selected;

  // We pass back the selected IDs AND the full data lists so the
  // SearchScreen can categorize them for the API call.
  final Function(
    List<String> selectedIds,
    List<dynamic> unis,
    List<dynamic> grados,
    List<dynamic> asigs,
  ) onApply;

  FilterModal({
    super.key,
    required this.selected,
    required this.onApply,
  });

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  // Logic States
  late List<String> localSelected;
  FilterTab activeTab = FilterTab.universidades;
  String searchTerm = '';
  bool isLoading = false;

  // Data States (Matching your React State)
  List<dynamic> universidades = [];
  List<dynamic> grados = [];
  List<dynamic> asignaturas = [];

  @override
  void initState() {
    super.initState();
    localSelected = [...widget.selected];
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => isLoading = true);

    try {
      // Replace these calls with your actual service methods
      // For example, if you have a GradoService, use that here.
      final uniService = UniversidadService();
      final gradoService = GradoService();

      // Simulating the Promise.all from your React code
      // Note: You need to implement these methods in your services
      final results = await Future.wait([
        uniService.getAllUniversidades(),
        gradoService.getAllGrados(),
        gradoService.getAllAsignaturas(),
      ]);

      setState(() {
        universidades = results[0];
        grados = results[1];
        asignaturas = results[2];
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al cargar filtros',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void toggleSelection(String id) {
    setState(() {
      if (localSelected.contains(id)) {
        localSelected.remove(id);
      } else {
        localSelected.add(id);
      }
    });
  }

  List<dynamic> getFilteredList() {
    List<dynamic> list = [];

    switch (activeTab) {
      case FilterTab.universidades:
        list = universidades;
        break;

      case FilterTab.grados:
        list = grados;
        break;

      case FilterTab.asignaturas:
        list = asignaturas;
        break;
    }

    return list.where((item) {
      final nombre =
          (item['nombre'] ?? '').toString().toLowerCase();

      return nombre.contains(searchTerm.toLowerCase());
    }).toList();
  }

  String getTabTitle(FilterTab tab) {
    switch (tab) {
      case FilterTab.universidades:
        return 'Universidades';

      case FilterTab.grados:
        return 'Grados';

      case FilterTab.asignaturas:
        return 'Asignaturas';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = getFilteredList();
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      final _ = themeController.isDarkMode.value;
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 14),

            // Drag Handle
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            SizedBox(height: 22),

            // TABS (React: .filter-tabs)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: FilterTab.values.map((tab) {
                  final bool isActive = activeTab == tab;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        activeTab = tab;
                        searchTerm = '';
                      }),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 220),
                        margin:
                            const EdgeInsets.symmetric(horizontal: 4),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.textLink
                              : AppColors.containerBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive ? AppColors.textLink : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            getTabTitle(tab),
                            style: GoogleFonts.inter(
                              color: isActive
                                  ? Colors.white
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 18),

            // SEARCH BAR (React: .filter-search)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.containerBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        onChanged: (val) =>
                            setState(() => searchTerm = val),
                        style:
                            GoogleFonts.inter(color: AppColors.textHeader),
                        decoration: InputDecoration(
                          hintText:
                              'Buscar ${getTabTitle(activeTab).toLowerCase()}...',
                          hintStyle: GoogleFonts.inter(
                            color: AppColors.textMuted,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  GestureDetector(
                    onTap: () {
                      setState(() {
                        localSelected.clear();
                      });
                    },
                    child: Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: AppColors.containerBg,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.cleaning_services_outlined,
                        color: AppColors.textLink,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18),

            // CONTENT (React: .filter-content)
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.textLink,
                      ),
                    )
                  : items.isEmpty
                      ? Center(
                          child: Text(
                            'No se encontraron resultados',
                            style: GoogleFonts.inter(
                              color: AppColors.textHeader,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: items.map((item) {
                              final String id =
                                  item['_id'] ?? item['id'] ?? '';

                              final String nombre =
                                  item['nombre'] ?? '';

                              final bool isSelected =
                                  localSelected.contains(id);

                              return GestureDetector(
                                onTap: () =>
                                    toggleSelection(id),
                                child: AnimatedContainer(
                                  duration: Duration(
                                    milliseconds: 180,
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.textLink
                                        : AppColors.containerBg,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.textLink
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nombre,
                                        style:
                                            GoogleFonts.inter(
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textHeader,
                                          fontWeight:
                                              FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),

                                      // React: tag-subtext for degrees
                                      if (activeTab ==
                                              FilterTab.grados &&
                                          item['universidad'] !=
                                              null)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            item['universidad']
                                                    ['nombre'] ??
                                                '',
                                            style:
                                                GoogleFonts.inter(
                                              color: isSelected
                                                  ? Colors.white70
                                                  : AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
            ),

            // ACTIONS (Cancel / Apply)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.border,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.inter(
                          color: AppColors.textHeader,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          localSelected,
                          universidades,
                          grados,
                          asignaturas,
                        );

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            AppColors.textLink,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Aplicar (${localSelected.length})',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}