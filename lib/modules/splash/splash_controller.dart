import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/app_routes.dart';
import 'package:mandena/auth/login/login_view.dart';
import 'package:mandena/core/api_service.dart';
import 'package:mandena/core/env.dart';
import 'package:mandena/core/session.dart';

/// نتيجة فحص التقييد
class _BanResult {
  final bool banned;
  final String reason;
  const _BanResult(this.banned, this.reason);
}

class SplashController extends GetxController {
  /// مدة عرض الشعار قبل الانتقال
  static const _splashDelay = Duration(milliseconds: 1800);

  final _api = ApiService();

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    // نضمن تهيئة الـ SharedPreferences
    await Session.init();

    // نترك أنيميشن الشعار يشتغل
    await Future.delayed(_splashDelay);

    try {
      final uid = await Session.userId();

      if (uid != null && uid > 0) {
        // ✅ عندي جلسة → نفحص هل المستخدم مقيّد من get_user.php
        final ban = await _checkBanStatus(uid);

        if (ban.banned) {
          // حساب مقيّد → نمسح الجلسة ونذهب لواجهة التقييد
          await Session.clear();

          Get.offAllNamed(AppRoutes.banned);
          return;
        }

        // ✅ مستخدم موجود وغير مقيّد → انتقل للهوم
        Get.offAllNamed(AppRoutes.home);
      } else {
        // ✅ لا توجد جلسة → انتقل لتسجيل الدخول
        Get.offAll(
          () => const LoginView(),
          // transition: Transition.downToUp,
          // duration: const Duration(milliseconds: 500),
          // curve: Curves.easeInOutCubic,
        );
      }
    } on TimeoutException {
      // ✅ في حال بطء أو فشل أثناء التحقق من الجلسة
      Get.snackbar(
        'انتهت المهلة',
        'الاتصال استغرق وقتًا طويلاً، حاول مجددًا بعد قليل.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(
        () => const LoginView(),
        transition: Transition.downToUp,
        duration: const Duration(milliseconds: 2100),
        curve: Curves.easeInOutCubic,
      );
    } on Exception catch (e) {
      // ✅ أي خطأ آخر → نعرض رسالة ودّية بدل التقنية
      Get.snackbar(
        'حدث خطأ',
        'تعذّر تحميل البيانات: ${_friendlyError(e)}',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(
        () => const LoginView(),
        transition: Transition.downToUp,
        duration: const Duration(milliseconds: 2100),
        curve: Curves.easeInOutCubic,
      );
    } catch (e) {
      // ✅ fallback عام لأي استثناء غير متوقّع
      Get.snackbar(
        'تنبيه',
        'حدث خطأ غير متوقّع أثناء التهيئة. سيتم تحويلك لصفحة تسجيل الدخول.',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.offAll(
        () => const LoginView(),
        transition: Transition.downToUp,
        duration: const Duration(milliseconds: 2100),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// دالة ترجمة الأخطاء إلى نصوص ودّية
  String _friendlyError(Object e) {
    final t = e.toString().toLowerCase();
    if (t.contains('socket') || t.contains('network')) {
      return 'تحقق من اتصال الإنترنت.';
    }
    if (t.contains('timeout')) {
      return 'انتهت مهلة الاتصال.';
    }
    if (t.contains('format')) {
      return 'استجابة غير متوقعة من الخادم.';
    }
    return 'حاول مجددًا لاحقًا.';
  }

  /// 🔍 فحص التقييد من نفس API المستخدم في أماكن أخرى: get_user.php
  Future<_BanResult> _checkBanStatus(int userId) async {
    try {
      final res = await _api.get(
        Env.userById, // هذا هو get_user.php اللي شغال عندك
        params: {
          'id': userId.toString(),
          // phone اختياري، مثل ما يبعثه AccountController
          // لو حابب تضيفه من السيشن:
          // 'phone': (await Session.phone()) ?? '',
        },
      );

      final obj = (res is String) ? jsonDecode(res) : res;

      if (obj is! Map) return const _BanResult(false, '');

      // ممكن يرجع بصيغ مختلفة:
      // { status:'success', user:{...} }
      // { status:'success', data:{...} }
      // أو { ...حقول مباشرة... }
      Map<String, dynamic>? data;
      if (obj['user'] is Map) {
        data = Map<String, dynamic>.from(obj['user']);
      } else if (obj['data'] is Map) {
        data = Map<String, dynamic>.from(obj['data']);
      } else if (obj['id'] != null && obj['phone'] != null) {
        data = Map<String, dynamic>.from(obj);
      }

      if (data == null) return const _BanResult(false, '');

      // الحقل الموجود في get_user.php حسب اللوج:
      // "is_banned":"1"
      final raw =
          data['is_banned'] ?? data['is_blocked'] ?? data['banned'] ?? 0;
      final s = raw.toString().toLowerCase().trim();
      final banned = (s == '1' || s == 'true');

      final reason =
          (data['banned_reason'] ??
                  data['blocked_reason'] ??
                  data['reason'] ??
                  '')
              .toString();

      return _BanResult(banned, reason);
    } catch (e) {
      // لو صار أي خطأ (نت أو JSON) → ما نعطّل التطبيق
      debugPrint('BAN CHECK ERROR: $e');
      return const _BanResult(false, '');
    }
  }
}
