import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeService {
  static const String storageKey = 'app_dark_mode_v1';
  final GetStorage _box = GetStorage();

  bool get isDarkMode {
    final v = _box.read(storageKey);
    return v is bool ? v : false;
  }

  ThemeMode get theme => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> saveTheme(bool isDark) async {
    await _box.write(storageKey, isDark);
  }

  Future<void> setThemeMode(bool isDark) async {
    await saveTheme(isDark);
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> switchTheme() async {
    await setThemeMode(!Get.isDarkMode);
  }
}
