import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the redesigned Music Library page and its supporting
/// desktop shell (sidebar + top header).
///
/// Deliberately a separate palette from [AppColors] rather than a change to
/// it -- the rest of the app keeps its existing indigo/gradient look, and
/// only this page adopts the flat blue SaaS look that was requested for it.
class MusicLibraryColors {
  static const Color primary = Color(0xFF1769E0);
  static const Color sidebarDark = Color(0xFF101B2D);
  static const Color background = Color(0xFFF5F8FC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF172033);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5EAF1);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color midiAccent = Color(0xFF7C3AED);

  /// A soft blue-tinted wash for the page background -- flat white/gray
  /// read as too plain once seen live, so this keeps the "predominantly
  /// white, light gray and blue" spec while giving the page some depth.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFEAF2FE), background],
  );
}

TextStyle mlText({
  double size = 14,
  FontWeight weight = FontWeight.normal,
  Color color = MusicLibraryColors.textPrimary,
  double? height,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}
