import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/universidad_service.dart';
import '../services/grado_service.dart';
import '../services/user_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';

class SelectUniversityScreen extends StatefulWidget {
  const SelectUniversityScreen({super.key});

  @override
  State<SelectUniversityScreen> createState() => _SelectUniversityScreenState();
}

class _SelectUniversityScreenState extends State<SelectUniversityScreen> {
  final UniversidadService _uniService = UniversidadService();
  final GradoService _gradoService = GradoService();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();

  int _currentStep = 1;
  bool _isLoadingData = false;
  bool _isSaving = false;
  String _searchQuery = '';

  List<dynamic> _universidades = [];
  List<dynamic> _grados = [];
  List<dynamic> _asignaturas = [];

  String _selectedUniId = '';
  String _selectedGradoId = '';
  List<String> _selectedAsigIds = [];

  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final userJson = await _storageService.getUserData();
      if (userJson != null) {
        final decoded = jsonDecode(userJson);
        _userId = decoded['_id'];
      }

      final unis = await _uniService.getAllUniversidades();
      setState(() {
        _universidades = unis;
      });
    } catch (e) {
      Get.snackbar('Error', 'Error al cargar universidades',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _fetchGrados() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final grads = await _gradoService.getGradosByUniversidad(_selectedUniId);
      setState(() {
        _grados = grads;
      });
    } catch (e) {
      Get.snackbar('Error', 'Error al cargar grados',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _fetchAsignaturas() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final asigs = await _gradoService.getAsignaturasByGrado(_selectedGradoId);
      setState(() {
        _asignaturas = asigs;
      });
    } catch (e) {
      Get.snackbar('Error', 'Error al cargar asignaturas',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _handleSelectUni(String id) {
    setState(() {
      _selectedUniId = id;
      _selectedGradoId = '';
      _selectedAsigIds = [];
      _searchQuery = '';
    });
  }

  void _handleSelectGrado(String id) {
    setState(() {
      _selectedGradoId = id;
      _selectedAsigIds = [];
      _searchQuery = '';
    });
  }

  void _handleToggleAsignatura(String id) {
    setState(() {
      if (_selectedAsigIds.contains(id)) {
        _selectedAsigIds.remove(id);
      } else {
        _selectedAsigIds.add(id);
      }
    });
  }

  void _handleNext() {
    if (_currentStep == 1 && _selectedUniId.isNotEmpty) {
      setState(() => _currentStep = 2);
      _fetchGrados();
    } else if (_currentStep == 2 && _selectedGradoId.isNotEmpty) {
      setState(() => _currentStep = 3);
      _fetchAsignaturas();
    }
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
        _searchQuery = '';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedUniId.isEmpty || _selectedGradoId.isEmpty || _userId == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Actualizar universidad y grado
      await _userService.updateUser({
        'universidad': _selectedUniId,
        'grado': _selectedGradoId,
      });

      // 2. Actualizar asignaturas
      final updatedUser = await _userService.updateAsignaturas(_userId!, _selectedAsigIds);

      if (updatedUser != null) {
        await _storageService.saveUserData(jsonEncode(updatedUser));
      }

      Get.snackbar('Éxito', 'Perfil configurado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white);

      Future.delayed(const Duration(milliseconds: 1500), () {
        Get.offAllNamed('/home');
      });
    } catch (e) {
      Get.snackbar('Error', 'Error al guardar configuración académica',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  bool _isNextDisabled() {
    if (_currentStep == 1) return _selectedUniId.isEmpty;
    if (_currentStep == 2) return _selectedGradoId.isEmpty;
    if (_currentStep == 3) return _selectedAsigIds.isEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController(text: _searchQuery);
    searchController.selection = TextSelection.fromPosition(TextPosition(offset: searchController.text.length));

    // Filtrar items según búsqueda
    List<dynamic> filteredItems = [];
    if (_currentStep == 1) {
      filteredItems = _universidades.where((item) {
        final name = (item['nombre'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    } else if (_currentStep == 2) {
      filteredItems = _grados.where((item) {
        final name = (item['nombre'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    } else if (_currentStep == 3) {
      filteredItems = _asignaturas.where((item) {
        final name = (item['nombre'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con Gradiente Radial Space Theme
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  AppColors.bgDarkStart,
                  AppColors.bgDarkMid,
                  AppColors.bgDarkEnd,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: AppColors.containerBg.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderWhite, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Barra de Progreso
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildProgressDot(1),
                              _buildProgressLine(1),
                              _buildProgressDot(2),
                              _buildProgressLine(2),
                              _buildProgressDot(3),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Título y Subtítulo
                          Text(
                            _getStepTitle(),
                            style: GoogleFonts.inter(
                              color: AppColors.textHeader,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getStepSubtitle(),
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Buscador (para pasos 1 y 2, opcional paso 3)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border.withOpacity(0.3)),
                            ),
                            child: TextField(
                              controller: searchController,
                              style: GoogleFonts.inter(color: AppColors.textHeader, fontSize: 14),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Buscar...',
                                hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                                icon: Icon(Icons.search, color: AppColors.textMuted, size: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contenido cargable / Lista de opciones
                          SizedBox(
                            height: 250,
                            child: _isLoadingData
                                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                                : filteredItems.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No hay resultados',
                                          style: GoogleFonts.inter(color: AppColors.textMuted),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: filteredItems.length,
                                        separatorBuilder: (context, index) => Divider(color: AppColors.border, height: 1),
                                        itemBuilder: (context, index) {
                                          final item = filteredItems[index];
                                          final String id = item['_id'] ?? item['id'] ?? '';
                                          final String nombre = item['nombre'] ?? '';

                                          final isSelected = _currentStep == 1
                                              ? _selectedUniId == id
                                              : _currentStep == 2
                                                  ? _selectedGradoId == id
                                                  : _selectedAsigIds.contains(id);

                                          return ListTile(
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                            title: Text(
                                              nombre,
                                              style: GoogleFonts.inter(
                                                color: isSelected ? Colors.white : AppColors.textHeader,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                fontSize: 14,
                                              ),
                                            ),
                                            trailing: isSelected
                                                ? const Icon(Icons.check_circle, color: AppColors.accent)
                                                : null,
                                            tileColor: isSelected ? AppColors.accentBg : null,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            onTap: () {
                                              if (_currentStep == 1) {
                                                _handleSelectUni(id);
                                              } else if (_currentStep == 2) {
                                                _handleSelectGrado(id);
                                              } else if (_currentStep == 3) {
                                                _handleToggleAsignatura(id);
                                              }
                                            },
                                          );
                                        },
                                      ),
                          ),
                          const SizedBox(height: 32),

                          // Botones de Navegación del Onboarding
                          Row(
                            children: [
                              if (_currentStep > 1)
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSaving ? null : _handleBack,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: AppColors.accent),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.chevron_left, color: AppColors.accent),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Atrás',
                                          style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_currentStep > 1) const SizedBox(width: 16),
                              Expanded(
                                child: _currentStep < 3
                                    ? CustomButton(
                                        text: 'Siguiente',
                                        onPressed: _isNextDisabled() ? () {} : _handleNext,
                                        // CustomButton has its own disabled / enabled colors internally.
                                      )
                                    : CustomButton(
                                        text: _isSaving ? 'Guardando...' : 'Finalizar',
                                        onPressed: _isNextDisabled() || _isSaving ? () {} : _handleSubmit,
                                        isLoading: _isSaving,
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDot(int stepIndex) {
    final isActive = _currentStep >= stepIndex;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.transparent : AppColors.border,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$stepIndex',
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine(int stepIndex) {
    final isActive = _currentStep > stepIndex;
    return Container(
      width: 40,
      height: 2,
      color: isActive ? AppColors.accent : AppColors.border,
    );
  }

  String _getStepTitle() {
    if (_currentStep == 1) return 'Elige tu Universidad';
    if (_currentStep == 2) return 'Elige tu Grado';
    return 'Tus Asignaturas';
  }

  String _getStepSubtitle() {
    if (_currentStep == 1) return 'Busca tu centro de estudio';
    if (_currentStep == 2) return 'Selecciona tu especialidad o carrera';
    return 'Elige las asignaturas en las que participas';
  }
}
