import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/account/account_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/fcm_service.dart';

import '../../app_routes.dart';
import '../../core/api_service.dart';
import '../../core/session.dart';
import '../../data/repositories/auth_repository.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  final loading = false.obs;
  final hidePass = true.obs;

  final AuthRepository _repo = AuthRepository(ApiService());

  /// فلاغ يحدد هل المستخدم ضغط "تسجيل الدخول" أم لا
  bool _submitted = false;

  @override
  void onInit() {
    super.onInit();
    _submitted = false; // للتأكيد
  }

  void togglePass() => hidePass.value = !hidePass.value;
  void goToRegister() => Get.toNamed(AppRoutes.register);

  String? validatePhone(String? v) {
    final txt = v?.trim() ?? '';
    final digits = txt.replaceAll(RegExp(r'\D'), '');

    // قبل الضغط على "تسجيل الدخول" لا نظهر أخطاء أثناء الكتابة
    if (!_submitted) {
      // لو الحقل فاضي أو تحت الحد → لا نرجّع رسالة (عشان ما يطلع "رقم غير صحيح" من أول رقم)
      if (txt.isEmpty || digits.length < 6) {
        return null;
      }
    }

    if (txt.isEmpty) return 'أدخل رقم الهاتف';
    if (digits.length < 6) return 'رقم غير صحيح';

    return null;
  }

  String? validatePass(String? v) {
    final txt = v ?? '';

    if (!_submitted) {
      // ما نظهر رسالة "أدخل كلمة المرور" أثناء الكتابة وقبل الضغط على الزر
      if (txt.isEmpty) return null;
    }

    return txt.isEmpty ? 'أدخل كلمة المرور' : null;
  }

  // ===================== رسائل احترافية للمستخدم ======================

  DateTime? _lastSnackAt;
  String? _lastSnackMessage;
  static const _snackThrottle = Duration(seconds: 4);

  void _showUserError(String msg, {bool showRetry = false}) {
    final now = DateTime.now();

    // منع تكرار نفس الرسالة خلال مدة قصيرة
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
      messageText: const Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تعذّر تسجيل الدخول',
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
      mainButton: showRetry
          ? TextButton(
              onPressed: () {
                if (!loading.value) {
                  Get.back(); // إغلاق السناك
                  login(); // إعادة المحاولة
                }
              },
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : TextButton(
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

  /// 🆕 تفسير رسائل الباك إند (رقم غير موجود، كلمة مرور خطأ، حساب غير مفعّل...)
  String? _backendErrorMessage(String raw) {
    final lower = raw.toLowerCase().trim();

    // الرسالة التي ذكرتها "رد غير صحيح"
    if (lower.contains('رد غير صحيح')) {
      return 'بيانات الدخول غير صحيحة.\nتحقّق من رقم الهاتف وكلمة المرور.';
    }

    if (lower.contains('wrong_password') ||
        lower.contains('invalid_password') ||
        lower.contains('password_incorrect') ||
        lower.contains('كلمة المرور غير صحيحة')) {
      return 'كلمة المرور غير صحيحة.\nتأكد من كتابتها بشكل صحيح.';
    }

    if (lower.contains('user_not_found') ||
        lower.contains('no_user') ||
        lower.contains('not registered') ||
        lower.contains('رقم غير مسجل') ||
        lower.contains('phone_not_found')) {
      return 'لا يوجد حساب مرتبط بهذا الرقم.\nتأكد من رقم الهاتف أو قم بإنشاء حساب جديد.';
    }

    if (lower.contains('invalid_phone') ||
        lower.contains('phone_invalid') ||
        lower.contains('phone_format')) {
      return 'رقم الهاتف غير صحيح.\nتأكد من إدخال الرقم مع المفتاح بالشكل الصحيح.';
    }

    if (lower.contains('inactive') ||
        lower.contains('not_active') ||
        lower.contains('disabled') ||
        lower.contains('غير مفع')) {
      return 'الحساب غير مفعّل حاليًا.\nتواصل مع إدارة المطعم لتفعيل حسابك.';
    }

    if (lower.contains('banned') ||
        lower.contains('blocked') ||
        lower.contains('is_banned') ||
        lower.contains('تم تقييد')) {
      return 'تم تقييد حسابك.\nلا يمكنك تسجيل الدخول حالياً.';
    }

    // لو ما عرفناش نوع الخطأ نرجّع null علشان نرجع للمعالجات العامة
    return null;
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

    if (t.contains('invalid') &&
        (t.contains('credential') ||
            t.contains('password') ||
            t.contains('login'))) {
      return 'بيانات الدخول غير صحيحة.\nتحقّق من رقم الهاتف وكلمة المرور.';
    }

    return 'حدث خطأ غير متوقع.\nيرجى المحاولة لاحقاً.';
  }

  String _friendlyHttp(int code) {
    if (code == 401 || code == 403) {
      return 'بيانات الدخول غير صحيحة أو غير مصرح.\nتحقّق من رقم الهاتف وكلمة المرور.';
    }

    if (code == 404) return 'الخدمة غير متاحة حالياً. حاول لاحقاً.';

    if (code == 429) {
      return '🚦 محاولات كثيرة خلال وقت قصير.\nانتظر قليلاً ثم أعد المحاولة.';
    }

    if (code >= 500 && code <= 504) {
      return '🛠️ الخدمة غير متاحة مؤقتاً.\nنقوم بالصيانة أو يوجد ضغط كبير.';
    }

    return 'تعذّر التواصل مع الخادم (HTTP $code). حاول لاحقاً.';
  }

  // ======================================================================

  Future<void> login() async {
    // نعلِم الفالديتور أن المستخدم ضغط على "تسجيل الدخول"
    _submitted = true;

    if (!(formKey.currentState?.validate() ?? false)) return;

    loading.value = true;

    try {
      final phone = phoneCtrl.text.trim();
      final password = passCtrl.text;

      // 1) امسح أي جلسة وذاكرة قديمة قبل عملية تسجيل الدخول
      await Session.clear();
      if (Get.isRegistered<AccountController>()) {
        Get.delete<AccountController>(force: true);
      }

      // 2) ✅ التحقق أولاً هل رقم الهاتف مسجّل أصلاً أم لا
      // لو غير موجود → نوضّح للمستخدم أنه لا يوجد حساب بهذا الرقم
      final bool exists = await _repo.checkPhoneExists(phone);
      if (!exists) {
        _showUserError(
          'لا يوجد حساب مرتبط بهذا الرقم.\nتأكد من رقم الهاتف أو قم بإنشاء حساب جديد.',
          showRetry: false,
        );
        loading.value = false;
        return;
      }

      // 3) نفّذ تسجيل الدخول على السيرفر
      final user = await _repo.login(phone: phone, password: password);

      // ===== فحص حالة التقييد من البيانات القادمة من الـ API =====
      final json = user.toJson();
      final rawBan =
          json['is_banned'] ?? json['banned'] ?? json['blocked'] ?? 0;
      final banStr = (rawBan is bool)
          ? (rawBan ? '1' : '0')
          : rawBan.toString().toLowerCase().trim();
      final isBlocked = (banStr == '1' || banStr == 'true');

      if (isBlocked) {
        await Session.clear();
        final reason = (json['banned_reason'] ?? json['ban_reason'] ?? '')
            .toString();
        Get.offAllNamed(AppRoutes.banned, arguments: {'reason': reason});
        return;
      }

      // 4) خزّن الجلسة الجديدة محليًا
      await Session.saveLoggedIn(user: json);

      // 5) خزّن user_id في SharedPreferences (مهم لسجل البحث لكل مستخدم)
      try {
        final prefs = await SharedPreferences.getInstance();
        final dynamic rawId = json['id'] ?? json['user_id'];
        final int userId = (rawId is int)
            ? rawId
            : int.tryParse(rawId?.toString() ?? '0') ?? 0;
        await prefs.setInt('user_id', userId);
      } catch (_) {
        // لو صار خطأ بسيط في التخزين نتجاهله، مش ضروري يوقف الدخول
      }

      // 6) حدّث AccountController / السلة / المفضلة بالجلسة الجديدة قبل الذهاب للهوم
      try {
        final acc = Get.isRegistered<AccountController>()
            ? Get.find<AccountController>()
            : Get.put(AccountController(), permanent: true);
        await acc.applyCurrentSession();
      } catch (_) {
        // لو ما لقيش الكنترولر أو صار خطأ بسيط نطنّشه
      }

      // 7) انتقل للصفحة الرئيسية
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      final txt = e.toString();
      final lower = txt.toLowerCase();

      // 🆕 أولاً: لو الخطأ من نوع "مقيّد"
      if (lower.contains('banned') ||
          lower.contains('blocked') ||
          lower.contains('is_banned') ||
          lower.contains('تم تقييد')) {
        await Session.clear();
        Get.offAllNamed(AppRoutes.banned, arguments: {'reason': txt});
        loading.value = false;
        return;
      }

      // 🆕 ثانياً: نحاول نفهم رسالة الباك إند بالتحديد (كلمة مرور / رقم / مستخدم غير موجود...)
      final backendMsg = _backendErrorMessage(txt);
      if (backendMsg != null) {
        _showUserError(backendMsg, showRetry: false);
        loading.value = false;
        return;
      }

      // ثالثاً: يمكن يكون مكتوب فيه كود HTTP داخل الرسالة
      final httpCodeMatch = RegExp(r'HTTP\s*([0-9]{3})').firstMatch(txt);
      if (httpCodeMatch != null) {
        final code = int.tryParse(httpCodeMatch.group(1) ?? '');
        final msg = _friendlyHttp(code ?? 0);
        _showUserError(msg, showRetry: true);
      } else {
        final msg = _friendlyMessage(e);
        final isCredErr =
            lower.contains('invalid') ||
            lower.contains('credential') ||
            lower.contains('password') ||
            lower.contains('unauthorized') ||
            lower.contains('401') ||
            lower.contains('403');

        _showUserError(
          isCredErr
              ? 'بيانات الدخول غير صحيحة.\nتحقّق من رقم الهاتف وكلمة المرور.'
              : msg,
          showRetry: true,
        );
      }
    } finally {
      loading.value = false;
    }
    await FcmService.initForLoggedInUser();
  }

  // 🆕 الدخول كـ حساب تجريبي (تصفح فقط – بدون اتصال بقاعدة البيانات)
  Future<void> loginAsGuest() async {
    if (loading.value) return;
    loading.value = true;

    try {
      // مسح أي جلسة قديمة (مستخدم حقيقي)
      await Session.clear();
      if (Get.isRegistered<AccountController>()) {
        Get.delete<AccountController>(force: true);
      }

      // تمييزه كـ حساب تجريبي في SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_guest', true);
        await prefs.setBool('is_demo_user', true); // 🆕
        await prefs.setInt('user_id', 0);
      } catch (_) {}

      // حفظ جلسة خفيفة في Session (مع علامة is_demo + is_guest)
      await Session.saveLoggedIn(
        user: {
          'id': 0,
          'user_id': 0,
          'name': 'حساب تجريبي', // 🆕 بدل "زائر"
          'phone': '',
          'is_guest': true,
          'is_demo': true, // 🆕 فلاغ واضح للحساب التجريبي
        },
      );

      // إنعاش AccountController بالجلسة الجديدة (التجريبية)
      try {
        final acc = Get.isRegistered<AccountController>()
            ? Get.find<AccountController>()
            : Get.put(AccountController(), permanent: true);
        await acc.applyCurrentSession();
      } catch (_) {}

      // رسالة بسيطة للمستخدم
      Get.snackbar(
        'حساب تجريبي',
        'يمكنك الآن تصفح الأصناف فقط.\nلا يمكنك إضافة للسلة أو تنفيذ طلبات حتى تسجّل الدخول بحساب حقيقي.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      // الذهاب للهوم
      Get.offAllNamed(AppRoutes.home, arguments: {'guest': true});
    } catch (_) {
      _showUserError(
        'لم نتمكن من إدخالك كحساب تجريبي.\nحاول مرة أخرى.',
        showRetry: false,
      );
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    // تقدر ترجع تفعّل الـ dispose لو حاب
    // phoneCtrl.dispose();
    // passCtrl.dispose();
    super.onClose();
  }
}
