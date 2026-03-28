import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  static Future<void> writeString(String key, String value) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(key, value);
    } catch (e) {
      debugPrint('SP writeString error: $e');
    }
  }

  static Future<String?> readString(String key) async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getString(key);
    } catch (e) {
      debugPrint('SP readString error: $e');
      return null;
    }
  }

  static Future<void> writeBool(String key, bool value) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(key, value);
    } catch (e) {
      debugPrint('SP writeBool error: $e');
    }
  }

  static Future<bool?> readBool(String key) async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getBool(key);
    } catch (e) {
      debugPrint('SP readBool error: $e');
      return null;
    }
  }

  static Future<void> remove(String key) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(key);
    } catch (e) {
      debugPrint('SP remove error: $e');
    }
  }
}
