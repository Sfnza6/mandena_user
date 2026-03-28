import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/account/account_controller.dart';
import '../../core/fcm_service.dart';

import '../../../core/api_service.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/session.dart';
import '../../../app_routes.dart';

// ✅ إضافات OTP
import '../otp/otp_controller.dart';
import '../otp/otp_verification_view.dart';

// ✅ إضافة: SharedPreferences و AccountController مثل اللوجين
import 'package:shared_preferences/shared_preferences.dart';

class RegisterController extends GetxController {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final pass2Ctrl = TextEditingController();
  final loading = false.obs;

  // 👁‍🗨 إظهار/إخفاء كلمة المرور + التأكيد
  final hidePass = true.obs;
  final hidePass2 = true.obs;

  void togglePass() => hidePass.value = !hidePass.value;
  void togglePass2() => hidePass2.value = !hidePass2.value;

  late final AuthRepository _repo;
  late final OtpController otp; // كنترولر OTP

  // ===================== رسائل ودّية + Snackbar أنيق ======================
  DateTime? _lastSnackAt;
  String? _lastSnackMessage;
  static const _snackThrottle = Duration(seconds: 4);

  void _showUserError(
    String msg, {
    String title = 'تعذّر إتمام العملية',
    VoidCallback? onRetry,
  }) {
    final now = DateTime.now();

    // 🔁 منع تكرار نفس الرسالة خلال فترة قصيرة
    if (_lastSnackAt != null &&
        now.difference(_lastSnackAt!) < _snackThrottle &&
        _lastSnackMessage == msg) {
      return;
    }
    _lastSnackAt = now;
    _lastSnackMessage = msg;

    Get.rawSnackbar(
      borderRadius: 14,
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      backgroundColor: const Color(0xFF1F2937),
      messageText: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              msg,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 13.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          if (onRetry != null) onRetry();
        },
        child: Text(
          onRetry != null ? 'إعادة المحاولة' : 'إغلاق',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccess(String msg, {String title = 'تم'}) {
    Get.rawSnackbar(
      borderRadius: 14,
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      backgroundColor: const Color(0xFF065F46), // أخضر أنيق
      messageText: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              msg,
              style: const TextStyle(
                color: Color(0xFFE7F5EF),
                fontSize: 13.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      duration: const Duration(seconds: 3),
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
    // احتمالية وجود رسالة تفيد بأن الرقم مستخدم
    if (t.contains('phone_exists') ||
        t.contains('duplicate') ||
        t.contains('exists')) {
      return 'رقم الهاتف مستخدم من قبل.';
    }
    return 'حدث خطأ غير متوقع.\nيرجى المحاولة لاحقاً.';
  }

  String _friendlyHttp(int code) {
    if (code == 400) return 'البيانات غير مكتملة أو غير صالحة.';
    if (code == 401 || code == 403) {
      return '⛔ غير مصرح. تحقق من البيانات ثم حاول مجدداً.';
    }
    if (code == 404) return 'الخدمة غير متاحة حالياً.';
    if (code == 409) return 'رقم الهاتف مستخدم من قبل.';
    if (code == 429) {
      return '🚦 محاولات كثيرة خلال وقت قصير. انتظر قليلاً ثم أعد المحاولة.';
    }
    if (code >= 500 && code <= 504) {
      return '🛠️ الخدمة غير متاحة مؤقتاً. نقوم بالصيانة أو يوجد ضغط كبير.';
    }
    return 'تعذّر التواصل مع الخادم (HTTP $code). حاول لاحقاً.';
  }

  // ignore: unused_element
  bool _isErrorStatus(dynamic s) {
    if (s == null) return true;
    if (s is bool) return s == false;
    final str = s.toString().toLowerCase();
    return str == 'error' || str == 'fail' || str == '0' || str == 'false';
  }

  // ignore: unused_element
  String _serverMessage(
    Map<String, dynamic> m, {
    String fallback = 'حدث خطأ، حاول لاحقاً.',
  }) {
    final cands = [m['message'], m['msg'], m['error'], m['detail'], m['desc']];
    for (final c in cands) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    return fallback;
  }
  // ======================================================================

  @override
  void onInit() {
    super.onInit();
    _repo = AuthRepository(ApiService());
    otp = Get.put(OtpController(), permanent: false);
  }

  /// 🧠 كاش بسيط لنتائج فحص الهاتف حتى لا نكرّر نفس الطلب لنفس الرقم
  final Map<String, bool> _phoneExistsCache = {};

  /// 🔍 فحص هل رقم الهاتف مسجّل مسبقاً قبل إرسال OTP
  Future<bool> _phoneAlreadyRegistered(String phone) async {
    try {
      final key = phone.trim();

      // لو النتيجة موجودة في الكاش → نرجعها مباشرة
      if (_phoneExistsCache.containsKey(key)) {
        return _phoneExistsCache[key]!;
      }

      final api = ApiService();
      // ✳️ عدّل اسم الملف/المسار حسب ما عندك في الـ PHP
      final res = await api.post(
        'check_phone_exists.php',
        body: {'phone': phone},
      );

      bool exists = false;

      if (res is Map) {
        // نحاول قراءة أكثر من شكل متوقّع
        final existsVal =
            res['exists'] ?? res['phone_exists'] ?? res['found'] ?? res['used'];

        if (existsVal is bool) {
          exists = existsVal;
        } else {
          final exStr = existsVal?.toString().toLowerCase() ?? '';
          if (exStr == '1' || exStr == 'true' || exStr == 'yes') {
            exists = true;
          } else {
            // أحياناً السيرفر يرجع كود 409 داخل JSON
            final code = int.tryParse('${res['code'] ?? ''}');
            if (code == 409) exists = true;
          }
        }
      }

      // نخزّن النتيجة في الكاش
      _phoneExistsCache[key] = exists;
      return exists;
    } catch (_) {
      // لو فشل الفحص، نرجّع false حتى لا نمنع التسجيل بلا سبب
      return false;
    }
  }

  /// تسجيل فعلي في السيرفر بعد نجاح OTP
  Future<void> _registerAfterOtp({
    required String name,
    required String phone,
    required String pass,
  }) async {
    loading.value = true;
    try {
      // بعض السيرفرات ترجع {"status":"success"} فقط بدون user
      // والريبو قد يرمي استثناء REGISTER_SUCCESS_NO_USER.
      final user = await _repo.register(
        username: name,
        phone: phone,
        password: pass,
      );

      final json = user.toJson();

      // حفظ الجلسة
      await Session.saveLoggedIn(user: json);
      await FcmService.initForLoggedInUser();

      // حفظ user_id في SharedPreferences مثل اللوجين
      try {
        final prefs = await SharedPreferences.getInstance();
        final dynamic rawId = json['id'] ?? json['user_id'];
        final int userId = (rawId is int)
            ? rawId
            : int.tryParse(rawId?.toString() ?? '0') ?? 0;
        await prefs.setInt('user_id', userId);
      } catch (_) {}

      // تحديث AccountController بالجلسة الجديدة
      try {
        final acc = Get.isRegistered<AccountController>()
            ? Get.find<AccountController>()
            : Get.put(AccountController(), permanent: true);
        await acc.applyCurrentSession();
      } catch (_) {}

      _showSuccess('تم إنشاء الحساب بنجاح');

      // 👉 الانتقال مباشرة إلى الهوم
      Get.offAllNamed(AppRoutes.home);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<RegisterController>()) {
          Get.delete<RegisterController>(force: true);
        }
      });
      return;
    } catch (e) {
      final msg = e.toString();

      // ✅ اعتبره نجاحًا لو كانت الاستجابة success بدون user
      if (msg.contains('REGISTER_SUCCESS_NO_USER') ||
          msg.contains('"status":"success"') ||
          msg.contains('status: success') ||
          msg.contains('success')) {
        // هنا ما عندنا بيانات user نحفظها، لذلك نكتفي بالذهاب إلى اللوجين
        _showSuccess('تم إنشاء الحساب بنجاح. يمكنك الآن تسجيل الدخول.');
        Get.offAllNamed(AppRoutes.login);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.isRegistered<RegisterController>()) {
            Get.delete<RegisterController>(force: true);
          }
        });
        return;
      }

