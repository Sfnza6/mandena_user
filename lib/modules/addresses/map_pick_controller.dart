// lib/modules/addresses/map_pick_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:get_storage/get_storage.dart'; // ✅ كاش بسيط لآخر موقع

class MapPickController extends GetxController {
  // نقطة افتراضية (سرت) — عدّلها لو تحب
  final LatLng initial = const LatLng(31.206518, 16.588744);

  /// موضع الكاميرا الحالي
  final center = Rx<LatLng>(const LatLng(31.206518, 16.588744));
  /// الماركر المختار
  final marker = Rx<LatLng?>(null);
  /// حالة تحميل زر تحديد موقعي
  final isBusy = false.obs;

  // ===================== تخزين بسيط لآخر موقع ======================
  late final GetStorage _box;
  static const String _kLastLatKey = 'map_pick_last_lat_v1';
  static const String _kLastLngKey = 'map_pick_last_lng_v1';

  void _initStorage() {
    try {
      _box = GetStorage();
    } catch (_) {
      // في الغالب GetStorage.init معمول في main
      _box = GetStorage();
    }
  }

  void _loadLastLocationIfAny() {
    try {
      final lat = _box.read(_kLastLatKey);
      final lng = _box.read(_kLastLngKey);
      if (lat is num && lng is num) {
        final p = LatLng(lat.toDouble(), lng.toDouble());
        center.value = p;
        marker.value = p;
      }
    } catch (_) {
      // لو في خطأ في الكاش نتجاهله بصمت
    }
  }

  void _saveLastLocation(LatLng p) {
    try {
      _box.write(_kLastLatKey, p.latitude);
      _box.write(_kLastLngKey, p.longitude);
    } catch (_) {
      // تجاهل أي خطأ
    }
  }
  // =================================================================

  // ===================== رسائل ودّية + Snackbar أنيق ======================
  DateTime? _lastSnackAt;
  static const _snackThrottle = Duration(seconds: 4);

  void _showSnack({
    required Color bg,
    required String title,
    required String msg,
    String? actionLabel,
    VoidCallback? onAction,
    int seconds = 4,
  }) {
    final now = DateTime.now();
    if (_lastSnackAt != null && now.difference(_lastSnackAt!) < _snackThrottle) return;
    _lastSnackAt = now;

    Get.rawSnackbar(
      borderRadius: 14,
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      backgroundColor: bg,
      messageText: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Text(msg,
                style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 13.5, height: 1.3)),
          ],
        ),
      ),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          if (onAction != null) onAction();
        },
        child: Text(
          actionLabel ?? 'إغلاق',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      duration: Duration(seconds: seconds),
    );
  }

  void _showUserError(String msg, {String title = 'تعذّر إتمام العملية', VoidCallback? onRetry}) {
    _showSnack(
      bg: const Color(0xFF1F2937),
      title: title,
      msg: msg,
      actionLabel: onRetry != null ? 'إعادة المحاولة' : 'إغلاق',
      onAction: onRetry,
    );
  }

  void _showInfo(String msg, {String title = 'تنبيه'}) {
    _showSnack(bg: const Color(0xFF374151), title: title, msg: msg, seconds: 3);
  }

  void _showSuccess(String msg, {String title = 'تم'}) {
    _showSnack(bg: const Color(0xFF065F46), title: title, msg: msg, seconds: 3);
  }

  String _friendlyMessage(Object e) {
    final t = e.toString().toLowerCase();
    if (t.contains('permission') || t.contains('denied')) {
      return '🔒 الصلاحية مطلوبة للوصول إلى موقعك.\nاسمح بالموقع من الإعدادات ثم أعد المحاولة.';
    }
    if (t.contains('service status disabled') || t.contains('location services are disabled')) {
      return '📍 خدمة تحديد الموقع مغلقة.\nفعّل الموقع من الإعدادات ثم أعد المحاولة.';
    }
    if (t.contains('timeout') || t.contains('timed out') || t.contains('deadline exceeded')) {
      return '⏳ انتهت مهلة الحصول على الموقع.\nحاول مجدداً بعد لحظات.';
    }
    return 'حدث خطأ غير متوقع.\nيرجى المحاولة لاحقاً.';
  }
  // ======================================================================

  @override
  void onInit() {
    super.onInit();
    _initStorage();

    final args = (Get.arguments as Map?) ?? {};
    final double? lat = (args['lat'] as num?)?.toDouble();
    final double? lng = (args['lng'] as num?)?.toDouble();

    if (lat != null && lng != null) {
      // ✅ لو جاي lat/lng من الشاشة السابقة، نعتمدها دائماً
      final p = LatLng(lat, lng);
      center.value = p;
      marker.value = p;
    } else {
      // لو ما فيش args → نحاول نستخدم آخر موقع مخزّن، ولو مش موجود نرجع للـ initial
      _loadLastLocationIfAny();
      marker.value ??= null;
      center.value = marker.value ?? initial;
    }
  }

  void onTap(LatLng p) {
    marker.value = p;
    center.value = p;
  }

  Future<void> myLocation() async {
    isBusy.value = true;
    try {
      final svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) {
        _showInfo('خدمة الموقع مغلقة. سيتم فتح الإعدادات.', title: 'تنبيه');
        await Geolocator.openLocationSettings();
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _showUserError('صلاحية الموقع مرفوضة دائمًا. افتح الإعدادات ومنح الإذن.',
            onRetry: () => Geolocator.openAppSettings());
        return;
      }
      if (perm == LocationPermission.denied) {
        _showUserError('تم رفض صلاحية الموقع. يرجى السماح بالموقع ثم المحاولة مجدداً.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final p = LatLng(pos.latitude, pos.longitude);
      onTap(p);
      _showSuccess('تم تحديد موقعك الحالي.');
    } catch (e) {
      _showUserError(_friendlyMessage(e));
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> confirm() async {
    final p = marker.value;
    if (p == null) {
      _showInfo('اختر موقعًا على الخريطة أولاً', title: 'تنبيه');
      return;
    }

    // ✅ نحفظ آخر موقع بعد التأكيد
    _saveLastLocation(p);

    String pretty = '';
    try {
      final list = await placemarkFromCoordinates(p.latitude, p.longitude);
      if (list.isNotEmpty) {
        final pl = list.first;
        pretty = [
          pl.country,
          pl.administrativeArea,
          pl.locality,
          pl.subLocality,
          pl.street
        ].where((e) => (e ?? '').toString().trim().isNotEmpty).join(' - ');
      }
    } catch (_) {
      // لا نظهر رسالة تقنية للمستخدم — العنوان الجميل اختياري فقط
    }

    Get.back(result: {
      'lat': p.latitude,
      'lng': p.longitude,
      'address_text': pretty,
    });
  }
}

