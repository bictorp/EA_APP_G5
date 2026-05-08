import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bug_service.dart';
import '../constants/app_colors.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final BugService _bugService = BugService();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _repController = TextEditingController();
  bool _isSending = false;

  Future<void> _submit() async {
    if (_tituloController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'El título y la descripción son obligatorios.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSending = true);
    
    final success = await _bugService.reportBug(
      titulo: _tituloController.text.trim(),
      descripcion: _descController.text.trim(),
      comoReplicarlo: _repController.text.trim(),
      plataforma: 'app',
    );

    setState(() => _isSending = false);

    if (success) {
      Get.back();
      Get.snackbar(
        'Bug reportado',
        'Gracias por ayudarnos a mejorar la aplicación.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'No se pudo enviar el reporte de bug. Inténtalo de nuevo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textHeader),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Reportar un Bug',
          style: GoogleFonts.inter(
            color: AppColors.textHeader,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué problema has encontrado?',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuéntanos qué no funciona correctamente para que podamos solucionarlo.',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            Text(
              'Título del problema *',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tituloController,
              style: const TextStyle(color: AppColors.textHeader),
              decoration: InputDecoration(
                hintText: 'Ej. La aplicación se cierra sola',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.containerBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Descripción detallada *',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textHeader),
              decoration: InputDecoration(
                hintText: 'Explica con más detalle qué estabas haciendo y qué ocurrió...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.containerBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              '¿Cómo replicarlo? (Opcional)',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textHeader),
              decoration: InputDecoration(
                hintText: 'Pasos para reproducir el error...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.containerBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSending 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Enviar reporte',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
