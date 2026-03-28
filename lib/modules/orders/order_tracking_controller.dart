import 'dart:async';
import 'dart:io'; // ✅ للتمييز بين أخطاء الشبكة وغيرها
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api_service.dart';

class OrderTrackingController extends GetxController {
  final _api = ApiService();

  final orderId = RxnInt();

  final status = 'pending'.obs;
  final stepIndex = 0.obs;

  final driverId  = RxnInt();
  final driverPos = Rxn<LatLng>(); // live
  final pickupPos = Rxn<LatLng>();
  final destPos   = Rxn<LatLng>();

  Timer? _statusTimer;
  Timer? _driverTimer;

  final statusIntervalSec = 5;
  final driverIntervalSec = 3;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['orderId'] != null) {
      orderId.value = int.tryParse(args['orderId'].toString());
    }
  }

  @override
  void onReady() {
    super.onReady();
    _startStatusPolling();
  }

  void _startStatusPolling() {
    _fetchOrderOnce();
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
      Duration(seconds: statusIntervalSec),
      (_) => _fetchOrderOnce(),
    );
  }

  Future<void> _fetchOrderOnce() async {
    if (orderId.value == null) {
      // ✅ رسالة ودّية إن لم يصل رقم الطلب
      Get.snackbar('تنبيه', 'تعذّر تتبّع الطلب لعدم توفّر رقم الطلب. جرّب فتح الطلب مجددًا.');
      return;
    }
    try {
      final res = await _api.get(
        'get_order_status.php',
        params: {'order_id': orderId.value.toString()},
      );

      final s = (res['status'] ?? res['state'] ?? 'pending')
          .toString()
          .toLowerCase();
      status.value = s;
      stepIndex.value = _mapStatusToStep(s);

      final pLat = _toD(res['pickup_lat']);
      final pLng = _toD(res['pickup_lng']);
      if (pLat != null && pLng != null) pickupPos.value = LatLng(pLat, pLng);

      final dLat = _toD(res['dest_lat']);
      final dLng = _toD(res['dest_lng']);
      if (dLat != null && dLng != null) destPos.value = LatLng(dLat, dLng);

      final did = int.tryParse('${res['driver_id'] ?? ''}');
      if (did != null && did > 0) {
        if (driverId.value != did) {
          driverId.value = did;
          _startDriverPolling();
        }
      } else {
        driverId.value = null;
        _stopDriverPolling();
      }
    } catch (e) {
      // ✅ رسالة إنسانية بدل الخطأ التقني
      Get.snackbar('تعذّر التحديث', _friendlyError(e));
    }
  }

  void _startDriverPolling() {
    if (driverId.value == null) return;
    _fetchDriverOnce();
    _driverTimer?.cancel();
    _driverTimer = Timer.periodic(
      Duration(seconds: driverIntervalSec),
      (_) => _fetchDriverOnce(),
    );
  }

  void _stopDriverPolling() {
    _driverTimer?.cancel();
    _driverTimer = null;
  }

  Future<void> _fetchDriverOnce() async {
    final did = driverId.value;
    if (did == null) return;
    try {
      final res = await _api.get(
        'get_driver_live.php',
        params: {'driver_id': '$did'},
      );
      final lat = _toD(res['lat']);
      final lng = _toD(res['lng']);
      if (lat != null && lng != null) {
        driverPos.value = LatLng(lat, lng);
      }
    } catch (e) {
      // ✅ رسالة ودّية عند فشل جلب موقع السائق
      Get.snackbar('تنبيه', _friendlyError(e));
    }
  }

  double? _toD(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  int _mapStatusToStep(String s) {
    switch (s) {
      case 'pending':     return 0;
      case 'processing':  return 1;
      case 'assigned':
      case 'on_the_way':
      case 'delivering':  return 2;
      case 'handover':    return 3;
      default:            return 0;
    }
  }

  String get arabicStatus {
    switch (status.value) {
      case 'pending':     return 'تم تقديم الطلب';
      case 'processing':  return 'تم تأكيد الطلب';
      case 'assigned':
      case 'on_the_way':
      case 'delivering':  return 'تحضير السلعة / في الطريق';
      case 'handover':    return 'التسليم جارٍ';
      case 'delivered':   return 'تم التسليم';
      case 'rejected':
      case 'cancelled':   return 'تم إلغاء الطلب';
      default:            return '...';
    }
  }

  @override
  void onClose() {
    _statusTimer?.cancel();
    _driverTimer?.cancel();
    super.onClose();
  }

  // ================== رسائل ودّية للأخطاء (لا تغيير في المنطق) ==================
  String _friendlyError(Object e) {
    final t = e.toString().toLowerCase();

    if (e is TimeoutException || t.contains('timeout')) {
      return 'انتهت مهلة الاتصال. تأكّد من الإنترنت ثم أعد المحاولة.';
    }
    if (e is SocketException || _looksOffline(t)) {
      return 'يبدو أنه لا يوجد اتصال بالإنترنت حاليًا. تحقّق من الشبكة ثم حاول مرة أخرى.';
    }
    if (t.contains('failed host lookup') || t.contains('dns')) {
      return 'تعذّر الوصول إلى الخادم. تحقّق من الشبكة أو جرّب لاحقًا.';
    }
    if (t.contains('format exception') || t.contains('json')) {
      return 'حدث خلل أثناء قراءة البيانات. سنحاول إصلاحه، أعد المحاولة لاحقًا.';
    }
    return 'حدث خلل غير متوقّع أثناء التحديث. يرجى المحاولة لاحقًا.';
  }

  bool _looksOffline(String t) {
    return t.contains('socketexception') ||
        t.contains('network is unreachable') ||
        t.contains('connection refused') ||
        t.contains('handshake');
  }
}
