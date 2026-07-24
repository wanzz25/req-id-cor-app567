import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet warna diambil langsung dari :root di public/index.html
/// biar APK & website kelihatan satu identitas yang sama.
class AppColors {
  static const purple      = Color(0xFF7C3AED); // --p
  static const purpleLight = Color(0xFFA78BFA); // --p2
  static const cyan        = Color(0xFF06B6D4); // --b
  static const bg          = Color(0xFF03050D); // --bg
  static const green       = Color(0xFF10B981); // --g
  static const cardBg      = Color(0x05FFFFFF); // rgba(255,255,255,.02)
  static const cardBorder  = Color(0x337C3AED); // rgba(124,58,237,.2)
  static const muted       = Color(0xFF475569);
  static const dim         = Color(0xFF334155);
  static const textMain    = Color(0xFFF1F5F9);
  static const amber       = Color(0xFFF59E0B); // status pending
  static const red         = Color(0xFFEF4444); // status ditolak / error
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textMain,
      displayColor: AppColors.textMain,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.purple,
        secondary: AppColors.cyan,
        surface: const Color(0xFF0A0E1A),
        error: AppColors.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
        iconTheme: const IconThemeData(color: AppColors.purpleLight),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF0D1320),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // sama kayak .card di website
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.03), // sama kayak .tk-input/.input-wrap
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // sama kayak .input-wrap input
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.purple, width: 1.4),
        ),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
        labelStyle: const TextStyle(color: AppColors.purpleLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // sama kayak .btn-submit
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          elevation: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A0E1A),
        selectedItemColor: AppColors.purpleLight,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF0D1320),
        contentTextStyle: const TextStyle(color: AppColors.textMain),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Gradient dekoratif dipakai di header/logo — nyontek .orb / .wanz-chip di web
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.purple, AppColors.cyan],
  );

  static Color statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.green;
      case 'rejected':
        return AppColors.red;
      default:
        return AppColors.amber; // pending
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Pending';
    }
  }
}
