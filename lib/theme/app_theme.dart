import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class AppTheme {
  /// 🎨 ثيم فاتح
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.light,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: colorScheme,
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.textMain,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textMain,
        ),
        iconTheme: IconThemeData(color: AppColors.textMain, size: 22),
      ),

      // 👇 لون الأيقونات في الوضع الفاتح
      iconTheme: IconThemeData(color: AppColors.textMain, size: 22),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: IconThemeData(color: AppColors.brand),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  /// 🌙 ثيم داكن – الأيقونات كلها باللون البني 0xFF6F3F17
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: Brightness.dark,
    );

    const Color darkBg = Color(0xFF050608);
    const Color darkSurface = Color(0xFF111319);

    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: colorScheme,

      textTheme: GoogleFonts.cairoTextTheme(
        base.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(
          color: AppColors.brand, // 👈 كل أيقونات الـ AppBar بني
          size: 22,
        ),
      ),

      // 👇 الأيقونات العامة في الوضع الليلي – بني
      iconTheme: IconThemeData(color: AppColors.brand, size: 22),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: IconThemeData(color: AppColors.brand),
        unselectedIconTheme: const IconThemeData(color: Colors.grey),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: darkSurface,
      ),

      cardColor: darkSurface,
      dialogTheme: DialogThemeData(backgroundColor: darkSurface),
    );
  }
}
