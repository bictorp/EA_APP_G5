import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/report_service.dart';

class UIUtils {
  static void showUnfollowBottomSheet({
    required String userId,
    required String nombre,
    required VoidCallback onConfirm,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Text(
              '¿Dejar de seguir a $nombre?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Si dejas de seguir a este usuario, dejarás de ver sus publicaciones en tu feed principal.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            
            // Acciones
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                ),
                child: Text(
                  'Dejar de seguir',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  static void showDeletePostBottomSheet({
    required VoidCallback onConfirm,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Text(
              '¿Eliminar publicación?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta acción es definitiva y no se podrá recuperar la publicación ni sus comentarios.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            
            // Acciones
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error.withOpacity(0.1),
                  foregroundColor: AppColors.error,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                ),
                child: Text(
                  'Eliminar publicación',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  static void showReportBottomSheet({
    required String targetId,
    required String tipo, // 'post' | 'comment' | 'user' | 'chat'
    required String title,
  }) {
    final List<String> reasons = [
      'Contenido inapropiado',
      'Spam o estafa',
      'Acoso o bullying',
      'Discurso de odio',
      'Información falsa',
      'Otros'
    ];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Reportar $title',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Por qué quieres reportar este contenido? Tu reporte es anónimo.',
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reasons.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      reasons[index],
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () async {
                      Get.back();
                      final success = await Get.find<ReportService>().reportContent(
                        tipo: tipo,
                        objetivoId: targetId,
                        descripcion: reasons[index],
                      );
                      
                      if (success) {
                        Get.snackbar(
                          'Reporte enviado',
                          'Gracias por ayudarnos a mantener la comunidad segura.',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: AppColors.accent.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          'No se pudo enviar el reporte. Inténtalo de nuevo.',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: AppColors.error.withOpacity(0.9),
                          colorText: Colors.white,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
