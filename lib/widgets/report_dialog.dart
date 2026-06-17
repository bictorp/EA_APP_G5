import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/report_service.dart';
import '../constants/app_colors.dart';

class ReportDialog extends StatefulWidget {
  final String tipo;
  final String objetivoId;

  ReportDialog({super.key, required this.tipo, required this.objetivoId});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  final List<String> _reasons = [
    'spam',
    'inappropriate_content',
    'harassment',
    'false_info',
    'hate_speech',
    'other'
  ];

  String _selectedReason = 'spam';

  Future<void> _submit() async {
    setState(() => _isSending = true);
    
    final desc = '${_selectedReason.tr}: ${_controller.text.trim()}';
    final success = await _reportService.reportContent(
      tipo: widget.tipo,
      objetivoId: widget.objetivoId,
      descripcion: desc,
    );

    setState(() => _isSending = false);

    if (success) {
      Get.back();
      Get.snackbar(
        'report_sent'.tr,
        'report_sent_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'report_error_msg'.tr,
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
        side: BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tipo == 'post' ? 'report_title_post'.tr : 'report_title_comment'.tr,
              style: GoogleFonts.inter(
                color: AppColors.textHeader,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'report_reason_q'.tr,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            SizedBox(height: 12),
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
                    child: Text(r.tr, style: TextStyle(color: AppColors.textHeader)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedReason = val!),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              style: TextStyle(color: AppColors.textHeader),
              decoration: InputDecoration(
                hintText: 'additional_details'.tr,
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.bg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('cancel'.tr, style: TextStyle(color: AppColors.textMuted)),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSending ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSending 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('report'.tr, style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
