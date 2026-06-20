import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../constants/app_colors.dart';
import '../models/evento.dart';
import '../services/evento_service.dart';
import '../services/storage_service.dart';
import '../controllers/theme_controller.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final EventoService _eventoService = EventoService();
  final StorageService _storageService = StorageService();
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  List<Evento> _eventos = [];
  bool _loading = true;
  LatLng _userCoords = const LatLng(41.3892, 2.1130);
  bool _hasLocationPermission = false;

  // Active state
  Evento? _selectedEvento;
  bool _isCreating = false;
  LatLng? _tempCoords;

  // Distance filter
  bool _showDistanceFilter = false;
  double _maxDistance = 5000.0;
  double _currentZoom = 15.0;

  // Current user info
  String _currentUserId = '';
  String _currentUserRol = '';

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ubicacionNameCtrl = TextEditingController();
  final _maxAsistentesCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _selectedDeadlineDate;

  late AnimationController _pulseController;

  int _getDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000;
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLon = (lon2 - lon1) * pi / 180;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return (r * c).round();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadUserInfo();
    _initLocationAndEvents();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _ubicacionNameCtrl.dispose();
    _maxAsistentesCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userJsonStr = await _storageService.getUserData();
      if (userJsonStr != null) {
        final userData = jsonDecode(userJsonStr);
        setState(() {
          _currentUserId = userData['_id'] ?? '';
          _currentUserRol = userData['rol'] ?? 'user';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data in map: $e');
    }
  }

  Future<void> _initLocationAndEvents() async {
    setState(() => _loading = true);
    await _determinePosition();
    await _fetchEventos();
    setState(() => _loading = false);
  }

  Future<void> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      _hasLocationPermission = true;
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _userCoords = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_userCoords, 15.0);
    } catch (e) {
      debugPrint('Location service error: $e');
    }
  }

  Future<void> _fetchEventos() async {
    try {
      final eventos = await _eventoService.getEventos(
        lat: _userCoords.latitude,
        lng: _userCoords.longitude,
      );
      setState(() {
        _eventos = eventos;
      });
    } catch (e) {
      Get.snackbar('Error', 'No se pudieron cargar los eventos del servidor',
          backgroundColor: AppColors.error.withOpacity(0.8), colorText: Colors.white);
    }
  }

  // ── State Transitions ─────────────────────────────────────────────────────

  void _onMapTap(LatLng point) {
    if (_isCreating) {
      // Only move the pin; the form stays open in the sheet
      setState(() => _tempCoords = point);
      _mapController.move(point, _mapController.camera.zoom);
    } else {
      setState(() => _selectedEvento = null);
    }
  }

  void _selectEvento(Evento ev) {
    setState(() {
      _selectedEvento = ev;
      _isCreating = false;
      _tempCoords = null;
    });
    _mapController.move(LatLng(ev.latitude, ev.longitude), 16.0);
    if (_sheetController.isAttached) {
      _sheetController.animateTo(0.52,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _startCreationFlow() {
    setState(() {
      _isCreating = true;
      _selectedEvento = null;
      _tempCoords = LatLng(_userCoords.latitude + 0.0005, _userCoords.longitude + 0.0005);
    });
    _mapController.move(_tempCoords!, 16.0);
    if (_sheetController.isAttached) {
      _sheetController.animateTo(0.65,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  // ── API Actions ───────────────────────────────────────────────────────────

  Future<void> _submitCreation() async {
    if (!_formKey.currentState!.validate() || _tempCoords == null) return;
    try {
      final response = await _eventoService.createEvento({
        'titulo': _tituloCtrl.text.trim(),
        'descripcion': _descCtrl.text.trim(),
        'ubicacionNombre': _ubicacionNameCtrl.text.trim(),
        'fecha': _selectedDate.toIso8601String(),
        'fechaLimite': _selectedDeadlineDate?.toIso8601String(),
        'lat': _tempCoords!.latitude,
        'lng': _tempCoords!.longitude,
        'maxAsistentes':
            _maxAsistentesCtrl.text.isEmpty ? null : int.parse(_maxAsistentesCtrl.text),
      });
      if (response != null) {
        setState(() {
          _eventos.add(response);
          _selectedEvento = response;
          _isCreating = false;
          _tempCoords = null;
          _selectedDeadlineDate = null;
        });
        _tituloCtrl.clear();
        _descCtrl.clear();
        _ubicacionNameCtrl.clear();
        _maxAsistentesCtrl.clear();
        if (_sheetController.isAttached) {
          _sheetController.animateTo(0.52,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
        Get.snackbar('success'.tr, 'map_event_published_success'.tr,
            backgroundColor: AppColors.success.withOpacity(0.8), colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'map_event_create_error'.tr,
          backgroundColor: AppColors.error.withOpacity(0.8), colorText: Colors.white);
    }
  }

  Future<void> _toggleAsistir(Evento ev) async {
    try {
      final updated = await _eventoService.asistirEvento(ev.id);
      if (updated != null) {
        setState(() {
          _selectedEvento = updated;
          final index = _eventos.indexWhere((e) => e.id == ev.id);
          if (index != -1) _eventos[index] = updated;
        });
      }
    } catch (e) {
      String msg = 'map_event_join_error'.tr;
      if (e is DioException && e.response?.data != null) {
        msg = e.response?.data['message'] ?? msg;
      }
      Get.snackbar('error'.tr, msg,
          backgroundColor: AppColors.error.withOpacity(0.8), colorText: Colors.white);
    }
  }

  Future<void> _deleteEvento(String id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.containerBg,
        title: Text('map_delete_event_title'.tr, style: TextStyle(color: AppColors.textHeader)),
        content: Text('map_delete_event_msg'.tr,
            style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr, style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Get.back(result: true),
            child: Text('delete'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final ok = await _eventoService.deleteEvento(id);
      if (ok) {
        setState(() {
          _eventos.removeWhere((e) => e.id == id);
          _selectedEvento = null;
        });
        if (_sheetController.isAttached) {
          _sheetController.animateTo(0.1,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
        Get.snackbar('success'.tr, 'map_event_deleted_success'.tr,
            backgroundColor: AppColors.success.withOpacity(0.8), colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'map_event_delete_error'.tr,
          backgroundColor: AppColors.error.withOpacity(0.8), colorText: Colors.white);
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
      filled: true,
      fillColor: AppColors.socialBg,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Sort & filter events by distance
    final sorted = _eventos.map((ev) {
      final dist = _getDistance(
          _userCoords.latitude, _userCoords.longitude, ev.latitude, ev.longitude);
      return MapEntry(ev, dist);
    }).toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final filteredEventos = _showDistanceFilter
        ? sorted.where((e) => e.value <= _maxDistance).toList()
        : sorted;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // ── 1. Map ──────────────────────────────────────────────────────
          Obx(() {
            bool isDark = true;
            try {
              isDark = Get.find<ThemeController>().isDarkMode.value;
            } catch (_) {}
            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userCoords,
                initialZoom: _currentZoom,
                onTap: (_, point) => _onMapTap(point),
                onMapEvent: (event) {
                  if (event is MapEventMove) {
                    setState(() => _currentZoom = event.camera.zoom);
                  }
                },
              ),
              children: [
                // Tile layer (dark/light)
                TileLayer(
                  urlTemplate: isDark
                      ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                      : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.ea.app.g5',
                  retinaMode: RetinaMode.isHighDensity(context),
                ),
                // User location pulsing marker
                MarkerLayer(markers: [
                  Marker(
                    point: _userCoords,
                    width: 40,
                    height: 40,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse Glow
                            Container(
                              width: 12 + (28 * _pulseController.value),
                              height: 12 + (28 * _pulseController.value),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.4 * (1 - _pulseController.value)),
                              ),
                            ),
                            // Inner Dot
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ]),
                // Distance filter circle
                if (_showDistanceFilter)
                  CircleLayer(circles: [
                    CircleMarker(
                      point: _userCoords,
                      radius: _maxDistance,
                      useRadiusInMeter: true,
                      color: AppColors.accent.withOpacity(0.05),
                      borderColor: AppColors.accent.withOpacity(0.4),
                      borderStrokeWidth: 1.5,
                    ),
                  ]),
                // Temp creation marker
                if (_isCreating && _tempCoords != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: _tempCoords!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Colors.amber, size: 40),
                    ),
                  ]),
                // Event markers
                MarkerLayer(
                  markers: filteredEventos.map((entry) {
                    final ev = entry.key;
                    final isSelected = _selectedEvento?.id == ev.id;
                    return Marker(
                      point: LatLng(ev.latitude, ev.longitude),
                      width: isSelected ? 48 : 36,
                      height: isSelected ? 48 : 36,
                      child: GestureDetector(
                        onTap: () => _selectEvento(ev),
                        child: Icon(
                          Icons.place_rounded,
                          color: isSelected ? AppColors.accent : AppColors.accent.withOpacity(0.75),
                          size: isSelected ? 48 : 36,
                          shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          }),

          // ── 2. Loading indicator ────────────────────────────────────────
          if (_loading)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.containerBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                    const SizedBox(width: 12),
                    Text('map_loading_events'.tr, style: TextStyle(color: AppColors.textMuted)),
                  ]),
                ),
              ),
            ),

          // ── 3. Back button ─────────────────────────────────────────────
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: AppColors.containerBg,
              radius: 22,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: AppColors.textHeader),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // ── 4. Zoom + Location + Add FABs ──────────────────────────────
          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapZoomButton(
                  icon: Icons.add,
                  heroTag: 'zoom_in_btn',
                  onPressed: () {
                    final z = (_currentZoom + 1).clamp(2.0, 19.0);
                    setState(() => _currentZoom = z);
                    _mapController.move(_mapController.camera.center, z);
                  },
                ),
                const SizedBox(height: 8),
                _MapZoomButton(
                  icon: Icons.remove,
                  heroTag: 'zoom_out_btn',
                  onPressed: () {
                    final z = (_currentZoom - 1).clamp(2.0, 19.0);
                    setState(() => _currentZoom = z);
                    _mapController.move(_mapController.camera.center, z);
                  },
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: 'my_pos_btn',
                  backgroundColor: AppColors.containerBg,
                  onPressed: _determinePosition,
                  child: Icon(Icons.my_location, color: AppColors.textHeader),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'add_ev_btn',
                  backgroundColor: _isCreating ? Colors.amber : AppColors.accent,
                  onPressed: _isCreating
                      ? () {
                          setState(() {
                            _isCreating = false;
                            _tempCoords = null;
                          });
                          if (_sheetController.isAttached) {
                            _sheetController.animateTo(0.1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut);
                          }
                        }
                      : _startCreationFlow,
                  child: Icon(
                    _isCreating ? Icons.close : Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          // ── 5. DraggableScrollableSheet (form / details / list) ─────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.1,
            minChildSize: 0.08,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.containerBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 1),
                  ],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // Grab handle
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // ── CREATION FORM ─────────────────────────────────────
                    if (_isCreating) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('map_create_event'.tr,
                                        style: GoogleFonts.inter(
                                            color: AppColors.textHeader,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: Icon(Icons.close, color: AppColors.textMuted),
                                      onPressed: () => setState(() {
                                        _isCreating = false;
                                        _tempCoords = null;
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Info / coords banner
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.accentBorder),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.info_outline,
                                        color: AppColors.accent, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _tempCoords != null
                                            ? '📍 ${_tempCoords!.latitude.toStringAsFixed(5)}, ${_tempCoords!.longitude.toStringAsFixed(5)}\n' + 'map_adjust_location'.tr
                                            : 'map_place_marker'.tr,
                                        style: GoogleFonts.inter(
                                            color: AppColors.textHeader, fontSize: 12),
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _tituloCtrl,
                                  style: TextStyle(color: AppColors.textHeader),
                                  decoration: _inputDecoration('map_event_title_label'.tr),
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'map_event_title_error'.tr : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _descCtrl,
                                  maxLines: 2,
                                  style: TextStyle(color: AppColors.textHeader),
                                  decoration: _inputDecoration('map_event_desc_label'.tr),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'map_event_desc_error'.tr
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _ubicacionNameCtrl,
                                  style: TextStyle(color: AppColors.textHeader),
                                  decoration:
                                      _inputDecoration('map_event_location_label'.tr),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'map_event_location_error'.tr
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _maxAsistentesCtrl,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(color: AppColors.textHeader),
                                      decoration: _inputDecoration('map_event_max_attendees_label'.tr),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppColors.border),
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null && mounted) {
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.fromDateTime(_selectedDate),
                                          );
                                          if (time != null) {
                                            setState(() {
                                              _selectedDate = DateTime(
                                                  picked.year,
                                                  picked.month,
                                                  picked.day,
                                                  time.hour,
                                                  time.minute);
                                              if (_selectedDeadlineDate != null &&
                                                  _selectedDeadlineDate!.isAfter(_selectedDate)) {
                                                _selectedDeadlineDate = null;
                                              }
                                            });
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_month,
                                          color: AppColors.accent, size: 16),
                                      label: Text(DateFormat('dd/MM HH:mm').format(_selectedDate),
                                          style: GoogleFonts.inter(
                                              color: AppColors.textHeader, fontSize: 12)),
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppColors.border),
                                        padding: const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDeadlineDate ?? _selectedDate,
                                          firstDate: DateTime.now(),
                                          lastDate: _selectedDate,
                                        );
                                        if (picked != null && mounted) {
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.fromDateTime(
                                                _selectedDeadlineDate ?? _selectedDate),
                                          );
                                          if (time != null) {
                                            setState(() => _selectedDeadlineDate = DateTime(
                                                picked.year,
                                                picked.month,
                                                picked.day,
                                                time.hour,
                                                time.minute));
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.timer_outlined,
                                          color: Colors.amber, size: 16),
                                      label: Text(
                                          _selectedDeadlineDate == null
                                              ? 'map_event_deadline_optional'.tr
                                              : 'map_event_deadline_prefix'.tr + DateFormat('dd/MM HH:mm').format(_selectedDeadlineDate!),
                                          style: GoogleFonts.inter(
                                              color: AppColors.textHeader, fontSize: 12)),
                                    ),
                                  ),
                                  if (_selectedDeadlineDate != null) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.redAccent, size: 18),
                                      onPressed: () => setState(() => _selectedDeadlineDate = null),
                                    ),
                                  ],
                                ]),
                                const SizedBox(height: 18),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _submitCreation,
                                  child: Text('map_publish_event'.tr,
                                      style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]

                    // ── EVENT DETAILS ──────────────────────────────────────
                    else if (_selectedEvento != null) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentBg,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.accentBorder),
                                    ),
                                    child: Text('map_event_detail_title'.tr,
                                        style: GoogleFonts.inter(
                                            color: AppColors.accent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close, color: AppColors.textMuted),
                                    onPressed: () =>
                                        setState(() => _selectedEvento = null),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(_selectedEvento!.titulo,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textHeader,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Row(children: [
                                Icon(Icons.access_time_rounded,
                                    color: AppColors.textMuted, size: 15),
                                const SizedBox(width: 5),
                                Text(
                                    DateFormat('dd MMM, HH:mm')
                                        .format(_selectedEvento!.fecha),
                                    style: GoogleFonts.inter(
                                        color: AppColors.textMuted, fontSize: 13)),
                                const SizedBox(width: 12),
                                Icon(Icons.location_on_outlined,
                                    color: AppColors.textMuted, size: 15),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(_selectedEvento!.ubicacionNombre,
                                      style: GoogleFonts.inter(
                                          color: AppColors.textMuted, fontSize: 13),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                              if (_selectedEvento!.fechaLimite != null) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Icon(Icons.timer_outlined,
                                      color: Colors.amber, size: 15),
                                  const SizedBox(width: 5),
                                  Text(
                                      'map_registration_limit'.tr + DateFormat('dd MMM, HH:mm').format(_selectedEvento!.fechaLimite!),
                                      style: GoogleFonts.inter(
                                          color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w500)),
                                ]),
                              ],
                              const SizedBox(height: 12),
                              Text(_selectedEvento!.descripcion,
                                  style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                      height: 1.4)),
                              Divider(color: AppColors.border, height: 28),
                              Row(children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.border,
                                  backgroundImage: _selectedEvento!.creador.avatarUrl != null
                                      ? NetworkImage(_selectedEvento!.creador.avatarUrl!)
                                      : const NetworkImage(
                                          'https://api.dicebear.com/7.x/avataaars/png?seed=anon'),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('map_organized_by'.tr,
                                          style: GoogleFonts.inter(
                                              color: AppColors.textMuted, fontSize: 11)),
                                      Text(_selectedEvento!.creador.nombre,
                                          style: GoogleFonts.inter(
                                              color: AppColors.textHeader,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                    ]),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                Icon(Icons.people_outline,
                                    color: AppColors.textMuted, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'map_attendees'.tr + ' (${_selectedEvento!.asistentes.length}'
                                  '${_selectedEvento!.maxAsistentes != null ? ' / ${_selectedEvento!.maxAsistentes}' : ''})',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textHeader,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              if (_selectedEvento!.asistentes.isEmpty)
                                Text('map_no_attendees'.tr,
                                    style: GoogleFonts.inter(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic))
                              else
                                SizedBox(
                                  height: 34,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedEvento!.asistentes.length,
                                    itemBuilder: (_, idx) {
                                      final a = _selectedEvento!.asistentes[idx];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 5),
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: AppColors.border,
                                          backgroundImage: a.avatarUrl != null
                                              ? NetworkImage(a.avatarUrl!)
                                              : const NetworkImage(
                                                  'https://api.dicebear.com/7.x/avataaars/png?seed=user'),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 20),
                              Builder(builder: (_) {
                                final isJoined = _selectedEvento!.asistentes
                                    .any((a) => a.id == _currentUserId);
                                return Row(children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isJoined
                                            ? AppColors.containerBg
                                            : AppColors.accent,
                                        side: isJoined
                                            ? BorderSide(color: AppColors.border)
                                            : null,
                                        padding:
                                            const EdgeInsets.symmetric(vertical: 15),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () =>
                                          _toggleAsistir(_selectedEvento!),
                                      child: Text(
                                        isJoined
                                            ? 'map_leave_event'.tr
                                            : 'map_join_event'.tr,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isJoined
                                              ? AppColors.textMuted
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_selectedEvento!.creador.id == _currentUserId ||
                                      _currentUserRol == 'admin') ...[
                                    const SizedBox(width: 10),
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            AppColors.error.withOpacity(0.12),
                                        padding: const EdgeInsets.all(14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: const BorderSide(
                                              color: AppColors.error, width: 0.5),
                                        ),
                                      ),
                                      icon: const Icon(Icons.delete_outline,
                                          color: AppColors.error),
                                      onPressed: () =>
                                          _deleteEvento(_selectedEvento!.id),
                                    ),
                                  ],
                                ]);
                              }),
                            ],
                          ),
                        ),
                      ),
                    ]

                    // ── EVENT LIST ─────────────────────────────────────────
                    else ...[
                      // Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                Text('map_nearby_events'.tr,
                                    style: GoogleFonts.inter(
                                        color: AppColors.textHeader,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Text('${filteredEventos.length}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ),
                                if (filteredEventos.length != _eventos.length) ...[
                                  const SizedBox(width: 6),
                                  Text('map_total_events'.trParams({'count': '${_eventos.length}'}),
                                      style: GoogleFonts.inter(
                                          color: AppColors.textMuted, fontSize: 11)),
                                ],
                              ]),
                              IconButton(
                                icon: Icon(Icons.tune,
                                    color: _showDistanceFilter
                                        ? AppColors.accent
                                        : AppColors.textMuted),
                                onPressed: () => setState(
                                    () => _showDistanceFilter = !_showDistanceFilter),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Distance filter panel
                      if (_showDistanceFilter)
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.socialBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [
                                        Icon(Icons.location_on_outlined,
                                            color: AppColors.textMuted, size: 14),
                                        const SizedBox(width: 4),
                                        Text('map_max_radius'.tr,
                                            style: GoogleFonts.inter(
                                                color: AppColors.textMuted,
                                                fontSize: 13)),
                                      ]),
                                      Text(
                                        _maxDistance >= 1000
                                            ? '${(_maxDistance / 1000).toStringAsFixed(1)} km'
                                            : '${_maxDistance.round()} m',
                                        style: GoogleFonts.inter(
                                            color: AppColors.accent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Slider(
                                    min: 200,
                                    max: 50000,
                                    divisions: 249,
                                    value: _maxDistance,
                                    activeColor: AppColors.accent,
                                    inactiveColor: AppColors.border,
                                    onChanged: (v) =>
                                        setState(() => _maxDistance = v),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('200m',
                                          style: GoogleFonts.inter(
                                              color: AppColors.textMuted,
                                              fontSize: 10)),
                                      Text('50km',
                                          style: GoogleFonts.inter(
                                              color: AppColors.textMuted,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ]),
                          ),
                        ),

                      SliverToBoxAdapter(
                          child: Divider(color: AppColors.border, height: 16)),

                      // Empty state
                      if (filteredEventos.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_off_outlined,
                                        size: 48, color: AppColors.textMuted),
                                    const SizedBox(height: 12),
                                    Text(
                                      _eventos.isEmpty
                                          ? 'map_no_events_platform'.tr
                                          : 'map_no_events_range'.tr,
                                      style: GoogleFonts.inter(
                                          color: AppColors.textMuted, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ]),
                            ),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final entry = filteredEventos[index];
                              final ev = entry.key;
                              final distance = entry.value;
                              final isJoined =
                                  ev.asistentes.any((a) => a.id == _currentUserId);
                              final isCreator = ev.creador.id == _currentUserId;
                              final distText = distance < 1000
                                  ? '${distance}m'
                                  : '${(distance / 1000).toStringAsFixed(1)}km';

                              return InkWell(
                                onTap: () => _selectEvento(ev),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: AppColors.borderWhite)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(ev.titulo,
                                                style: GoogleFonts.inter(
                                                    color: AppColors.textHeader,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            Text(ev.descripcion,
                                                style: GoogleFonts.inter(
                                                    color: AppColors.textMuted,
                                                    fontSize: 13),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 6),
                                            Row(children: [
                                              const Icon(
                                                  Icons.navigation_outlined,
                                                  size: 12,
                                                  color: AppColors.accent),
                                              const SizedBox(width: 3),
                                              Text(distText,
                                                  style: GoogleFonts.inter(
                                                      color: AppColors.textMuted,
                                                      fontSize: 11)),
                                              const SizedBox(width: 10),
                                              Icon(Icons.calendar_today_outlined,
                                                  size: 12,
                                                  color: AppColors.textMuted),
                                              const SizedBox(width: 3),
                                              Text(
                                                  DateFormat('dd/MM/yy')
                                                      .format(ev.fecha),
                                                  style: GoogleFonts.inter(
                                                      color: AppColors.textMuted,
                                                      fontSize: 11)),
                                              const SizedBox(width: 10),
                                              Icon(Icons.people_outline,
                                                  size: 12,
                                                  color: AppColors.textMuted),
                                              const SizedBox(width: 3),
                                              Text('${ev.asistentes.length}',
                                                  style: GoogleFonts.inter(
                                                      color: AppColors.textMuted,
                                                      fontSize: 11)),
                                            ]),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          if (isJoined)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                              margin:
                                                  const EdgeInsets.only(bottom: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.success
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: AppColors.success
                                                        .withOpacity(0.3)),
                                              ),
                                              child: Text('map_attending'.tr,
                                                  style: const TextStyle(
                                                      color: AppColors.success,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          if (isCreator)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                    color: Colors.amber
                                                        .withOpacity(0.3)),
                                              ),
                                              child: Text('map_creator'.tr,
                                                  style: const TextStyle(
                                                      color: Colors.amber,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: filteredEventos.length,
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Small square zoom control button — mirrors EA_WEB_G5 Leaflet zoom controls.
class _MapZoomButton extends StatelessWidget {
  final IconData icon;
  final String heroTag;
  final VoidCallback onPressed;

  const _MapZoomButton({
    required this.icon,
    required this.heroTag,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.containerBg,
      borderRadius: BorderRadius.circular(10),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Icon(icon, color: AppColors.textHeader, size: 22),
        ),
      ),
    );
  }
}
