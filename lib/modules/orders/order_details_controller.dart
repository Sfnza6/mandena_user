import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:mandena/core/api_service.dart';
import 'package:mandena/core/env.dart';
import 'package:mandena/core/session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderExtraModel {
  final String name;
  final int quantity;
  final double price;
  final double lineTotal;

  OrderExtraModel({
    required this.name,
    required this.quantity,
    required this.price,
    required this.lineTotal,
  });

  factory OrderExtraModel.fromJson(Map<String, dynamic> j) => OrderExtraModel(
    name: (j['name'] ?? '').toString(),
    quantity: int.tryParse('${j['quantity'] ?? 1}') ?? 1,
    price: (j['price'] is num)
        ? (j['price'] as num).toDouble()
        : (double.tryParse('${j['price']}') ?? 0.0),
    lineTotal: (j['line_total'] is num)
        ? (j['line_total'] as num).toDouble()
        : (double.tryParse('${j['line_total']}') ?? 0.0),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'price': price,
    'line_total': lineTotal,
  };
}

class OrderComponentModel {
  final int id;
  final String name;
  final int quantity;
  final double price;

  OrderComponentModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderComponentModel.fromJson(Map<String, dynamic> j) =>
      OrderComponentModel(
        id: int.tryParse('${j['id'] ?? j['com_id'] ?? 0}') ?? 0,
        name: (j['name'] ?? j['title'] ?? '').toString(),
        quantity: int.tryParse('${j['quantity'] ?? j['qty'] ?? 1}') ?? 1,
        price: (j['price'] is num)
            ? (j['price'] as num).toDouble()
            : (double.tryParse('${j['price']}') ?? 0.0),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'price': price,
  };
}

class OrderItemModel {
  final int orderItemId;
  final int itemId;
  final String name;
  final int quantity;
  final double price;
  final double lineTotal;
  final double lineTotalWithExtras;
  final List<OrderExtraModel> extras;
  final List<OrderComponentModel> componentsAdd;
  final List<OrderComponentModel> componentsRem;

