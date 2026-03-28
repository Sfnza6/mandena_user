import 'dart:async';
import 'dart:convert';
import 'dart:io'; // ✅ لتمييز أخطاء الشبكة (SocketException)
import 'package:get/get.dart';
import 'package:mandena/core/api_service.dart';
import 'package:mandena/core/env.dart';
import 'package:mandena/core/session.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ للكاش

/// موديل إضافة (صوص/جبنة...) لعنصر داخل الطلب
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

  // ✅ للكاش
  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'price': price,
    'line_total': lineTotal,
  };
}

/// موديل لمكوّن (مضاف/محذوف)
class OrderComponentModel {
  final int id;
  final String name;
  final int quantity;
  final double price; // للمحذوف عادة 0

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

  // ✅ للكاش
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'price': price,
  };
}

/// عنصر (وجبة) داخل الطلب
class OrderItemModel {
  final int orderItemId;
  final int itemId;
  final String name;
  final int quantity;
  final double price;
  final double lineTotal;
  final double lineTotalWithExtras;
  final List<OrderExtraModel> extras;

  /// المكونات (المضافة تُحتسب، المحذوفة بلا سعر)
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
    // أولاً: نقرأ معرّفات هذا السطر كي نستخدمها في الفلترة
    final orderItemId = int.tryParse('${j['order_item_id']}') ?? 0;
    final itemId = int.tryParse('${j['item_id']}') ?? 0;

    // مساعد لتحويل أي قيمة إلى List (حتى لو جاءت كنص JSON)
    List asList(v) {
      if (v is List) return v;
      if (v is String && v.trim().startsWith('[')) {
        try {
          return jsonDecode(v) as List;
        } catch (_) {}
      }
      return const [];
    }

    // NEW: اختيار قائمة من عدّة مفاتيح محتملة
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

    // دالة مطابقة عنصر مُدخل مع هذا السطر
    bool belongsToThisItem(Map<String, dynamic> m) {
      final oi =
          int.tryParse('${m['order_item_id'] ?? m['oi_id'] ?? ''}') ?? -1;
      final ii = int.tryParse('${m['item_id'] ?? m['itemId'] ?? ''}') ?? -1;
      if (oi > 0) return oi == orderItemId;
      if (ii > 0) return ii == itemId;
      // لو ما في مؤشّر، نعتبره يخص هذا السطر فقط إذا لم تُرسل قوائم عامة
      return true;
    }

    // الإضافات
    final extrasList = (j['extras'] is List)
        ? (j['extras'] as List)
              .map(
                (e) => OrderExtraModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <OrderExtraModel>[];

    // NEW: المكونات — ندعم مفاتيح متعددة لكل نوع
    final rawAdd = pickList(j, const [
      'components_add',
      'componentsAdd',
    ]).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final rawRem = pickList(j, const [
      'components_rem',
      'componentsRem',
      'components_removed',
    ]).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // فلترة حسب order_item_id / item_id
    final compsAdd = rawAdd
        .where(belongsToThisItem)
        .map((e) => OrderComponentModel.fromJson(e))
        .toList();

    final compsRem = rawRem
        .where(belongsToThisItem)
        .map((e) => OrderComponentModel.fromJson(e))
        .toList();

    // مجموع احتياطي لو line_total_with_extras جاء صفر
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

  // ✅ للكاش
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

/// رأس الطلب
class OrderHeaderModel {
  final int id;
  final int userId;
  final int driverId;
  final String status; // pending / processing / assigned...
  final String statusOrder; // pickup / delivery
  final double total; // قد يكون 0 من السيرفر
  final String address;
  final String createdAt;
  final double deliveryFee;
  final double grandTotal; // (extras + delivery) إن أرسله السيرفر

  /// ✅ نوع طريقة الدفع (0 = عند الاستلام، 1 = أونلاين ...)
  final int paymentMethod;

  /// ✅ اسم / مفتاح البوابة أو المصرف (مثلاً: صحاري باي)
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
    statusOrder: (j['status_order'] ?? '').toString(),
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

  // ✅ للكاش
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
  final driver = Rxn<Map<String, dynamic>>(); // {id,name,phone}

  late int orderId;
  int? userId;

  // ========= كاش تفاصيل الطلب =========
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
    } catch (_) {
      // تجاهل
    }
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
    } catch (_) {
      // تجاهل
    }
  }
  // =====================================

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    // ✅ دعم مفاتيح متعددة
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
    // ✅ حاول تعرض آخر نسخة من الكاش أولاً
    _loadCache();
    fetch();
  }

  Future<void> fetch() async {
    if (orderId <= 0) {
      // ✅ رسالة ودّية بدلاً من تقنية
      Get.snackbar('تنبيه', 'رقم الطلب غير صحيح. حاول فتح الطلب من جديد.');
      return;
    }
    try {
      loading(true);

      // تحقّق ملكية (اختياري)
      userId ??= await Session.userId();

      final res = await _api.get(
        Env.orderDetails,
        params: {
          'order_id': '$orderId',
          if (userId != null) 'user_id': '$userId',
          // كسر كاش
          't': '${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final root = res is String ? jsonDecode(res) : res;
      if ((root['status'] ?? '').toString().toLowerCase() != 'success') {
        // ✅ رسالة احترافية عند فشل الاستجابة (مع رسالة السيرفر إن وُجدت)
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
        // لو فشل، حاول تعيد عرض الكاش (إن وجد)
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

      // ✅ حفظ تفاصيل الطلب في الكاش
      await _saveCache();
    } catch (e) {
      // ✅ رسالة ودّية بدل التقنية
      Get.snackbar('تنبيه', _friendlyError(e));
      header.value = null;
      items.clear();
      driver.value = null;
      // وحاول تعرض آخر نسخة مخزّنة
      await _loadCache();
    } finally {
      loading(false);
    }
  }

  /// مجموع أصناف الطلب شامل الإضافات + المكونات المُضافة
  double get itemsTotal {
    if (items.isEmpty) return 0.0;
    return items.fold<double>(
      0.0,
      (sum, it) =>
          sum +
          (it.lineTotalWithExtras > 0 ? it.lineTotalWithExtras : it.lineTotal),
    );
  }

  /// الإجمالي النهائي (إن لم يرسله السيرفر)
  double get computedGrandTotal {
    final h = header.value;
    if (h == null) return 0.0;
    if (h.grandTotal > 0) return h.grandTotal;
    return itemsTotal + h.deliveryFee;
  }

  String deliveryTypeArabic(String key) {
    switch (key.toLowerCase()) {
      case 'pickup':
        return 'استلام';
      case 'delivery':
        return 'توصيل';
      default:
        return key;
    }
  }

  // ========= معلومات الدفع ===========

  /// هل الدفع أونلاين؟
  bool isOnlinePayment(OrderHeaderModel h) => h.paymentMethod == 1;

  /// نص طريقة الدفع + اسم المصرف
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

  /// رسالة توضيح إضافية عند الدفع أونلاين
  String onlinePaymentNote(OrderHeaderModel h) {
    final gw = h.gateway.trim();
    final bankText = gw.isNotEmpty ? ' ($gw)' : '';
    return 'تم تنفيذ عملية الدفع إلكترونيًا$bankText. '
        'في حال حدوث أي مشكلة في عملية الخصم سيتم التواصل معك من قبل المطعم.';
  }

  // ================== رسائل ودّية للأخطاء (بدون تغيير المنطق) ==================
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
