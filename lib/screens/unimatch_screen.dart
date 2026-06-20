import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/unimatch_controller.dart';
import '../models/unimatch_profile.dart';
import '../constants/app_colors.dart';

class UnimatchScreen extends StatefulWidget {
  const UnimatchScreen({super.key});

  @override
  State<UnimatchScreen> createState() => _UnimatchScreenState();
}

class _UnimatchScreenState extends State<UnimatchScreen> {
  final UnimatchController controller = Get.put(UnimatchController());
  final CardSwiperController _swiperController = CardSwiperController();
  final ImagePicker _picker = ImagePicker();
  
  // Guardamos el índice de la foto actual para cada perfil en un mapa {profileId: photoIndex}
  final Map<String, int> _photoIndices = {};

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _pickOnboardingImage() async {
    try {
      final XFile? selected = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (selected != null) {
        controller.localOnboardingPhotos.add(selected);
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo seleccionar la imagen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          );
        }

        // Si no han aceptado términos o no tienen fotos cargadas en el onboarding local
        if (!controller.hasAcceptedTerms.value) {
          return _buildWelcomeState();
        }

        if (controller.profiles.isEmpty) {
          return _buildEmptyState();
        }

        return SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🔥 ',
                      style: TextStyle(fontSize: 26),
                    ),
                    Text(
                      'UniMatch',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
                          ).createShader(
                            const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                          ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card stack
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: CardSwiper(
                    controller: _swiperController,
                    cardsCount: controller.profiles.length,
                    cardBuilder: (context, index, percentX, percentY) {
                      final profile = controller.profiles[index];
                      return _buildProfileCard(profile, percentX);
                    },
                    onSwipe: (previousIndex, currentIndex, direction) async {
                      final type = direction == CardSwiperDirection.right ? 'like' : 'dislike';
                      await controller.handleSwipe(previousIndex, type);
                      return true;
                    },
                    allowedSwipeDirection: const AllowedSwipeDirection.only(left: true, right: true),
                    numberOfCardsDisplayed: controller.profiles.length < 3 ? controller.profiles.length : 3,
                    backCardOffset: const Offset(0, 40),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),

              // Bottom control buttons
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dislike Button
                    _buildActionButton(
                      icon: Icons.close_rounded,
                      color: const Color(0xFFEF4444),
                      onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                    ),
                    const SizedBox(width: 40),
                    // Like Button
                    _buildActionButton(
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () => _swiperController.swipe(CardSwiperDirection.right),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileCard(UnimatchProfile profile, int percentX) {
    // Obtener foto actual
    final currentPhotoIndex = _photoIndices[profile.id] ?? 0;
    final hasMultiplePhotos = profile.unimatchPhotos.length > 1;
    
    // Obtener URL de imagen activa
    final String imageUrl = (profile.unimatchPhotos.isNotEmpty && currentPhotoIndex < profile.unimatchPhotos.length)
        ? profile.unimatchPhotos[currentPhotoIndex].imageUrl
        : (profile.avatarUrl ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde');

    // Calcular coincidencias académicas
    final myUser = controller.currentUser.value;
    final myUni = myUser?['universidad'];
    final myUniId = (myUni is String) ? myUni : (myUni is Map ? (myUni['_id'] ?? myUni['id']) : null);
    final profUniId = profile.universidad?['_id'] ?? profile.universidad?['id'];
    final isMatchingUni = profile.universidad != null && myUniId == profUniId;

    final myGrado = myUser?['grado'];
    final myGradoId = (myGrado is String) ? myGrado : (myGrado is Map ? (myGrado['_id'] ?? myGrado['id']) : null);
    final profGradoId = profile.grado?['_id'] ?? profile.grado?['id'];
    final isMatchingDegree = profile.grado != null && myGradoId == profGradoId;

    final List<dynamic> myAsigs = myUser?['asignaturas'] ?? [];
    final List<String> myAsigIds = myAsigs.map((a) => (a is String ? a : (a['_id'] ?? a['id'])).toString()).toList();
    final commonSubjects = profile.asignaturas.where((a) => myAsigIds.contains((a['_id'] ?? a['id']).toString())).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image with single GestureDetector to avoid blocking swipe
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                if (!hasMultiplePhotos) return;
                final double width = MediaQuery.of(context).size.width - 32; // Ajuste por padding de tarjeta
                final double dx = details.localPosition.dx;
                setState(() {
                  if (dx < width / 2) {
                    // Tap izquierda -> foto anterior
                    if (currentPhotoIndex > 0) {
                      _photoIndices[profile.id] = currentPhotoIndex - 1;
                    }
                  } else {
                    // Tap derecha -> foto siguiente
                    if (currentPhotoIndex < profile.unimatchPhotos.length - 1) {
                      _photoIndices[profile.id] = currentPhotoIndex + 1;
                    }
                  }
                });
              },
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.person, size: 80, color: Colors.white24),
                ),
              ),
            ),

            // Top gradient overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 250,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Photo Indicators
            if (hasMultiplePhotos)
              Positioned(
                top: 15,
                left: 15,
                right: 15,
                child: Row(
                  children: List.generate(
                    profile.unimatchPhotos.length,
                    (idx) => Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: idx == currentPhotoIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Info details
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre
                  Text(
                    profile.nombre,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Descripcion
                  if (profile.descripcion != null && profile.descripcion!.isNotEmpty)
                    Text(
                      profile.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Tags con resaltado de afinidad académica
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (profile.universidad != null)
                        _buildTag(
                          icon: '🏫',
                          text: profile.universidad!['nombre'] ?? '',
                          color: const Color(0xFF6366F1),
                          isHighlight: isMatchingUni,
                        ),
                      if (profile.grado != null)
                        _buildTag(
                          icon: '📚',
                          text: profile.grado!['nombre'] ?? '',
                          color: const Color(0xFFEC4899),
                          isHighlight: isMatchingDegree,
                        ),
                      // Mostrar únicamente asignaturas en común y resaltadas
                      ...commonSubjects.map(
                        (a) => _buildTag(
                          icon: '📖',
                          text: a['nombre'] ?? '',
                          color: AppColors.accent,
                          isHighlight: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Swipe Feedback Overlays (Like/Nope)
            if (percentX != 0)
              Positioned(
                top: 40,
                left: percentX > 0 ? 30 : null,
                right: percentX < 0 ? 30 : null,
                child: Transform.rotate(
                  angle: percentX > 0 ? -0.15 : 0.15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: percentX > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.2),
                    ),
                    child: Text(
                      percentX > 0 ? 'LIKE' : 'NOPE',
                      style: TextStyle(
                        color: percentX > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({required String icon, required String text, required Color color, bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.accent.withOpacity(0.3) : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlight ? AppColors.accent : color.withOpacity(0.3),
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$icon ',
            style: const TextStyle(fontSize: 12),
          ),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎓',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 24),
            Text(
              'Has llegado al final del campus',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeader,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay más perfiles por ahora.\n¡Vuelve más tarde para descubrir nuevas personas!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => controller.loadProfiles(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Buscar de nuevo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🔥',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 20),
            Text(
              '¡Bienvenido a UniMatch!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeader,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Conecta con compañeros de tu misma universidad, grado o asignaturas mediante el swipe de tarjetas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Sección de subir al menos 1 foto
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sube al menos 1 foto para empezar:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeader,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Grid de fotos seleccionadas localmente
            Obx(() {
              final photos = controller.localOnboardingPhotos;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: photos.length < 6 ? photos.length + 1 : 6,
                itemBuilder: (context, index) {
                  if (index == photos.length && photos.length < 6) {
                    return GestureDetector(
                      onTap: _pickOnboardingImage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border.withOpacity(0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.add_a_photo_outlined, color: Colors.white60, size: 28),
                      ),
                    );
                  }
                  
                  final file = photos[index];
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: kIsWeb
                              ? Image.network(
                                  file.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(file.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            controller.localOnboardingPhotos.removeAt(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }),
            
            const SizedBox(height: 35),
            Obx(() {
              final isUploading = controller.isUploadingOnboarding.value;
              final hasPhotos = controller.localOnboardingPhotos.isNotEmpty;
              return ElevatedButton(
                onPressed: (!hasPhotos || isUploading) 
                    ? null 
                    : () => controller.uploadOnboardingPhotosAndAcceptTerms(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  disabledBackgroundColor: const Color(0xFFEC4899).withOpacity(0.3),
                ),
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Aceptar Términos y Empezar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
