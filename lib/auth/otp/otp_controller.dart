// lib/auth/otp/otp_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../app_routes.dart'; // للانتقال إلى صفحة تسجيل الدخول

class OtpController extends GetxController {
  /// عدّل هذا حسب بيئتك:
  /// - Windows/Web/Device:  http://127.0.0.1/iforenta_api  (أو IP جهازك على الشبكة)
  /// - Android Emulator:     http://10.0.2.2/iforenta_api
  final String baseUrl = 'https://evoranta.ly';

  final isSending   = false.obs;
  final isVerifying = false.obs;
  final resendLeft  = 60.obs;
  Timer? _timer;

  void startTimer([int secs = 60]) {
    resendLeft.value = secs;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendLeft.value <= 0) {
        t.cancel();
      } else {
        resendLeft.value--;
      }
    });
  }

  // ===================== رسائل ودّية + Snackbar أنيق ======================
  DateTime? _lastSnackAt;
  static const _snackThrottle = Duration(seconds: 4);

  void _showUserError(String msg, {String title = 'تعذّر إتمام العملية', VoidCallback? onRetry}) {
    final now = DateTime.now();
    if (_lastSnackAt != null && now.difference(_lastSnackAt!) < _snackThrottle) return;
    _lastSnackAt = now;

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
            Text(title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(msg,
              style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 13.5, height: 1.3),
            ),
          ],
        ),
      ),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          if (onRetry != null) onRetry();
        },
        child: Text(onRetry != null ? 'إعادة المحاولة' : 'إغلاق',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
    if (t.contains('timeout') || t.contains('timed out') || t.contains('deadline exceeded')) {
      return '⏳ انتهت مهلة الاتصال.\nحاول مجدداً بعد لحظات.';
    }
    if (t.contains('handshakeexception') || t.contains('certificate') || t.contains('ssl')) {
      return '🔐 مشكلة أمان مؤقتة أثناء الاتصال بالخادم.\nيرجى المحاولة لاحقاً.';
    }
    if (t.contains('formatexception') || t.contains('unexpected character') || t.contains('json')) {
      return '⚠️ حدث خلل في البيانات المستلمة.\nسنحاول إصلاحه، جرّب لاحقاً.';
    }
    return 'حدث خطأ غير متوقع.\nيرجى المحاولة لاحقاً.';
  }

  String _friendlyHttp(int code) {
    if (code == 401 || code == 403) return '⛔ طلب غير مصرح.\nتحقّق من البيانات ثم حاول مجدداً.';
    if (code == 404) return '🔎 الخدمة غير متاحة حالياً.';
    if (code == 429) return '🚦 محاولات كثيرة خلال وقت قصير.\nانتظر قليلاً ثم أعد المحاولة.';
    if (code >= 500 && code <= 504) {
      return '🛠️ الخدمة غير متاحة مؤقتاً.\nنقوم بالصيانة أو يوجد ضغط كبير.';
    }
    return 'تعذّر التواصل مع الخادم (HTTP $code). حاول لاحقاً.';
  }

  bool _isErrorStatus(dynamic s) {
    if (s == null) return true;
    if (s is bool) return s == false;
    final str = s.toString().toLowerCase();
    return str == 'error' || str == 'fail' || str == '0' || str == 'false';
  }

  String _serverMessage(Map<String, dynamic> m, {String fallback = 'حدث خطأ، حاول لاحقاً.'}) {
    final cands = [m['message'], m['msg'], m['error'], m['detail'], m['desc']];
    for (final c in cands) {
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    return fallback;
  }
  // ======================================================================

  // --- Helpers ---
  String _normalizeLibyaPhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (!digits.startsWith('218')) {
      if (digits.startsWith('0')) digits = digits.substring(1);
      digits = '218$digits';
    }
    return digits;
  }

  Map<String, dynamic> _safeJson(String body, int statusCode) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'status': 'error',
        'http': statusCode,
        'message': 'رد غير JSON من السيرفر',
        'raw': body.substring(0, body.length > 400 ? 400 : body.length),
      };
    }
  }

  // --- API ---
  Future<Map<String, dynamic>> sendOtp({ required String phone }) async {
    isSending.value = true;
    try {
      final normalized = _normalizeLibyaPhone(phone);

      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/send_otp.php'),
            body: {
              'phone': normalized,
              'service_name': 'EVORANTA',
              'len': '6',
            },
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = _friendlyHttp(res.statusCode);
        _showUserError(msg, onRetry: () => sendOtp(phone: phone));
        return {'status':'error','code':res.statusCode,'message':msg};
      }

      final data = _safeJson(res.body, res.statusCode);
      if (_isErrorStatus(data['status'])) {
        final msg = _serverMessage(data, fallback: 'تعذّر إرسال رمز التحقق. حاول لاحقاً.');
        _showUserError(msg, onRetry: () => sendOtp(phone: phone));
      }
      return data;
    } on TimeoutException {
      final msg = '⏳ انتهت مهلة الاتصال.\nحاول مجدداً بعد لحظات.';
      _showUserError(msg, onRetry: () => sendOtp(phone: phone));
      return {'status':'error','message': msg};
    } catch (e) {
      final msg = _friendlyMessage(e);
      _showUserError(msg, onRetry: () => sendOtp(phone: phone));
      return {'status':'error','message': msg};
    } finally {
      isSending.value = false;
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    required String otpId,
  }) async {
    isVerifying.value = true;
    try {
      final normalized = _normalizeLibyaPhone(phone);

      final res = await http
          .post(
            Uri.parse('$baseUrl/auth/verify_otp.php'),
            body: {
              'phone': normalized,
              'code': code,
              'otp_id': otpId,
            },
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        final msg = _friendlyHttp(res.statusCode);
        _showUserError(msg, onRetry: () => verifyOtp(phone: phone, code: code, otpId: otpId));
        return {'status':'error','code':res.statusCode,'message': msg};
      }

      final data = _safeJson(res.body, res.statusCode);
      if (_isErrorStatus(data['status'])) {
        final msg = _serverMessage(data, fallback: 'رمز التحقق غير صحيح أو منتهي.');
        _showUserError(msg);
      }
      return data;
    } on TimeoutException {
      final msg = '⏳ انتهت مهلة الاتصال.\nحاول مجدداً بعد لحظات.';
      _showUserError(msg, onRetry: () => verifyOtp(phone: phone, code: code, otpId: otpId));
      return {'status':'error','message': msg};
    } catch (e) {
      final msg = _friendlyMessage(e);
      _showUserError(msg, onRetry: () => verifyOtp(phone: phone, code: code, otpId: otpId));
      return {'status':'error','message': msg};
    } finally {
      isVerifying.value = false;
    }
  }

  /// ✅ واجهة مريحة: تؤكد OTP ثم تعرض رسالة نجاح وتحوّل لصفحة تسجيل الدخول
  Future<void> confirmOtpAndFinish({
    required String phone,
    required String code,
    required String otpId,
  }) async {
    isVerifying.value = true;
    try {
      final res = await verifyOtp(phone: phone, code: code, otpId: otpId);
      final status = (res['status'] ?? '').toString().toLowerCase();

      if (status == 'ok' || status == 'success' || status == 'verified') {
        final msg = (res['message'] ?? 'تم التحقق وتسجيل الحساب بنجاح. يمكنك الآن تسجيل الدخول.').toString();

        Get.rawSnackbar(
          borderRadius: 14,
          snackStyle: SnackStyle.FLOATING,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          backgroundColor: const Color(0xFF065F46), // أخضر أنيق للنجاح
          messageText: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          duration: const Duration(seconds: 3),
        );

        Get.offAllNamed(AppRoutes.login);
        return;
      }

      final msg = (res['message'] ?? 'تعذّر التحقق، حاول مرة أخرى').toString();
      _showUserError(msg, title: 'تعذّر التحقق');
    } catch (e) {
      _showUserError(_friendlyMessage(e), title: 'تعذّر التحقق');
    } finally {
      isVerifying.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
