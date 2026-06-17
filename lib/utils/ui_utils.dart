import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/report_service.dart';
import '../controllers/theme_controller.dart';

class UIUtils {
  static void showUnfollowBottomSheet({
    required String userId,
    required String nombre,
    required VoidCallback onConfirm,
  }) {
    final themeController = Get.find<ThemeController>();
    Get.bottomSheet(
      Obx(() {
        final isDark = themeController.isDarkMode.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
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
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Text(
                'unfollow_confirm_title'.trParams({'name': nombre}),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textHeader,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'unfollow_confirm_msg'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 32),
              
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
                      side: BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                  child: Text(
                    'unfollow_btn'.tr,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'cancel'.tr,
                    style: GoogleFonts.inter(
                      color: AppColors.textHeader,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      }),
    );
  }

  static void showDeletePostBottomSheet({
    required VoidCallback onConfirm,
  }) {
    final themeController = Get.find<ThemeController>();
    Get.bottomSheet(
      Obx(() {
        final isDark = themeController.isDarkMode.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
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
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Text(
                'delete_post_confirm_title'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textHeader,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'delete_post_confirm_msg'.tr,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 32),
              
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
                      side: BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                  child: Text(
                    'delete_post'.tr,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'cancel'.tr,
                    style: GoogleFonts.inter(
                      color: AppColors.textHeader,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      }),
    );
  }

  static void showReportBottomSheet({
    required String targetId,
    required String tipo, // 'post' | 'comment' | 'user' | 'chat'
    required String title,
  }) {
    final List<Map<String, String>> reasons = [
      {'key': 'report_reason_inappropriate', 'value': 'Contenido inapropiado'},
      {'key': 'report_reason_spam_scam', 'value': 'Spam o estafa'},
      {'key': 'report_reason_harassment_bullying', 'value': 'Acoso o bullying'},
      {'key': 'report_reason_hate_speech', 'value': 'Discurso de odio'},
      {'key': 'report_reason_false_info', 'value': 'Información falsa'},
      {'key': 'report_reason_other', 'value': 'Otros'}
    ];
    final themeController = Get.find<ThemeController>();

    Get.bottomSheet(
      Obx(() {
        final isDark = themeController.isDarkMode.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
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
                    color: isDark ? Colors.white24 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'report'.tr + ' ' + title,
                style: GoogleFonts.inter(
                  color: AppColors.textHeader,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'report_reason_anonymous'.tr,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 24),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: reasons.length,
                  separatorBuilder: (context, index) => Divider(color: AppColors.border, height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        reasons[index]['key']!.tr,
                        style: GoogleFonts.inter(color: AppColors.textHeader, fontSize: 16),
                      ),
                      trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
                      onTap: () async {
                        Get.back();
                        final success = await Get.find<ReportService>().reportContent(
                          tipo: tipo,
                          objetivoId: targetId,
                          descripcion: reasons[index]['value']!,
                        );
                        
                        if (success) {
                          Get.snackbar(
                            'report_sent'.tr,
                            'report_sent_msg'.tr,
                            snackPosition: SnackPosition.TOP,
                            backgroundColor: AppColors.accent.withOpacity(0.9),
                            colorText: Colors.white,
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            'report_error_msg'.tr,
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
              SizedBox(height: 20),
            ],
          ),
        );
      }),
      isScrollControlled: true,
    );
  }
}
