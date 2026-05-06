import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/report_service.dart';
import '../constants/app_colors.dart';

class ReportDialog extends StatefulWidget {
  final String tipo;
  final String objetivoId;

  const ReportDialog({super.key, required this.tipo, required this.objetivoId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
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
    return Dialog(
      backgroundColor: AppColors.containerBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reportar ${widget.tipo == 'post' ? 'Publicación' : 'Comentario'}',
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Por qué quieres reportar este contenido?',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  dropdownColor: AppColors.containerBg,
                  isExpanded: true,
                  items: _reasons.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r, style: const TextStyle(color: AppColors.textHeader)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedReason = val!),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textHeader),
              decoration: InputDecoration(
                hintText: 'Detalles adicionales (opcional)',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Reportar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