      if (msg.toLowerCase().contains('phone_exists') ||
          msg.toLowerCase().contains('duplicate') ||
          msg.toLowerCase().contains('exists')) {
        _showUserError('رقم الهاتف مستخدم من قبل.');
      } else {
        _showUserError(_friendlyMessage(e));
      }
    } finally {
      loading.value = false;
    }
  }

  /// ✅ التدفق: أخذ القيم → فحص رقم الهاتف → إرسال OTP → تحقق → تسجيل مستخدم → انتقال للّوجين/الهوم
  Future<void> registerWithOtp() async {
    // 1) خُذ القيم الآن (لن نقرأ الكنترولرات بعد الإغلاق)
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final pass2 = pass2Ctrl.text.trim();

    // 2) تحقق حقول
    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      _showUserError('أدخل كل الحقول', title: 'تنبيه');
      return;
    }
    if (pass != pass2) {
      _showUserError('تأكيد كلمة المرور غير متطابق', title: 'تنبيه');
      return;
    }

    loading.value = true;
    try {
      // 3) فحص هل الرقم مسجّل مسبقاً؟
      final exists = await _phoneAlreadyRegistered(phone);
      if (exists) {
        _showUserError(
          'رقم الهاتف مسجّل مسبقاً، استخدم تسجيل الدخول.',
          title: 'تنبيه',
        );
        return; // 🚫 لا OTP ولا انتقال
      }

      // 4) إرسال OTP (فعلي — بدون test)
      final r = await otp.sendOtp(phone: phone);
      final status = (r['status'] ?? '').toString().toLowerCase();
      if (status != 'ok' && status != 'success') {
        _showUserError(
          (r['message'] ?? 'تعذّر إرسال رمز التحقق').toString(),
          title: 'خطأ',
          onRetry: () => registerWithOtp(),
        );
        return;
      }

      final String otpId = (r['otp_id'] ?? '').toString();

      // 5) شاشة التحقق: عند النجاح نسجّل بالقيم المأخوذة
      Get.to(
        () => OtpVerificationView(
          phone: phone,
          otpId: otpId,
          onVerified: () async {
            await _registerAfterOtp(name: name, phone: phone, pass: pass);
          },
        ),
      );
    } finally {
      loading.value = false;
    }
    await FcmService.initForLoggedInUser();
  }

  /// (بديل لو حبيت تسجيل مباشر بلا OTP)
  Future<void> register() async {
    final name = nameCtrl.text.trim();
    final phone = phoneCtrl.text.trim();
    final pass = passCtrl.text.trim();
    final pass2 = pass2Ctrl.text.trim();

    if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
      _showUserError('أدخل كل الحقول', title: 'تنبيه');
      return;
    }
    if (pass != pass2) {
      _showUserError('تأكيد كلمة المرور غير متطابق', title: 'تنبيه');
      return;
    }

    loading.value = true;
    try {
      final user = await _repo.register(
        username: name,
        phone: phone,
        password: pass,
      );

      final json = user.toJson();

      await Session.saveLoggedIn(user: json);
      _showSuccess('تم إنشاء الحساب بنجاح');

      // حفظ user_id في SharedPreferences مثل اللوجين
      try {
        final prefs = await SharedPreferences.getInstance();
        final dynamic rawId = json['id'] ?? json['user_id'];
        final int userId = (rawId is int)
            ? rawId
            : int.tryParse(rawId?.toString() ?? '0') ?? 0;
        await prefs.setInt('user_id', userId);
      } catch (_) {}

      // تحديث AccountController بالجلسة الجديدة
      try {
        final acc = Get.isRegistered<AccountController>()
            ? Get.find<AccountController>()
            : Get.put(AccountController(), permanent: true);
        await acc.applyCurrentSession();
      } catch (_) {}

      // 👉 الانتقال مباشرة إلى الهوم
      Get.offAllNamed(AppRoutes.home);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<RegisterController>()) {
          Get.delete<RegisterController>(force: true);
        }
      });
    } catch (e) {
      final txt = e.toString();

      // نجاح بدون user
      if (txt.contains('REGISTER_SUCCESS_NO_USER') ||
          txt.contains('"status":"success"') ||
          txt.contains('status: success') ||
          txt.contains('success')) {
        _showSuccess('تم إنشاء الحساب بنجاح. يمكنك الآن تسجيل الدخول.');
        Get.offAllNamed(AppRoutes.login);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.isRegistered<RegisterController>()) {
            Get.delete<RegisterController>(force: true);
          }
        });
      } else if (txt.toLowerCase().contains('phone_exists') ||
          txt.toLowerCase().contains('duplicate') ||
          txt.toLowerCase().contains('exists')) {
        _showUserError('رقم الهاتف مستخدم من قبل.', title: 'تنبيه');
      } else {
        // لو احتوى على كود HTTP داخل رسالة الاستثناء
        final codeMatch = RegExp(r'HTTP\s*([0-9]{3})').firstMatch(txt);
        if (codeMatch != null) {
          final code = int.tryParse(codeMatch.group(1) ?? '');
          _showUserError(_friendlyHttp(code ?? 0));
        } else {
          _showUserError(_friendlyMessage(e));
        }
      }
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    // ⚠️ لا تتخلّص من الكنترولات هنا لتجنّب use-after-dispose أثناء الانتقالات
    // nameCtrl.dispose();
    // phoneCtrl.dispose();
    // passCtrl.dispose();
    // pass2Ctrl.dispose();
    super.onClose();
  }
}
