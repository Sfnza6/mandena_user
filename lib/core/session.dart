import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mandena/home/home_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

// لإدارة الكنترولرات ومسحها عند تسجيل الخروج
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../modules/cart/cart_controller.dart';

import '../modules/account/account_controller.dart';

class Session {
  static SharedPreferences? _sp;
  static const _kUser = 'sess_user';

  /// لازم تنادى في main() قبل runApp
  static Future<void> init() async {
    _sp ??= await SharedPreferences.getInstance();
  }

  /// حفظ الجلسة (يمسح القديم، ويوحّد المفاتيح المهمة)
  static Future<void> saveLoggedIn({required Map<String, dynamic> user}) async {
    await init();

    // ⚠ إيقاف وضع التجريبي عند تسجيل دخول حقيقي
    await clearDemoFlag();

    await _sp!.remove(_kUser);

    final u = Map<String, dynamic>.from(user);

    final id = int.tryParse('${u['id'] ?? u['user_id'] ?? ''}');
    if (id != null) {
      u['id'] = id;
    } else {
      u.remove('id');
    }

    final phone = (u['phone'] ?? '').toString();
    if (phone.isNotEmpty) {
      u['phone'] = phone;
    } else {
      u.remove('phone');
    }

    await _sp!.setString(_kUser, jsonEncode(u));
  }

  /// قراءة الجلسة كـ Map
  static Future<Map<String, dynamic>?> readLoggedIn() async {
    await init();
    final s = _sp!.getString(_kUser);
    if (s == null || s.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(s));
    } catch (_) {
      return null;
    }
  }

  /// التحقق من تسجيل الدخول (بدون توكن)
  static Future<bool> hasLoggedIn() async {
    final u = await readLoggedIn();
    if (u == null) return false;

    final id = int.tryParse('${u['id'] ?? u['user_id'] ?? ''}');
    final phone = (u['phone'] ?? '').toString();

    // لو تجريبي → يعتبر Logged In
    if (await isDemo()) return true;

    return (id != null && id > 0) || phone.isNotEmpty;
  }

  /// ملخصات مريحة
  static Future<int?> userId() async {
    final u = await readLoggedIn();
    if (u == null) return null;

    // لو حساب تجريبي → userId = 0
    if (await isDemo()) return 0;

    return int.tryParse('${u['id'] ?? u['user_id'] ?? ''}');
  }

  static Future<String?> userPhone() async {
    final u = await readLoggedIn();
    if (u == null) return null;

    final p = (u['phone'] ?? '').toString();
    return p.isEmpty ? null : p;
  }

  static Future<void> setField(String key, dynamic value) async {
    await init();
    final u = await readLoggedIn() ?? {};
    if (value == null) {
      u.remove(key);
    } else {
      u[key] = value;
    }
    await _sp!.setString(_kUser, jsonEncode(u));
  }

  /// 🔴 خروج كامل
  static Future<void> clear() async {
    await init();

    try {
      if (Get.isRegistered<CartController>()) {
        final cart = Get.find<CartController>();
        try {
          cart.clear();
        } catch (_) {}
      }

      if (Get.isRegistered<HomeController>()) {
        Get.delete<HomeController>(force: true);
      }

      if (Get.isRegistered<AccountController>()) {
        Get.delete<AccountController>(force: true);
      }
    } catch (_) {}

    await _sp!.remove(_kUser);
    await _sp!.remove('hasDefaultAddress');

    try {
      await _sp!.clear();
    } catch (_) {}

    try {
      await GetStorage.init();
      final box = GetStorage();
      await box.erase();
    } catch (_) {}
  }

  static Future<void> debugDump() async {
    final u = await readLoggedIn();
    if (kDebugMode) {
      debugPrint('SESSION DEBUG -> $u');
    }
  }

  // ========= وجود عنوان افتراضي =========
  static Future<void> setHasDefaultAddress(bool v) async {
    await init();
    await _sp!.setBool('hasDefaultAddress', v);
  }

  static Future<bool> hasDefaultAddress() async {
    await init();
    return _sp!.getBool('hasDefaultAddress') ?? false;
  }

  // ===============================================================
  // 🆕 دعم الحساب التجريبي Demo
  // ===============================================================

  static const _kDemoKey = 'is_demo_user';

  /// هل هو حساب تجريبي؟
  static Future<bool> isDemo() async {
    await init();
    return _sp!.getBool(_kDemoKey) ?? false;
  }

  /// تسجيل الدخول كحساب تجريبي
  static Future<void> saveDemoUser() async {
    await init();

    await _sp!.setBool(_kDemoKey, true);

    await _sp!.setString(
      _kUser,
      jsonEncode({'id': 0, 'phone': '', 'name': 'حساب تجريبي'}),
    );

    await _sp!.setBool('logged_in', true);
  }

  /// إزالة وضع التجريبي عند تسجيل دخول حقيقي
  static Future<void> clearDemoFlag() async {
    await init();
    await _sp!.setBool(_kDemoKey, false);
  }
}