  OrderItemModel({
    required this.orderItemId,
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.lineTotal,
    required this.lineTotalWithExtras,
    required this.extras,
    required this.componentsAdd,
    required this.componentsRem,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> j) {
    final orderItemId = int.tryParse('${j['order_item_id']}') ?? 0;
    final itemId = int.tryParse('${j['item_id']}') ?? 0;

    List asList(v) {
      if (v is List) return v;
      if (v is String && v.trim().startsWith('[')) {
        try {
          return jsonDecode(v) as List;
        } catch (_) {}
      }
      return const [];
    }

    List pickList(Map<String, dynamic> src, List<String> keys) {
      for (final k in keys) {
        if (src.containsKey(k) && src[k] != null) {
          final v = src[k];
          final lst = asList(v);
          if (lst.isNotEmpty) return lst;
        }
      }
      return const [];
    }

    bool belongsToThisItem(Map<String, dynamic> m) {
      final oi =
          int.tryParse('${m['order_item_id'] ?? m['oi_id'] ?? ''}') ?? -1;
      final ii = int.tryParse('${m['item_id'] ?? m['itemId'] ?? ''}') ?? -1;
      if (oi > 0) return oi == orderItemId;
      if (ii > 0) return ii == itemId;
      return true;
    }

    final extrasList = (j['extras'] is List)
        ? (j['extras'] as List)
              .map(
                (e) => OrderExtraModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <OrderExtraModel>[];

    final rawAdd = pickList(j, const [
      'components_add',
      'componentsAdd',
    ]).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawRem = pickList(j, const [
      'components_rem',
      'componentsRem',
      'components_removed',
    ]).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final compsAdd = rawAdd
        .where(belongsToThisItem)
        .map((e) => OrderComponentModel.fromJson(e))
        .toList();

    final compsRem = rawRem
        .where(belongsToThisItem)
        .map((e) => OrderComponentModel.fromJson(e))
        .toList();

    final lineTotalVal = (j['line_total'] is num)
        ? (j['line_total'] as num).toDouble()
        : (double.tryParse('${j['line_total']}') ?? 0.0);

    final extrasSum = extrasList.fold<double>(
      0.0,
      (s, x) => s + (x.price * x.quantity),
    );
    final compsAddSum = compsAdd.fold<double>(
      0.0,
      (s, x) => s + (x.price * x.quantity),
    );
    final fallbackWithExtras = lineTotalVal + extrasSum + compsAddSum;

    final ltw = (j['line_total_with_extras'] is num)
        ? (j['line_total_with_extras'] as num).toDouble()
        : (double.tryParse('${j['line_total_with_extras']}') ?? 0.0);

    return OrderItemModel(
      orderItemId: orderItemId,
      itemId: itemId,
      name: (j['name'] ?? j['title'] ?? '').toString(),
      quantity: int.tryParse('${j['quantity'] ?? 0}') ?? 0,
      price: (j['price'] is num)
          ? (j['price'] as num).toDouble()
          : (double.tryParse('${j['price']}') ?? 0.0),
      lineTotal: lineTotalVal,
      lineTotalWithExtras: (ltw > 0) ? ltw : fallbackWithExtras,
      extras: extrasList,
      componentsAdd: compsAdd,
      componentsRem: compsRem,
    );
  }

  Map<String, dynamic> toJson() => {
    'order_item_id': orderItemId,
    'item_id': itemId,
    'name': name,
    'quantity': quantity,
    'price': price,
    'line_total': lineTotal,
    'line_total_with_extras': lineTotalWithExtras,
    'extras': extras.map((e) => e.toJson()).toList(),
    'components_add': componentsAdd.map((e) => e.toJson()).toList(),
    'components_rem': componentsRem.map((e) => e.toJson()).toList(),
  };
}

class OrderHeaderModel {
  final int id;
  final int userId;
  final int driverId;
  final String status;
  final String statusOrder;
  final double total;
  final String address;
  final String createdAt;
  final double deliveryFee;
  final double grandTotal;
  final int paymentMethod;
  final String gateway;

  OrderHeaderModel({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.status,
    required this.statusOrder,
    required this.total,
    required this.address,
    required this.createdAt,
    required this.deliveryFee,
    required this.grandTotal,
    required this.paymentMethod,
    required this.gateway,
  });

  factory OrderHeaderModel.fromJson(Map<String, dynamic> j) => OrderHeaderModel(
    id: int.tryParse('${j['id']}') ?? 0,
    userId: int.tryParse('${j['user_id']}') ?? 0,
    driverId: int.tryParse('${j['driver_id']}') ?? 0,
    status: (j['status'] ?? '').toString(),
    statusOrder: (j['status_order'] ?? j['status_order_label'] ?? '')
        .toString(),
    total: (j['total'] is num)
        ? (j['total'] as num).toDouble()
        : (double.tryParse('${j['total']}') ?? 0.0),
    address: (j['address'] ?? '').toString(),
    createdAt: (j['created_at'] ?? '').toString(),
    deliveryFee: (j['delivery_fee'] is num)
        ? (j['delivery_fee'] as num).toDouble()
        : (double.tryParse('${j['delivery_fee']}') ?? 0.0),
    grandTotal: (j['grand_total'] is num)
        ? (j['grand_total'] as num).toDouble()
        : (double.tryParse('${j['grand_total']}') ?? 0.0),
    paymentMethod:
        int.tryParse('${j['payment_method'] ?? j['payment'] ?? 0}') ?? 0,
    gateway: (j['gateway'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'driver_id': driverId,
    'status': status,
    'status_order': statusOrder,
    'total': total,
    'address': address,
    'created_at': createdAt,
    'delivery_fee': deliveryFee,
    'grand_total': grandTotal,
    'payment_method': paymentMethod,
    'gateway': gateway,
  };
}

class OrderDetailsController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final header = Rxn<OrderHeaderModel>();
  final items = <OrderItemModel>[].obs;
  final driver = Rxn<Map<String, dynamic>>();

  late int orderId;
  int? userId;

  String get _cacheKey => 'order_details_${orderId}_${userId ?? 0}';

  Future<void> _saveCache() async {
    try {
      final h = header.value;
      if (h == null) return;
      final sp = await SharedPreferences.getInstance();
      final data = {
        'header': h.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'driver': driver.value,
      };
      await sp.setString(_cacheKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadCache() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_cacheKey);
      if (s == null || s.isEmpty) return;
      final data = jsonDecode(s);
      if (data is! Map) return;

      final hRaw = data['header'];
      if (hRaw is Map) {
        header.value = OrderHeaderModel.fromJson(
          Map<String, dynamic>.from(hRaw),
        );
      }

      final itemsRaw = data['items'];
      if (itemsRaw is List) {
        items.assignAll(
          itemsRaw
              .map(
                (e) => OrderItemModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
        );
      }

      final dRaw = data['driver'];
      if (dRaw is Map) {
        driver.value = Map<String, dynamic>.from(dRaw);
      } else {
        driver.value = null;
      }
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    orderId =
        int.tryParse(
          '${args?['orderId'] ?? args?['order_id'] ?? args?['id'] ?? 0}',
        ) ??
        0;
    userId = int.tryParse('${args?['userId'] ?? args?['user_id'] ?? ''}');
  }

  @override
  void onReady() {
    super.onReady();
    _loadCache();
    fetch();
  }

  Future<void> fetch() async {
    if (orderId <= 0) {
      Get.snackbar('تنبيه', 'رقم الطلب غير صحيح. حاول فتح الطلب من جديد.');
      return;
    }

    try {
      loading(true);
      userId ??= await Session.userId();

      final res = await _api.get(
        Env.orderDetails,
        params: {
          'order_id': '$orderId',
          if (userId != null) 'user_id': '$userId',
          't': '${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final root = res is String ? jsonDecode(res) : res;
      if ((root['status'] ?? '').toString().toLowerCase() != 'success') {
        final msg = (root['message'] ?? '').toString().trim();
        Get.snackbar(
          'تعذّر التحميل',
          msg.isNotEmpty
              ? msg
              : 'لم نتمكّن من تحميل تفاصيل الطلب الآن. يُرجى المحاولة لاحقًا.',
        );
        header.value = null;
        items.clear();
        driver.value = null;
        await _loadCache();
        return;
      }

      final data = root['data'] ?? {};
      header.value = OrderHeaderModel.fromJson(
        Map<String, dynamic>.from(data['order'] ?? const {}),
      );

      final list = (data['items'] ?? []) as List;
      items.assignAll(
        list.map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e))),
      );

      driver.value = (data['driver'] == null)
          ? null
          : Map<String, dynamic>.from(data['driver']);

      await _saveCache();
    } catch (e) {
      Get.snackbar('تنبيه', _friendlyError(e));
      header.value = null;
      items.clear();
      driver.value = null;
      await _loadCache();
    } finally {
      loading(false);
    }
  }

  double get itemsTotal {
    if (items.isEmpty) return 0.0;
    return items.fold<double>(
      0.0,
      (sum, it) =>
          sum +
          (it.lineTotalWithExtras > 0 ? it.lineTotalWithExtras : it.lineTotal),
    );
  }

  double get computedGrandTotal {
    final h = header.value;
    if (h == null) return 0.0;
    if (h.grandTotal > 0) return h.grandTotal;
    return itemsTotal + h.deliveryFee;
  }

  String deliveryTypeArabic(String key) {
    switch (key.toLowerCase()) {
      case 'pickup':
        return 'استلام خارجي';
      case 'internal_pickup':
        return 'استلام داخلي';
      case 'delivery':
        return 'توصيل';
      default:
        return key;
    }
  }

  bool _isPickupOrderType(String value) {
    final x = value.toLowerCase().trim();
    return x == 'pickup' ||
        x == 'internal_pickup' ||
        x == 'استلام خارجي' ||
        x == 'استلام داخلي';
  }

  String statusArabicForOrder(String status, String statusOrder) {
    final st = status.toLowerCase().trim();
    final isPickup = _isPickupOrderType(statusOrder);

    if (isPickup) {
      switch (st) {
        case 'pending':
        case 'paid':
          return 'بانتظار القبول';
        case 'processing':
        case 'accepted':
        case 'approved':
        case 'ready_for_driver':
        case 'searching_driver':
        case 'driver_offered':
        case 'assigned':
        case 'driver_to_pickup':
          return 'جاري التحضير';
        case 'ready_pickup':
        case 'pickup_ready':
        case 'ready_for_pickup':
        case 'prepared_pickup':
          return 'الطلب جاهز';
        case 'delivered':
        case 'success':
        case 'complete':
        case 'completed':
          return 'مكتملة';
        case 'rejected':
          return 'مرفوض';
        case 'cancelled':
        case 'canceled':
        case 'failed':
          return 'ملغي';
      }
    }

    return statusArabic(status);
  }

  String statusArabic(String key) {
    switch (key.toLowerCase().trim()) {
      case 'pending':
      case 'paid':
        return 'بانتظار القبول';
      case 'processing':
      case 'accepted':
      case 'approved':
      case 'ready_for_driver':
      case 'searching_driver':
      case 'driver_offered':
        return 'جاري التحضير / جاري البحث عن سائق';
      case 'ready_pickup':
      case 'pickup_ready':
      case 'ready_for_pickup':
      case 'prepared_pickup':
        return 'الطلب جاهز';
      case 'assigned':
      case 'driver_to_pickup':
        return 'جاري التحضير / تم تعيين سائق';
      case 'on_the_way':
      case 'out_for_delivery':
      case 'delivering':
      case 'handover':
        return 'جاري التوصيل';
      case 'delivered':
      case 'success':
      case 'complete':
      case 'completed':
        return 'مكتملة';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
      case 'canceled':
      case 'failed':
        return 'ملغي';
      case 'pickup':
        return 'استلام خارجي';
      case 'internal_pickup':
        return 'استلام داخلي';
      case 'delivery':
        return 'توصيل';
      default:
        return key;
    }
  }

  bool isOnlinePayment(OrderHeaderModel h) => h.paymentMethod == 1;

  String paymentMethodText(OrderHeaderModel h) {
    if (isOnlinePayment(h)) {
      final gw = h.gateway.trim();
      if (gw.isNotEmpty) {
        return 'طريقة الدفع: دفع إلكتروني عبر $gw';
      }
      return 'طريقة الدفع: دفع إلكتروني';
    } else {
      return 'طريقة الدفع: دفع عند الاستلام';
    }
  }

  String onlinePaymentNote(OrderHeaderModel h) {
    final gw = h.gateway.trim();
    final bankText = gw.isNotEmpty ? ' ($gw)' : '';
    return 'تم تنفيذ عملية الدفع إلكترونيًا$bankText. '
        'في حال حدوث أي مشكلة في عملية الخصم سيتم التواصل معك من قبل المطعم.';
  }

  String _friendlyError(Object e) {
    final t = e.toString().toLowerCase();

    if (e is TimeoutException || t.contains('timeout')) {
      return 'انتهت مهلة الاتصال. تأكّد من الإنترنت وحاول مجددًا.';
    }
    if (_looksOffline(t) || e is SocketException) {
      return 'يبدو أنه لا يوجد اتصال بالإنترنت حالياً. تحقّق من الشبكة ثم أعد المحاولة.';
    }
    if (t.contains('format exception') || t.contains('json')) {
      return 'تعذّر قراءة بيانات الطلب. سنحاول تحسين الاتصال، أعد المحاولة لاحقًا.';
    }
    return 'حدث خلل غير متوقّع أثناء تحميل تفاصيل الطلب. حاول لاحقًا.';
  }

  bool _looksOffline(String t) {
    return t.contains('failed host lookup') ||
        t.contains('socketexception') ||
        t.contains('network is unreachable') ||
        t.contains('connection refused') ||
        t.contains('handshake') ||
        t.contains('dns');
  }
}
