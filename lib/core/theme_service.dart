// lib/core/theme_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
  static const _key = 'is_dark_mode';
  final GetStorage _box = GetStorage();

  /// يرجع الثيم الحالي (فاتح / داكن) من التخزين
  ThemeMode get theme {
    final isDark = _box.read(_key);
    if (isDark is bool && isDark == true) {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }

  /// حفظ القيمة في GetStorage
  void _saveTheme(bool isDark) {
    _box.write(_key, isDark);
  }

  /// التبديل بين الفاتح والداكن
  void switchTheme() {
    final isDark = Get.isDarkMode;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    Get.changeThemeMode(newMode);
    _saveTheme(!isDark);
  }
}
