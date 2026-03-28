import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// كنترولر متابعة الاتصال بالإنترنت
class ConnectionController extends GetxController {
  // اسم مسار شاشة عدم الاتصال (تأكد إنه نفس الاسم في routes)
  static const String noConnectionRoute = '/no_connection';

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _sub;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
  }

  /// فحص أولي + تشغيل الاستماع لأي تغيّر في الاتصال
  Future<void> _initConnectivity() async {
    try {
      // فحص أولي
      final ConnectivityResult result = await _connectivity.checkConnectivity();
      _handleStatus(result);

      // متابعة التغيّر في الاتصال
      _sub = _connectivity.onConnectivityChanged.listen((result) {
        _handleStatus(result);
      });
    } catch (_) {
      // لو صار خطأ اعتبره بدون إنترنت
      _handleStatus(ConnectivityResult.none);
    }
  }

  /// التعامل مع حالة الاتصال
  void _handleStatus(ConnectivityResult result) {
    final bool connected = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;

    if (!connected) {
      // مافيش إنترنت → افتح شاشة no_connection لو مش مفتوحة أصلاً
      if (Get.currentRoute != noConnectionRoute) {
        Get.toNamed(noConnectionRoute);
      }
    } else {
      // في إنترنت → لو نحن واقفين على شاشة no_connection رجّعنا للي قبلها
      if (Get.currentRoute == noConnectionRoute) {
        final canPop = Get.key.currentState?.canPop() ?? false;
        if (canPop) {
          Get.back(); // يرجع لنفس الشاشة اللي كان فيها المستخدم
        }
        // لو ما يقدرش يرجع (نادرًا)، نخليه زي ما هو عشان ما نطيحوش في خطأ
      }
    }
  }

  /// زر "إعادة المحاولة" في شاشة no_connection
  Future<void> retryConnection() async {
    final ConnectivityResult result = await _connectivity.checkConnectivity();
    _handleStatus(result);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
