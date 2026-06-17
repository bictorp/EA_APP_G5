import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class SafeCircleAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final String? name;
  final IconData defaultIcon;

  const SafeCircleAvatar({
    super.key,
    required this.url,
    required this.radius,
    this.name,
    this.defaultIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white10,
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                url!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallback();
                },
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    if (name != null && name!.trim().isNotEmpty) {
      final initial = name!.trim()[0].toUpperCase();
      return Container(
        alignment: Alignment.center,
        color: Colors.white10,
        width: radius * 2,
        height: radius * 2,
        child: Text(
          initial,
          style: GoogleFonts.inter(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.w800,
            color: AppColors.textHeader,
          ),
        ),
      );
    }
    return Container(
      color: Colors.white10,
      width: radius * 2,
      height: radius * 2,
      child: Icon(
        defaultIcon,
        size: radius,
        color: AppColors.textHeader,
      ),
    );
  }
}
