import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/report_service.dart';
import '../constants/app_colors.dart';

class ReportScreen extends StatefulWidget {
  final String tipo;
  final String objetivoId;

  const ReportScreen({super.key, required this.tipo, required this.objetivoId});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  final List<String> _reasons = [
    'Spam',
    'Contenido inapropiado',
    'Acoso',
    'Información falsa',
    'Odio',
    'Otro'
  ];

  String _selectedReason = 'Spam';

  Future<void> _submit() async {
    setState(() => _isSending = true);
    
    final desc = '$_selectedReason: ${_controller.text.trim()}';
    final success = await _reportService.reportContent(
      tipo: widget.tipo,
      objetivoId: widget.objetivoId,
      descripcion: desc,
    );

    setState(() => _isSending = false);

    if (success) {
      Get.back();
      Get.snackbar(
        'Reporte enviado',
        'Gracias por ayudarnos a mantener la comunidad segura.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'No se pudo enviar el reporte. Inténtalo de nuevo.',
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
          icon: const Icon(Icons.close, color: AppColors.textHeader),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Reportar',
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
              '¿Por qué quieres reportar este ${widget.tipo == 'post' ? 'post' : 'comentario'}?',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu reporte es anónimo, a menos que estés reportando una infracción de propiedad intelectual.',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            
            // Reasons List (Selectable)
            ..._reasons.map((reason) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _selectedReason == reason ? AppColors.accent.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedReason == reason ? AppColors.accent : AppColors.border,
                  width: 1,
                ),
              ),
              child: ListTile(
                title: Text(
                  reason,
                  style: GoogleFonts.inter(
                    color: _selectedReason == reason ? AppColors.accent : AppColors.textHeader,
                    fontWeight: _selectedReason == reason ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: _selectedReason == reason 
                  ? const Icon(Icons.check_circle, color: AppColors.accent)
                  : null,
                onTap: () => setState(() => _selectedReason = reason),
              ),
            )),

            const SizedBox(height: 24),
            Text(
              'Detalles adicionales',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textHeader),
              decoration: InputDecoration(
                hintText: 'Cuéntanos más...',
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
                  backgroundColor: AppColors.error,
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
