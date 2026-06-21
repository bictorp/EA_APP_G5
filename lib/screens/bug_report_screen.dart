import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bug_service.dart';
import '../constants/app_colors.dart';

class BugReportScreen extends StatefulWidget {
  BugReportScreen({super.key});

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
        'error'.tr,
        'bug_report_fields_required'.tr,
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
        'bug_report_success_title'.tr,
        'bug_report_success_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withOpacity(0.8),
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'bug_report_error_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textHeader),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'bug_report_title'.tr,
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
                  'bug_report_subtitle'.tr,
                  style: GoogleFonts.inter(
                    color: AppColors.textHeader,
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'bug_report_desc'.tr,
                  style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                ),
                SizedBox(height: 32),

                Text(
                  'bug_report_title_label'.tr,
                  style: GoogleFonts.inter(
                    color: AppColors.textHeader,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _tituloController,
                  style: TextStyle(color: AppColors.textHeader),
                  decoration: InputDecoration(
                    hintText: 'bug_report_title_hint'.tr,
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.containerBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                Text(
                  'bug_report_desc_label'.tr,
                  style: GoogleFonts.inter(
                    color: AppColors.textHeader,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 4,
                  style: TextStyle(color: AppColors.textHeader),
                  decoration: InputDecoration(
                    hintText: 'bug_report_desc_hint'.tr,
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.containerBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                Text(
                  'bug_report_steps_label'.tr,
                  style: GoogleFonts.inter(
                    color: AppColors.textHeader,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _repController,
                  maxLines: 3,
                  style: TextStyle(color: AppColors.textHeader),
                  decoration: InputDecoration(
                    hintText: 'bug_report_steps_hint'.tr,
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.containerBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 40),

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
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'bug_report_send'.tr,
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
        ));
  }
}
