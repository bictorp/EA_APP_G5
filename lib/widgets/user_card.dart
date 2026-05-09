import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../screens/profile_screen.dart';

class UserCard extends StatelessWidget {
  final dynamic user;
  final VoidCallback? onTap;

  const UserCard({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => ProfileScreen(
            userId: user['_id'],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.containerBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user['avatarUrl'] != null
                  ? NetworkImage(user['avatarUrl'])
                  : null,
              backgroundColor: Colors.white10,
              child: user['avatarUrl'] == null
                  ? const Icon(
                      Icons.person,
                      color: Colors.white54,
                    )
                  : null,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nombre'] ?? '',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      if (user['universidad'] != null)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textLink.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              user['universidad'] is Map
                                  ? user['universidad']['nombre'] ?? ''
                                  : '',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.textLink,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      if (user['universidad'] != null &&
                          user['grado'] != null)
                        const SizedBox(width: 8),

                      if (user['grado'] != null)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              user['grado'] is Map
                                  ? user['grado']['nombre'] ?? ''
                                  : '',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}