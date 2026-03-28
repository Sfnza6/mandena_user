import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  /// ThemeMode الحالي (light / dark)
  final themeMode = ThemeMode.light.obs;

  static const _key = 'theme_mode';

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString(_key);
    if (saved == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    final sp = await SharedPreferences.getInstance();
    final v = (mode == ThemeMode.dark) ? 'dark' : 'light';
    await sp.setString(_key, v);

    // تغيير الثيم مباشرة في التطبيق
    Get.changeThemeMode(mode);
  }

  /// سويتش بسيط بين لايت و دارك
  void toggleDark() {
    final isDark = themeMode.value == ThemeMode.dark;
    setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
