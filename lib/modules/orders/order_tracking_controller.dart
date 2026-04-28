import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../core/api_service.dart';

class OrderTrackingController extends GetxController {
  final _api = ApiService();

  final orderId = RxnInt();

  /// الحالة الحالية كما تظهر في قاعدة البيانات بعد توحيد الأسماء.
  final status = 'pending'.obs;
  final stepIndex = 0.obs;

  final driverId = RxnInt();
  final driverPos = Rxn<LatLng>();
  final pickupPos = Rxn<LatLng>();
  final destPos = Rxn<LatLng>();

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
    refreshNow();
    _startStatusPolling();
  }

  Future<void> refreshNow() async => _fetchOrderOnce(showSnack: true);

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
      Duration(seconds: statusIntervalSec),
      (_) => _fetchOrderOnce(showSnack: false),
    );
  }

  Future<void> _fetchOrderOnce({bool showSnack = false}) async {
    if (orderId.value == null) {
      if (showSnack) {
        Get.snackbar(
          'تنبيه',
          'تعذّر تتبّع الطلب لعدم توفّر رقم الطلب. جرّب فتح الطلب مجددًا.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      return;
    }

    try {
      final res = await _api.get(
        'get_order_status.php',
        params: {
          'order_id': orderId.value.toString(),
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final raw = (res['status'] ?? res['state'] ?? 'pending').toString();
      final s = normalizeStatus(raw);
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

      if (isTerminalStatus) {
        _statusTimer?.cancel();
        _stopDriverPolling();
      }
    } catch (e) {
      if (showSnack) {
        Get.snackbar(
          'تعذّر التحديث',
          _friendlyError(e),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void _startDriverPolling() {
    if (driverId.value == null) return;
    _fetchDriverOnce(showSnack: false);
    _driverTimer?.cancel();
    _driverTimer = Timer.periodic(
      Duration(seconds: driverIntervalSec),
      (_) => _fetchDriverOnce(showSnack: false),
    );
  }

  void _stopDriverPolling() {
    _driverTimer?.cancel();
    _driverTimer = null;
  }

  Future<void> _fetchDriverOnce({bool showSnack = false}) async {
    final did = driverId.value;
    if (did == null) return;

    try {
      final res = await _api.get(
        'get_driver_live.php',
        params: {
          'driver_id': '$did',
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final lat = _toD(res['lat']);
      final lng = _toD(res['lng']);
      if (lat != null && lng != null) {
        driverPos.value = LatLng(lat, lng);
      }
    } catch (e) {
      if (showSnack) {
        Get.snackbar(
          'تنبيه',
          _friendlyError(e),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  double? _toD(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return double.tryParse(s);
  }

  static String normalizeStatus(String value) {
    final x = value.toLowerCase().trim();

    if (const [
      'approved',
      'accepted',
      'accept',
      'in_prep',
      'readying',
    ].contains(x)) {
      return 'processing';
    }

    if (const ['prepare', 'preparing'].contains(x)) return 'processing';
    if (const ['ready', 'ready_for_delivery'].contains(x)) {
      return 'ready_for_driver';
    }
    if (const ['offered', 'driver_offer', 'driver_offered'].contains(x)) {
      return 'driver_offered';
    }
    if (const ['searching', 'searching_driver', 'find_driver'].contains(x)) {
      return 'searching_driver';
    }
    if (const ['driver_to_restaurant', 'driver_to_pickup'].contains(x)) {
      return 'driver_to_pickup';
    }
    if (const ['on_way', 'on_the_way', 'out_for_delivery'].contains(x)) {
      return 'out_for_delivery';
    }
    if (const ['success', 'complete', 'completed'].contains(x)) {
      return 'delivered';
    }
    if (const ['canceled', 'cancel'].contains(x)) return 'cancelled';

    return x.isEmpty ? 'pending' : x;
  }

  int _mapStatusToStep(String s) {
    switch (s) {
      case 'pending':
      case 'paid':
        return 0;

      case 'processing':
        return 1;

      case 'ready_for_driver':
      case 'searching_driver':
      case 'driver_offered':
        return 2;

      case 'assigned':
      case 'driver_to_pickup':
      case 'on_the_way':
      case 'out_for_delivery':
      case 'delivering':
      case 'handover':
        return 3;

      case 'delivered':
        return 4;

      case 'rejected':
      case 'cancelled':
      case 'failed':
        return 0;

      default:
        return 0;
    }
  }

  bool get isCancelledStatus =>
      const {'rejected', 'cancelled', 'failed'}.contains(status.value);

  bool get isDeliveredStatus => status.value == 'delivered';

  bool get isTerminalStatus => isCancelledStatus || isDeliveredStatus;

  String get arabicStatus {
    switch (status.value) {
      case 'pending':
      case 'paid':
        return 'بانتظار قبول الطلب';
      case 'processing':
        return 'جاري تحضير الطلب';
      case 'ready_for_driver':
        return 'الطلب جاهز ونبحث عن سائق';
      case 'searching_driver':
        return 'جاري البحث عن أقرب سائق';
      case 'driver_offered':
        return 'تم إرسال الطلب للسائق';
      case 'assigned':
        return 'تم قبول الطلب من السائق';
      case 'driver_to_pickup':
        return 'السائق متجه لاستلام الطلب';
      case 'on_the_way':
      case 'out_for_delivery':
      case 'delivering':
        return 'السائق في الطريق إليك';
      case 'handover':
        return 'جاري تسليم الطلب';
      case 'delivered':
        return 'تم التسليم بنجاح';
      case 'rejected':
        return 'تم رفض الطلب';
      case 'cancelled':
      case 'failed':
        return 'تم إلغاء الطلب';
      default:
        return 'جاري تحديث حالة الطلب';
    }
  }

  String get statusHint {
    switch (status.value) {
      case 'pending':
      case 'paid':
        return 'وصل طلبك للمطعم وسيتم مراجعته خلال لحظات.';
      case 'processing':
        return 'المطعم يعمل على تجهيز طلبك الآن.';
      case 'ready_for_driver':
      case 'searching_driver':
      case 'driver_offered':
        return 'الطلب جاهز، ويتم اختيار أقرب سائق تابع لنفس الفرع.';
      case 'assigned':
      case 'driver_to_pickup':
        return 'تم تحديد السائق وسيبدأ التوصيل بعد استلام الطلب.';
      case 'on_the_way':
      case 'out_for_delivery':
      case 'delivering':
      case 'handover':
        return 'تابع موقع السائق على الخريطة حتى يصل إليك.';
      case 'delivered':
        return 'نأمل أن تكون تجربتك ممتازة. بالعافية.';
      case 'rejected':
      case 'cancelled':
      case 'failed':
        return 'هذا الطلب لم يكتمل. يمكنك مراجعة التفاصيل أو إنشاء طلب جديد.';
      default:
        return 'سيتم تحديث حالة الطلب تلقائياً.';
    }
  }

  @override
  void onClose() {
    _statusTimer?.cancel();
    _driverTimer?.cancel();
    super.onClose();
  }

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
      return 'حدث خلل أثناء قراءة البيانات. أعد المحاولة لاحقًا.';
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
