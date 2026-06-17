import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../screens/profile_screen.dart';
import '../widgets/safe_circle_avatar.dart';

class UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback? onTap;

  UserCard({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.to(() => ProfileScreen(userId: user['_id'] ?? user['id']), preventDuplicates: false),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.containerBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderWhite),
        ),
        child: Row(
          children: [
            // Avatar con fallback
            SafeCircleAvatar(
              radius: 28,
              url: user['avatarUrl'],
              name: user['nombre'],
            ),

            SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nombre'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textHeader,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Usamos Wrap en lugar de Row para evitar overflows masivos
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (user['universidad'] != null && user['universidad'] is Map)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textLink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user['universidad']['nombre'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.textLink,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                      if (user['grado'] != null && user['grado'] is Map)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.borderWhite,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user['grado']['nombre'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}