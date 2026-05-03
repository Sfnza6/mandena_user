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
  final statusOrder = 'delivery'.obs;
  final stepIndex = 0.obs;
  final stepTimes = <int, String>{}.obs;

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
      final initialStatusOrder = (args['status_order'] ?? args['statusOrder'])
          ?.toString();
      if (initialStatusOrder == 'pickup' ||
          initialStatusOrder == 'internal_pickup') {
        statusOrder.value = initialStatusOrder!;
      }
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
      statusOrder.value = _extractStatusOrder(res);
      stepIndex.value = _mapStatusToStep(s);
      _extractStepTimes(res);

      final pLat = _toD(res['pickup_lat']);
      final pLng = _toD(res['pickup_lng']);
      if (pLat != null && pLng != null) pickupPos.value = LatLng(pLat, pLng);

      final dLat = _toD(res['dest_lat']);
      final dLng = _toD(res['dest_lng']);
      if (dLat != null && dLng != null) destPos.value = LatLng(dLat, dLng);

      final did = int.tryParse('${res['driver_id'] ?? ''}');
      if (isPickupOrder) {
        driverId.value = null;
        _stopDriverPolling();
      } else if (did != null && did > 0) {
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

  String _extractStatusOrder(Map<dynamic, dynamic> res) {
    final order = (res['order'] is Map)
        ? Map<String, dynamic>.from(res['order'])
        : const <String, dynamic>{};
    final raw =
        (res['status_order'] ??
                order['status_order'] ??
                res['status_order_label'] ??
                order['status_order_label'] ??
                'delivery')
            .toString()
            .toLowerCase()
            .trim();
    if (raw == 'pickup' || raw == 'استلام خارجي') return 'pickup';
    if (raw == 'internal_pickup' || raw == 'استلام داخلي') {
      return 'internal_pickup';
    }
    return 'delivery';
  }

  bool get isPickupOrder =>
      statusOrder.value == 'pickup' || statusOrder.value == 'internal_pickup';

  bool get isInternalPickup => statusOrder.value == 'internal_pickup';

  List<String> get trackingSteps {
    if (isPickupOrder) {
      return const <String>[
        'بانتظار\nالقبول',
        'جاري\nالتحضير',
        'تم\nالتجهيز',
        'مكتملة',
      ];
    }

    return const <String>[
      'بانتظار\nالقبول',
      'جاري التحضير\nوالبحث',
      'تم تعيين\nسائق',
      'جاري\nالتوصيل',
      'مكتملة',
    ];
  }

  void _extractStepTimes(Map<dynamic, dynamic> res) {
    final order = (res['order'] is Map)
        ? Map<String, dynamic>.from(res['order'])
        : const <String, dynamic>{};

    dynamic pick(List<String> keys) {
      for (final k in keys) {
        final rootVal = res[k];
        if (_hasDateValue(rootVal)) return rootVal;

        final orderVal = order[k];
        if (_hasDateValue(orderVal)) return orderVal;
      }
      return null;
    }

    final rawTimes = <int, dynamic>{
      0: pick(const [
        'created_at',
        'ordered_at',
        'order_time',
        'customer_ordered_at',
      ]),
      1: pick(const [
        'approved_at',
        'accepted_at',
        'admin_approved_at',
        'processing_at',
        'preparing_at',
        'searching_driver_at',
        'ready_for_driver_at',
      ]),
      2: pick(const [
        'ready_at',
        'assigned_at',
        'driver_assigned_at',
        'driver_accepted_at',
        'accepted_driver_at',
        'driver_to_pickup_at',
      ]),
      3: pick(const [
        'on_the_way_at',
        'out_for_delivery_at',
        'delivering_at',
        'handover_at',
        'picked_up_at',
      ]),
      4: pick(const ['delivered_at', 'completed_at', 'complete_at']),
    };

    // بعض الحقول عندك محفوظة بتوقيت السيرفر UTC وبعضها بتوقيت ليبيا.
    // لذلك نطبّع العرض فقط حتى لا تظهر مرحلة لاحقة بوقت أقدم من المرحلة السابقة.
    final parsed = <int, DateTime?>{};
    DateTime? previous;

    for (int i = 0; i <= 4; i++) {
      DateTime? dt = _parseStepDateTime(rawTimes[i]);

      if (dt != null && previous != null && dt.isBefore(previous)) {
        int guard = 0;
        while (dt!.isBefore(previous) && guard < 3) {
          dt = dt.add(const Duration(hours: 2));
          guard++;
        }
      }

      parsed[i] = dt;
      if (dt != null) previous = dt;
    }

    stepTimes.assignAll(<int, String>{
      for (int i = 0; i <= 4; i++) i: _formatStepTime(parsed[i], rawTimes[i]),
    });
  }

  bool _hasDateValue(dynamic value) {
    if (value == null) return false;
    final s = value.toString().trim();
    return s.isNotEmpty &&
        s.toLowerCase() != 'null' &&
        s != '0000-00-00 00:00:00';
  }

  DateTime? _parseStepDateTime(dynamic raw) {
    if (!_hasDateValue(raw)) return null;
    final s = raw.toString().trim();

    DateTime? dt = DateTime.tryParse(s);
    dt ??= DateTime.tryParse(s.replaceFirst(' ', 'T'));
    return dt;
  }

  String _formatStepTime(DateTime? dt, dynamic fallbackRaw) {
    if (dt != null) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    if (!_hasDateValue(fallbackRaw)) return '—';
    final s = fallbackRaw.toString().trim();
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
    if (match != null) {
      final hh = match.group(1)!.padLeft(2, '0');
      final mm = match.group(2)!;
      return '$hh:$mm';
    }
    return s;
  }

  String stepTimeLabel(int index) {
    final realIndex = (isPickupOrder && index == 3) ? 4 : index;
    final t = stepTimes[realIndex]?.trim() ?? '—';
    if (t.isEmpty || t == '—') return '—';
    return t;
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
    if (const [
      'ready_pickup',
      'pickup_ready',
      'ready_for_pickup',
      'prepared_pickup',
    ].contains(x)) {
      return 'ready_pickup';
    }
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
    if (isPickupOrder) {
      switch (s) {
        case 'pending':
        case 'paid':
          return 0;
        case 'processing':
        case 'ready_for_driver':
        case 'searching_driver':
        case 'driver_offered':
        case 'assigned':
        case 'driver_to_pickup':
          return 1;
        case 'ready_pickup':
          return 2;
        case 'delivered':
          return 3;
        case 'rejected':
        case 'cancelled':
        case 'failed':
          return 0;
        default:
          return 0;
      }
    }

    switch (s) {
      case 'pending':
      case 'paid':
        return 0;

      case 'processing':
      case 'ready_for_driver':
      case 'searching_driver':
      case 'driver_offered':
        return 1;

      case 'assigned':
      case 'driver_to_pickup':
        return 2;

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
    if (isPickupOrder) {
      switch (status.value) {
        case 'pending':
        case 'paid':
          return '⏳ بانتظار قبول الطلب';
        case 'processing':
        case 'ready_for_driver':
        case 'searching_driver':
        case 'driver_offered':
        case 'assigned':
        case 'driver_to_pickup':
          return '🍳 جاري التحضير';
        case 'ready_pickup':
          return '✅ الطلب جاهز';
        case 'delivered':
          return '✅ مكتملة';
        case 'rejected':
          return '❌ تم رفض الطلب';
        case 'cancelled':
        case 'failed':
          return '❌ تم إلغاء الطلب';
        default:
          return 'جاري تحديث حالة الطلب';
      }
    }

    switch (status.value) {
      case 'pending':
      case 'paid':
        return '⏳ بانتظار قبول الطلب';
      case 'processing':
      case 'ready_for_driver':
      case 'searching_driver':
      case 'driver_offered':
        return '🍳 جاري التحضير / جاري البحث عن سائق';
      case 'assigned':
      case 'driver_to_pickup':
        return '🚗 جاري التحضير / تم تعيين سائق';
      case 'on_the_way':
      case 'out_for_delivery':
      case 'delivering':
      case 'handover':
        return '🏃 جاري التوصيل';
      case 'delivered':
        return '✅ مكتملة';
      case 'rejected':
        return '❌ تم رفض الطلب';
      case 'cancelled':
      case 'failed':
        return '❌ تم إلغاء الطلب';
      default:
        return 'جاري تحديث حالة الطلب';
    }
  }

  String get statusHint {
    if (isPickupOrder) {
      final type = isInternalPickup ? 'استلام داخلي' : 'استلام خارجي';
      switch (status.value) {
        case 'pending':
        case 'paid':
          return 'وصل طلبك للمطعم وسيتم مراجعته خلال لحظات.';
        case 'processing':
        case 'ready_for_driver':
        case 'searching_driver':
        case 'driver_offered':
        case 'assigned':
        case 'driver_to_pickup':
          return 'طلبك $type وهو الآن قيد التحضير داخل المطعم.';
        case 'ready_pickup':
          return 'طلبك جاهز للاستلام.';
        case 'delivered':
          return 'تم اكتمال الطلب بنجاح. بالعافية!';
        case 'rejected':
        case 'cancelled':
        case 'failed':
          return 'هذا الطلب لم يكتمل. يمكنك إنشاء طلب جديد.';
        default:
          return 'سيتم تحديث حالة الطلب تلقائياً.';
      }
    }

    switch (status.value) {
      case 'pending':
      case 'paid':
        return 'وصل طلبك للمطعم وسيتم مراجعته خلال لحظات.';
      case 'processing':
      case 'ready_for_driver':
      case 'searching_driver':
      case 'driver_offered':
        return 'المطعم يجهّز طلبك الآن، والنظام يبحث عن أقرب سائق متاح.';
      case 'assigned':
      case 'driver_to_pickup':
        return 'تم تعيين السائق لطلبك، والطلب ما زال قيد التحضير حتى يستلمه السائق.';
      case 'on_the_way':
      case 'out_for_delivery':
      case 'delivering':
      case 'handover':
        return 'السائق استلم الطلب وهو الآن في مرحلة التوصيل. تابع موقعه على الخريطة.';
      case 'delivered':
        return 'تم اكتمال الطلب بنجاح. بالعافية!';
      case 'rejected':
      case 'cancelled':
      case 'failed':
        return 'هذا الطلب لم يكتمل. يمكنك إنشاء طلب جديد.';
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
