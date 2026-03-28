import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static SharedPreferences? _prefs;

  /// استدعِها في main() بشكل مبكّر إن حبيت
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// تأكيد تهيئة SharedPreferences عند أول استخدام
  static Future<void> _ensureInit() async {
    if (_prefs == null) {
      await init();
    }
  }

  /// حفظ بيانات المستخدم بعد تسجيل الدخول
  static Future<void> saveUser({
    required int id,
    required String name,
    required String phone,
  }) async {
    await _ensureInit();
    await _prefs!.setInt('user_id', id);
    await _prefs!.setString('user_name', name);
    await _prefs!.setString('user_phone', phone);
  }

  // ==================== Getters متزامنة (قديمة) ====================

  /// الحصول على رقم المستخدم (sync) – تستخدمها لو انت أصلاً مستخدمها قبل
  static int? get userId => _prefs?.getInt('user_id');

  /// الحصول على اسم المستخدم (sync)
  static String? get userName => _prefs?.getString('user_name');

  /// التحقق إن المستخدم مسجّل دخول (sync)
  static bool get isLoggedIn => _prefs?.containsKey('user_id') ?? false;

  // ==================== دوال Async مخصّصة ====================

  /// الحصول على رقم المستخدم (async) – نستخدمها في الكنترولات
  static Future<int?> getUserId() async {
    await _ensureInit();
    return _prefs?.getInt('user_id');
  }

  /// الحصول على اسم المستخدم (async) – لو احتجتها لاحقاً
  static Future<String?> getUserName() async {
    await _ensureInit();
    return _prefs?.getString('user_name');
  }

  /// التحقق إن المستخدم مسجّل دخول (async)
  static Future<bool> getIsLoggedIn() async {
    await _ensureInit();
    return _prefs?.containsKey('user_id') ?? false;
  }

  // ==================== تسجيل الخروج ====================

  /// تسجيل خروج – يمسح فقط بيانات المستخدم
  static Future<void> logout() async {
    await _ensureInit();
    await _prefs!.remove('user_id');
    await _prefs!.remove('user_name');
    await _prefs!.remove('user_phone');
  }
}
