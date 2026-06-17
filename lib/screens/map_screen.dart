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
  LatLng _userCoords = const LatLng(41.3892, 2.1130); // Default to Barcelona UPC
  bool _hasLocationPermission = false;

  // Active state
  Evento? _selectedEvento;
  bool _isCreating = false;
  LatLng? _tempCoords;

  // Distance filter state (matching web version)
  bool _showDistanceFilter = false;
  double _maxDistance = 5000.0; // Default 5 km in meters

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

  // Helper method to calculate distance in meters (same as web version's getDistance)
  int _getDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000; // Radius of the Earth in meters
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
    _loadUserInfo();
    _initLocationAndEvents();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _ubicacionNameCtrl.dispose();
    _maxAsistentesCtrl.dispose();
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
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      _hasLocationPermission = true;
      final Position position = await Geolocator.getCurrentPosition(
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
      Get.snackbar(
        'Error',
        'No se pudieron cargar los eventos del servidor',
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  void _onMapTap(LatLng point) {
    if (_isCreating) {
      setState(() {
        _tempCoords = point;
      });
      _mapController.move(point, _mapController.camera.zoom);
      _showCreationSheet();
    } else {
      setState(() {
        _selectedEvento = null;
      });
    }
  }

  void _selectEvento(Evento ev) {
    setState(() {
      _selectedEvento = ev;
      _isCreating = false;
      _tempCoords = null;
    });
    _mapController.move(LatLng(ev.latitude, ev.longitude), 16.0);
    _showDetailsSheet(ev);
  }

  void _startCreationFlow() {
    setState(() {
      _isCreating = true;
      _selectedEvento = null;
      _tempCoords = LatLng(_userCoords.latitude + 0.0005, _userCoords.longitude + 0.0005);
    });
    _mapController.move(_tempCoords!, 16.0);
    _showCreationSheet();
  }

  // --- UI Sheets ---

  void _showCreationSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(0.08,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
    showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.containerBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Crear Evento',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white60),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _isCreating = false;
                                _tempCoords = null;
                              });
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accentBg.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.accentBorder.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.accent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Arrastra o toca el mapa para ajustar la ubicación del evento.',
                                style: GoogleFonts.inter(color: AppColors.textHeader, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tituloCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Título del evento *'),
                        validator: (value) => value == null || value.isEmpty ? 'Introduce un título' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Descripción del evento *'),
                        validator: (value) => value == null || value.isEmpty ? 'Introduce una descripción' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ubicacionNameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Nombre del lugar * (Ej: Aula 102)'),
                        validator: (value) => value == null || value.isEmpty ? 'Introduce el nombre del lugar' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _maxAsistentesCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Máx. Asistentes (Opcional)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  final TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(_selectedDate),
                                  );
                                  if (time != null) {
                                    setSheetState(() {
                                      _selectedDate = DateTime(
                                        picked.year, picked.month, picked.day, time.hour, time.minute
                                      );
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.calendar_month, color: AppColors.accent, size: 18),
                              label: Text(
                                DateFormat('dd/MM HH:mm').format(_selectedDate),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _submitCreation(context),
                        child: Text(
                          'Publicar Evento',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetailsSheet(Evento ev) {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(0.08,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
    showBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bool isCreator = ev.creador.id == _currentUserId;
            final bool isAdmin = _currentUserRol == 'admin';
            final bool isJoined = ev.asistentes.any((a) => a.id == _currentUserId);

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.containerBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accentBorder.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Evento',
                            style: GoogleFonts.inter(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedEvento = null;
                            });
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ev.titulo,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: Colors.white60, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMMM, HH:mm').format(ev.fecha),
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on_outlined, color: Colors.white60, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ev.ubicacionNombre,
                            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ev.descripcion,
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14, height: 1.4),
                    ),
                    const Divider(color: AppColors.border, height: 32),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.border,
                          backgroundImage: ev.creador.avatarUrl != null
                              ? NetworkImage(ev.creador.avatarUrl!)
                              : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=anonymous'),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Organizado por',
                              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                            ),
                            Text(
                              ev.creador.nombre,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Asistentes (${ev.asistentes.length}${ev.maxAsistentes != null ? ' / ${ev.maxAsistentes}' : ''})',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (ev.asistentes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Nadie se ha apuntado todavía. ¡Sé el primero!',
                          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      SizedBox(
                        height: 36,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: ev.asistentes.length,
                          itemBuilder: (context, idx) {
                            final as = ev.asistentes[idx];
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.border,
                                backgroundImage: as.avatarUrl != null
                                    ? NetworkImage(as.avatarUrl!)
                                    : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=user'),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isJoined ? AppColors.containerBg : AppColors.accent,
                              side: isJoined ? const BorderSide(color: AppColors.border) : null,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _toggleAsistir(ev, setSheetState),
                            child: Text(
                              isJoined ? 'Abandonar Evento' : 'Apuntarse al Evento',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isJoined ? Colors.white70 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (isCreator || isAdmin) ...[
                          const SizedBox(width: 12),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.error.withOpacity(0.15),
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.error, width: 0.5),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () => _deleteEvento(ev.id),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Request Submissions ---

  Future<void> _submitCreation(BuildContext sheetCtx) async {
    if (!_formKey.currentState!.validate() || _tempCoords == null) return;

    try {
      final response = await _eventoService.createEvento({
        'titulo': _tituloCtrl.text.trim(),
        'descripcion': _descCtrl.text.trim(),
        'ubicacionNombre': _ubicacionNameCtrl.text.trim(),
        'fecha': _selectedDate.toIso8601String(),
        'lat': _tempCoords!.latitude,
        'lng': _tempCoords!.longitude,
        'maxAsistentes': _maxAsistentesCtrl.text.isEmpty ? null : int.parse(_maxAsistentesCtrl.text),
      });

      if (response != null) {
        Navigator.pop(sheetCtx);
        setState(() {
          _eventos.add(response);
          _selectedEvento = response;
          _isCreating = false;
          _tempCoords = null;
        });

        // Reset
        _tituloCtrl.clear();
        _descCtrl.clear();
        _ubicacionNameCtrl.clear();
        _maxAsistentesCtrl.clear();

        _showDetailsSheet(response);
        Get.snackbar(
          'Éxito',
          'Evento publicado exitosamente',
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Hubo un problema al crear el evento',
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _toggleAsistir(Evento ev, StateSetter setSheetState) async {
    try {
      final updated = await _eventoService.asistirEvento(ev.id);
      if (updated != null) {
        setSheetState(() {
          // Update event in sheets state
          ev = updated;
        });
        setState(() {
          // Update event in maps parent list
          final index = _eventos.indexWhere((e) => e.id == ev.id);
          if (index != -1) {
            _eventos[index] = updated;
          }
        });
      }
    } catch (e) {
      String msg = 'No se pudo actualizar la asistencia';
      if (e is DioException && e.response?.data != null) {
        msg = e.response?.data['message'] ?? msg;
      }
      Get.snackbar(
        'Error',
        msg,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteEvento(String id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.containerBg,
        title: const Text('¿Eliminar evento?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción es permanente y no se puede deshacer.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final ok = await _eventoService.deleteEvento(id);
      if (ok) {
        Navigator.pop(context); // Close details sheet
        setState(() {
          _eventos.removeWhere((e) => e.id == id);
          _selectedEvento = null;
        });
        Get.snackbar(
          'Éxito',
          'Evento eliminado correctamente',
          backgroundColor: AppColors.success.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo eliminar el evento',
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // --- Helper Methods ---

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
      filled: true,
      fillColor: Colors.black12,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate proximity and sort events
    final sortedEventos = _eventos.map((ev) {
      final dist = _getDistance(
        _userCoords.latitude,
        _userCoords.longitude,
        ev.latitude,
        ev.longitude,
      );
      return MapEntry(ev, dist);
    }).toList();

    // Sort by distance (proximity)
    sortedEventos.sort((a, b) => a.value.compareTo(b.value));

    // Filter by max distance if filter is toggled
    final filteredEventos = _showDistanceFilter
        ? sortedEventos.where((entry) => entry.value <= _maxDistance).toList()
        : sortedEventos;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // 1. Interactive Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userCoords,
              initialZoom: 15.0,
              onTap: (tapPosition, point) => _onMapTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.ea.app.g5',
              ),
              // Search radius CircleLayer (matching web version)
              if (_showDistanceFilter)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _userCoords,
                      radius: _maxDistance, // in meters
                      useRadiusInMeter: true,
                      color: AppColors.accent.withOpacity(0.08),
                      borderColor: AppColors.accent.withOpacity(0.4),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Current user position marker
                  Marker(
                    point: _userCoords,
                    width: 40,
                    height: 40,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: AppColors.accent, blurRadius: 8, spreadRadius: 2),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Temporary marker in creation mode
                  if (_isCreating && _tempCoords != null)
                    Marker(
                      point: _tempCoords!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.add_location_alt_rounded,
                        color: Colors.amber,
                        size: 42,
                      ),
                    ),

                  // Event markers filtered by distance if filter is active
                  ..._eventos.where((ev) {
                    if (!_showDistanceFilter) return true;
                    final distance = _getDistance(
                      _userCoords.latitude,
                      _userCoords.longitude,
                      ev.latitude,
                      ev.longitude,
                    );
                    return distance <= _maxDistance;
                  }).map((ev) {
                    final bool isSelected = _selectedEvento?.id == ev.id;
                    return Marker(
                      point: LatLng(ev.latitude, ev.longitude),
                      width: isSelected ? 55 : 45,
                      height: isSelected ? 55 : 45,
                      child: GestureDetector(
                        onTap: () => _selectEvento(ev),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: isSelected ? Colors.pinkAccent : AppColors.accent,
                            size: isSelected ? 48 : 36,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Loading indicator
          if (_loading)
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  color: AppColors.containerBg,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                        SizedBox(width: 12),
                        Text('Cargando eventos...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 3. Floating Action Bar Controls (shifted upward to avoid overlap with bottom sheet)
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: AppColors.containerBg,
              radius: 22,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'my_pos_btn',
                  backgroundColor: AppColors.containerBg,
                  onPressed: _determinePosition,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'add_ev_btn',
                  backgroundColor: _isCreating ? Colors.amber : AppColors.accent,
                  onPressed: _isCreating
                      ? () {
                          Navigator.pop(context);
                          setState(() {
                            _isCreating = false;
                            _tempCoords = null;
                          });
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

          // 4. Draggable Scrollable Events List (matching sidebar/card view from web version)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.1,
            minChildSize: 0.08,
            maxChildSize: 0.8,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.containerBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
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
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // Header Row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Eventos Cercanos',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${filteredEventos.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (filteredEventos.length != _eventos.length) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${_eventos.length} total)',
                                    style: GoogleFonts.inter(
                                      color: Colors.white30,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.tune,
                                color: _showDistanceFilter ? AppColors.accent : Colors.white60,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showDistanceFilter = !_showDistanceFilter;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Distance Filter panel (if toggled)
                    if (_showDistanceFilter)
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: Colors.white60, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Radio máximo',
                                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _maxDistance >= 1000
                                        ? '${(_maxDistance / 1000).toStringAsFixed(1)} km'
                                        : '${_maxDistance.round()} m',
                                    style: GoogleFonts.inter(
                                      color: AppColors.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                                onChanged: (double val) {
                                  setState(() {
                                    _maxDistance = val;
                                  });
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('200m', style: GoogleFonts.inter(color: Colors.white30, fontSize: 10)),
                                  Text('50km', style: GoogleFonts.inter(color: Colors.white30, fontSize: 10)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Spacer
                    SliverToBoxAdapter(
                      child: const Divider(color: AppColors.border, height: 16),
                    ),

                    // Event Proximity list
                    if (filteredEventos.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_off_outlined,
                                  size: 48,
                                  color: Colors.white30,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _eventos.isEmpty
                                      ? 'No hay eventos en la plataforma.'
                                      : 'No hay eventos en este rango.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
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
                            final isJoined = ev.asistentes.any((a) => a.id == _currentUserId);
                            final isCreator = ev.creador.id == _currentUserId;

                            String distText = distance < 1000
                                ? '${distance}m'
                                : '${(distance / 1000).toStringAsFixed(1)}km';

                            return InkWell(
                              onTap: () {
                                _selectEvento(ev);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppColors.borderWhite)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ev.titulo,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ev.descripcion,
                                            style: GoogleFonts.inter(
                                              color: AppColors.textMuted,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.navigation_outlined, size: 12, color: AppColors.accent),
                                              const SizedBox(width: 4),
                                              Text(
                                                distText,
                                                style: GoogleFonts.inter(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('dd/MM/yyyy').format(ev.fecha),
                                                style: GoogleFonts.inter(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Icon(Icons.people_outline, size: 12, color: AppColors.textMuted),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${ev.asistentes.length}',
                                                style: GoogleFonts.inter(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (isJoined)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(bottom: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.success.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                            ),
                                            child: const Text(
                                              '✓ Asistiré',
                                              style: TextStyle(
                                                color: AppColors.success,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        if (isCreator)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                            ),
                                            child: const Text(
                                              '★ Creador',
                                              style: TextStyle(
                                                color: Colors.amber,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
