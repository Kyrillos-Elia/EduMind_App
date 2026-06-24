import 'package:flutter/material.dart';

class AppPalette {
  final bool isDark;
  final Color bgTop;
  final Color bgBottom;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color primary;
  final Color primarySoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color danger;

  const AppPalette({
    required this.isDark,
    required this.bgTop,
    required this.bgBottom,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.primary,
    required this.primarySoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.danger,
  });

  factory AppPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppPalette(
      isDark: isDark,
      bgTop: isDark ? const Color(0xFF0B0F2A) : const Color(0xFFFFFFFF),
      bgBottom: isDark ? const Color(0xFF050816) : const Color(0xFFF4F7FC),
      surface: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFFFFFFF),
      surfaceAlt: isDark ? const Color(0x14FFFFFF) : const Color(0xFFF8FAFC),
      border: isDark ? const Color(0x26FFFFFF) : const Color(0xFFD8E0EC),
      primary: isDark ? const Color(0xFF4DA3FF) : const Color(0xFF2563EB),
      primarySoft: isDark ? const Color(0xFF9AA4BF) : const Color(0xFF64748B),
      textPrimary: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A),
      textSecondary: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF64748B),
      danger: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
    );
  }
}
