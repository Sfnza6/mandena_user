// lib/auth/forgot/forgot_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart'; // ✅ لإظهار Snackbar أنيق
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
// ✅ تخزين الكاش في الجهاز
import 'package:get_storage/get_storage.dart';

class ForgotController extends GetxController {
  /// عدّل حسب بيئتك (نفسه المستخدم عندك)
  /// - Windows/Web/Device:  http://127.0.0.1/iforenta_api
  /// - Android Emulator:    http://10.0.2.2/iforenta_api
  final String baseUrl = 'https://evoranta.ly';

  final sending   = false.obs;
  final verifying = false.obs;
  final resetting = false.obs;

  // =================== إضافات عرض رسائل ودّية للمستخدم ===================
  DateTime? _lastSnackAt;
  String?  _lastSnackMessage;
  static const _snackThrottle = Duration(seconds: 4);

  void _showUserError(String msg) {
    final now = DateTime.now();

    // 🔁 منع تكرار نفس الرسالة خلال فترة قصيرة
    if (_lastSnackAt != null &&
        now.difference(_lastSnackAt!) < _snackThrottle &&
        _lastSnackMessage == msg) {
      return; // نفس الرسالة وفي نفس الفترة → لا نعيدها
    }

    _lastSnackAt = now;
    _lastSnackMessage = msg;

    Get.rawSnackbar(
      borderRadius: 14,
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      backgroundColor: const Color(0xFF1F2937),
      messageText: const Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تعذّر إتمام العملية',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 6),
          ],
        ),
      ),
      // نضيف الرسالة كنص منفصل كي لا نفقد التنسيق العربي
      titleText: Directionality(
        textDirection: TextDirection.rtl,
        child: Text(
          msg,
          style: const TextStyle(
            color: Color(0xFFE5E7EB),
            fontSize: 13.5,
            height: 1.3,
          ),
        ),
      ),
      mainButton: TextButton(
        onPressed: () => Get.back(),
        child: const Text(
          'إغلاق',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      duration: const Duration(seconds: 4),
    );
  }

  String _friendlyMessage(Object e) {
    final t = e.toString().toLowerCase();

    if (t.contains('failed host lookup') ||
        t.contains('socketexception') ||
        t.contains('network is unreachable') ||
        t.contains('network_error') ||
        t.contains('no address associated with hostname') ||
        t.contains('لا يوجد اتصال')) {
      return '⚠️ لا يوجد اتصال بالإنترنت.\nتحقّق من الشبكة ثم أعد المحاولة.';
    }

    if (t.contains('timeout') ||
        t.contains('timed out') ||
        t.contains('deadline exceeded')) {
      return '⏳ انتهت مهلة الاتصال.\nحاول مجدداً بعد لحظات.';
    }

    if (t.contains('handshakeexception') ||
        t.contains('certificate') ||
        t.contains('ssl')) {
      return '🔐 مشكلة أمان مؤقتة أثناء الاتصال بالخادم.\nيرجى المحاولة لاحقاً.';
    }

    if (t.contains('formatexception') ||
        t.contains('unexpected character') ||
        t.contains('json')) {
      return '⚠️ حدث خلل في البيانات المستلمة.\nسنحاول إصلاحه، جرّب لاحقاً.';
    }

    return 'حدث خطأ غير متوقع.\nيرجى المحاولة لاحقاً.';
  }

  String _friendlyHttp(int code) {
    if (code == 401) return '🔒 يلزم تسجيل الدخول للمتابعة.';
    if (code == 403) return '⛔ الوصول مرفوض. يرجى المحاولة بحساب مصرح.';
    if (code == 404) return '🔎 لم يتم العثور على المطلوب حالياً.';
    if (code == 429) return '🚦 محاولات كثيرة خلال وقت قصير.\nانتظر قليلاً ثم أعد المحاولة.';
    if (code >= 500 && code <= 504) {
      return '🛠️ الخدمة غير متاحة مؤقتاً.\nنقوم بالصيانة أو يوجد ضغط كبير.';
    }
    return 'تعذّر التواصل مع الخادم (HTTP $code). حاول لاحقاً.';
  }

  bool _isErrorStatus(dynamic s) {
    // ندعم صيغ مختلفة: 'error' / 'fail' / false / 0
    if (s == null) return true;
    if (s is bool) return s == false;
    final str = s.toString().toLowerCase();
    return str == 'error' || str == 'fail' || str == '0' || str == 'false';
  }

  String _serverMessage(
    Map<String, dynamic> m, {
    String fallback = 'حدث خطأ، حاول لاحقاً.',
  }) {
    final cands = [
      m['message'],
      m['msg'],
      m['error'],
      m['detail'],
      m['desc'],
    ];
    for (final c in cands) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    return fallback;
  }
  // ====================================================================

  String normalizeLyPhone(String v) {
    var d = v.replaceAll(RegExp(r'\D'), '');
    if (!d.startsWith('218')) {
      if (d.startsWith('0')) d = d.substring(1);
      d = '218$d';
    }
    return d;
  }

  Map<String, dynamic> _safe(http.Response r) {
    try {
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return {'status': 'error', 'http': r.statusCode, 'raw': r.body};
    }
  }

  /// 🧠 كاش بسيط لنتائج فحص الهاتف حتى لا نكرّر نفس الطلب لنفس الرقم
  final Map<String, bool> _phoneExistsCache = {};

  // ✅ تخزين الكاش في الجهاز
  static const String _kPhoneExistsKey = 'forgot_phone_exists_v1';
  late final GetStorage _box;

  @override
  void onInit() {
    super.onInit();
    _initCache();
  }

  Future<void> _initCache() async {
    try {
      await GetStorage.init();
    } catch (_) {
      // لو كانت مهيئة من قبل نتجاهل الخطأ
    }
    _box = GetStorage();

    try {
      final raw = _box.read(_kPhoneExistsKey);
      if (raw is Map) {
        raw.forEach((key, value) {
          final k = key.toString();
          if (value is bool) {
            _phoneExistsCache[k] = value;
          } else if (value is String) {
            final v = value.toLowerCase();
            _phoneExistsCache[k] = (v == 'true' || v == '1');
          } else if (value is num) {
            _phoneExistsCache[k] = value != 0;
          }
        });
      }
    } catch (_) {
      // لو فشل قراءة الكاش → نتجاهل ببساطة
    }
  }

  void _persistPhoneExistsCache() {
    try {
      _box.write(_kPhoneExistsKey, _phoneExistsCache);
    } catch (_) {
      // تجاهل أي خطأ في التخزين
    }
  }

  /// ✅ فحص هل رقم الهاتف موجود فعلياً في قاعدة البيانات قبل إرسال OTP
  Future<bool> _phoneExistsInServer(String phone) async {
    try {
      final p = normalizeLyPhone(phone);

      // لو النتيجة موجودة في الكاش → نرجعها مباشرة
      if (_phoneExistsCache.containsKey(p)) {
        return _phoneExistsCache[p]!;
      }

      // 🔹 نفس API فحص الرقم المستخدم في التسجيل
      // عدّل المسار لو ملف check_phone_exists.php في مكان مختلف
      final uri = Uri.parse('$baseUrl/iforenta_api/check_phone_exists.php');

      final r = await http
          .post(
            uri,
            body: {'phone': p},
          )
          .timeout(const Duration(seconds: 20));

      if (r.statusCode < 200 || r.statusCode >= 300) {
        // لو في مشكلة في السيرفر → نعتبره غير موجود (لا نسمح بإرسال OTP)
        _phoneExistsCache[p] = false;
        _persistPhoneExistsCache();
        return false;
      }

      final data = _safe(r);
      final existsVal =
          data['exists'] ?? data['phone_exists'] ?? data['found'] ?? data['used'];

      bool exists;
      if (existsVal is bool) {
        exists = existsVal;
      } else {
        final exStr = existsVal?.toString().toLowerCase() ?? '';
        if (exStr == '1' || exStr == 'true' || exStr == 'yes') {
          exists = true;
        } else {
          final code = int.tryParse('${data['code'] ?? ''}');
          exists = code == 409;
        }
      }

      // نخزّن النتيجة في الكاش + التخزين الدائم
      _phoneExistsCache[p] = exists;
      _persistPhoneExistsCache();
      return exists;
    } catch (_) {
      // في حالة خطأ في الفحص، نفضّل أن نعتبر الرقم غير موجود
      return false;
    }
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    sending.value = true;
    try {
      // ✅ أولاً: تأكد أن الرقم موجود في users
      final exists = await _phoneExistsInServer(phone);
      if (!exists) {
        final msg =
            'لا يوجد حساب مسجّل بهذا الرقم.\nتأكّد من الرقم أو قم بإنشاء حساب جديد.';
        _showUserError(msg);
        // نرجع status=error حتى لا ينتقل ForgotPhoneView إلى شاشة OTP
        return {
          'status': 'error',
          'code': 'phone_not_found',
          'message': msg,
        };
      }

      // ✅ لو موجود فعلاً → أرسل OTP
      final p = normalizeLyPhone(phone);
      final r = await http.post(
        Uri.parse('$baseUrl/auth/send_otp.php'),
        body: {'phone': p, 'service_name': 'EVORANTA', 'len': '6'},
      );

      if (r.statusCode < 200 || r.statusCode >= 300) {
        final msg = _friendlyHttp(r.statusCode);
        _showUserError(msg);
        return {'status': 'error', 'code': r.statusCode, 'message': msg};
      }

      final data = _safe(r);
      if (_isErrorStatus(data['status'])) {
        final msg =
            _serverMessage(data, fallback: 'تعذّر إرسال رمز التحقق. حاول لاحقاً.');
        _showUserError(msg);
      }
      return data;
    } catch (e) {
      final msg = _friendlyMessage(e);
      _showUserError(msg);
      return {'status': 'error', 'message': msg};
    } finally {
      sending.value = false;
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    required String otpId,
  }) async {
    verifying.value = true;
    try {
      final p = normalizeLyPhone(phone);
      final r = await http.post(
        Uri.parse('$baseUrl/auth/verify_otp.php'),
        body: {'phone': p, 'code': code, 'otp_id': otpId},
      );

      if (r.statusCode < 200 || r.statusCode >= 300) {
        final msg = _friendlyHttp(r.statusCode);
        _showUserError(msg);
        return {'status': 'error', 'code': r.statusCode, 'message': msg};
      }

      final data = _safe(r);
      if (_isErrorStatus(data['status'])) {
        final fallback = 'رمز التحقق غير صحيح أو منتهي.';
        final msg = _serverMessage(data, fallback: fallback);
        _showUserError(msg);
      }
      return data;
    } catch (e) {
      final msg = _friendlyMessage(e);
      _showUserError(msg);
      return {'status': 'error', 'message': msg};
    } finally {
      verifying.value = false;
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String newPassword,
  }) async {
    resetting.value = true;
    try {
      final p = normalizeLyPhone(phone);
      final r = await http.post(
        Uri.parse('$baseUrl/auth/reset_password.php'),
        body: {'phone': p, 'new_password': newPassword},
      );

      if (r.statusCode < 200 || r.statusCode >= 300) {
        final msg = _friendlyHttp(r.statusCode);
        _showUserError(msg);
        return {'status': 'error', 'code': r.statusCode, 'message': msg};
      }

      final data = _safe(r);
      if (_isErrorStatus(data['status'])) {
        final msg =
            _serverMessage(data, fallback: 'تعذّر إعادة تعيين كلمة المرور.');
        _showUserError(msg);
      }
      return data;
    } catch (e) {
      final msg = _friendlyMessage(e);
      _showUserError(msg);
      return {'status': 'error', 'message': msg};
    } finally {
      resetting.value = false;
    }
  }
}
