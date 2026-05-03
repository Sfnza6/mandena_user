import 'dart:async';
import 'dart:convert';
import 'dart:io'; // ✅ لإلتقاط SocketException
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mandena/core/api_service.dart';
import 'package:mandena/core/env.dart';
import 'package:mandena/core/session.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ للكاش

class UserOrder {
  final int id;
  final double total;
  final String status; // قد تأتي normalized_status
  final String statusOrder; // delivery | pickup | internal_pickup
  final String createdAt;
  final int itemsCount;

  UserOrder({
    required this.id,
    required this.total,
    required this.status,
    required this.statusOrder,
    required this.createdAt,
    required this.itemsCount,
  });

  factory UserOrder.fromJson(Map<String, dynamic> j) => UserOrder(
    id: int.tryParse('${j['id']}') ?? 0,
    total: (j['total'] is num)
        ? (j['total'] as num).toDouble()
        : (double.tryParse('${j['total'] ?? 0}') ?? 0.0),
    status: (j['normalized_status'] ?? j['status'] ?? '').toString(),
    statusOrder:
        (j['status_order'] ??
                j['order_type'] ??
                j['status_order_label'] ??
                'delivery')
            .toString(),
    createdAt: (j['created_at'] ?? '').toString(),
    itemsCount: int.tryParse('${j['items_count'] ?? j['count'] ?? 0}') ?? 0,
  );

  // ✅ لتحويل الطلب إلى JSON للتخزين في الكاش
  Map<String, dynamic> toJson() => {
    'id': id,
    'total': total,
    'status': status,
    'status_order': statusOrder,
    'created_at': createdAt,
    'items_count': itemsCount,
  };
}

class MyOrdersController extends GetxController with WidgetsBindingObserver {
  final _api = ApiService();

  final loading = false.obs;
  final current = <UserOrder>[].obs;
  final history = <UserOrder>[].obs;

  Timer? _poll;
  final pollSeconds = 3;
  bool _cacheLoadedOnce = false;
  bool _isFetching = false;
  final tabIndex = 0.obs; // 0: حاليًا، 1: السجل

  final Map<int, UserOrder> _localSeeds = {};

  // 🆕 فلاغ للحساب التجريبي
  bool _isDemo = false;

  // Sticky لتفادي ومضة الاختفاء بعد الموافقة مباشرة (اختياري)
  final Map<int, DateTime> _stickyUntil = {};
  final Duration _stickyDuration = const Duration(minutes: 10);

  bool _isSticky(int id) {
    final t = _stickyUntil[id];
    if (t == null) return false;
    if (DateTime.now().isAfter(t)) {
      _stickyUntil.remove(id);
      return false;
    }
    return true;
  }

  // مجموعات الحالات
  static const _currentSet = {
    'pending',
    'paid',
    'processing',

    // ✅ طلب الاستلام عندما يصبح جاهز للزبون
    'ready_pickup',

    'ready_for_driver',
    'searching_driver',
    'driver_offered',
    'assigned',
    'driver_to_pickup',
    'on_the_way',
    'out_for_delivery',
    'delivering',
    'handover',
  };

  static const _doneSet = {'success', 'delivered', 'complete', 'completed'};
  static const _cancelSet = {'cancelled', 'canceled', 'rejected', 'failed'};

  String _normalize(String s) {
    final x = s.toLowerCase().trim();

    if ([
      'approved',
      'accepted',
      'accept',
      'preparing',
      'prepare',
      'in_prep',
      'readying',
    ].contains(x)) {
      return 'processing';
    }

    // ✅ حالة طلب الاستلام الجاهز للعميل
    if ([
      'ready_pickup',
      'pickup_ready',
      'ready_for_pickup',
      'prepared_pickup',
    ].contains(x)) {
      return 'ready_pickup';
    }

    if (['ready', 'ready_for_delivery'].contains(x)) return 'ready_for_driver';

    if (['offered', 'driver_offer', 'driver_offered'].contains(x)) {
      return 'driver_offered';
    }

    if (['searching', 'searching_driver', 'find_driver'].contains(x)) {
      return 'searching_driver';
    }

    if (['driver_to_restaurant', 'driver_to_pickup'].contains(x)) {
      return 'driver_to_pickup';
    }

    if (['on_way', 'on_the_way', 'out_for_delivery'].contains(x)) {
      return 'out_for_delivery';
    }

    if (['success', 'complete', 'completed'].contains(x)) return 'delivered';
    if (['canceled', 'cancel'].contains(x)) return 'cancelled';

    return x.isEmpty ? 'pending' : x;
  }

  String _normalizeStatusOrder(String value) {
    final x = value.toLowerCase().trim();
    if (x == 'pickup' || x == 'استلام خارجي') return 'pickup';
    if (x == 'internal_pickup' || x == 'استلام داخلي') return 'internal_pickup';
    return 'delivery';
  }

  bool isPickupOrder(UserOrder o) {
    final t = _normalizeStatusOrder(o.statusOrder);
    return t == 'pickup' || t == 'internal_pickup';
  }

  void seedOrder({
    required int orderId,
    double total = 0,
    int itemsCount = 0,
    String status = 'pending',
    String statusOrder = 'delivery',
    String? createdAt,
  }) {
    if (orderId <= 0) return;

    final order = UserOrder(
      id: orderId,
      total: total,
      status: _normalize(status),
      statusOrder: _normalizeStatusOrder(statusOrder),
      createdAt: (createdAt == null || createdAt.trim().isEmpty)
          ? DateTime.now().toIso8601String()
          : createdAt,
      itemsCount: itemsCount,
    );

    _localSeeds[orderId] = order;
    _stickyUntil[orderId] = DateTime.now().add(_stickyDuration);

    current.removeWhere((o) => o.id == orderId);
    history.removeWhere((o) => o.id == orderId);
    current.insert(0, order);
    current.refresh();
  }

  void _mergeLocalSeeds(List<UserOrder> cur, List<UserOrder> his) {
    final now = DateTime.now();
    final expired = <int>[];

    _localSeeds.forEach((id, order) {
      final until = _stickyUntil[id];
      if (until == null || now.isAfter(until)) {
        expired.add(id);
        return;
      }

      // لا ترجع الطلب للقائمة الحالية لو السيرفر رجّعه في السجل/المكتملة.
      if (!cur.any((x) => x.id == id) && !his.any((x) => x.id == id)) {
        cur.add(order);
      }
    });

    for (final id in expired) {
      _localSeeds.remove(id);
      _stickyUntil.remove(id);
    }
  }

  // =================== كاش الطلبات ===================
  String _cacheKeyFor(int uid) => 'my_orders_uid_$uid';

  Future<void> _saveCache(int uid) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final data = {
        'current': current.map((o) => o.toJson()).toList(),
        'history': history.map((o) => o.toJson()).toList(),
      };
      await sp.setString(_cacheKeyFor(uid), jsonEncode(data));
    } catch (_) {
      // نتجاهل بصمت
    }
  }

  Future<void> _loadCache(int uid) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_cacheKeyFor(uid));
      if (s == null || s.isEmpty) return;

      final data = jsonDecode(s);
      if (data is! Map) return;

      final curList = (data['current'] as List?) ?? const [];
      final hisList = (data['history'] as List?) ?? const [];

      final cur = curList
          .map<UserOrder>(
            (e) => UserOrder.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      final his = hisList
          .map<UserOrder>(
            (e) => UserOrder.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      current.assignAll(cur);
      history.assignAll(his);
    } catch (_) {
      // نتجاهل
    }
  }
  // ===================================================

  @override
  void onInit() {
    super.onInit();
    final wantedTab = Get.parameters['tab'];
    if (wantedTab == 'history') tabIndex.value = 1;
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    WidgetsBinding.instance.addObserver(this);

    // استلام orderId للتثبيت والظهور الفوري بعد إنشاء الطلب
    final hiArg = Get.arguments is Map ? (Get.arguments as Map) : null;
    final argId = hiArg != null
        ? int.tryParse(
            '${hiArg['highlightOrderId'] ?? hiArg['order_id'] ?? ''}',
          )
        : null;

    if (argId != null && argId > 0) {
      seedOrder(
        orderId: argId,
        total:
            double.tryParse('${hiArg == null ? 0 : (hiArg['total'] ?? 0)}') ??
            0,
        itemsCount:
            int.tryParse(
              '${hiArg == null ? 0 : (hiArg['items_count'] ?? 0)}',
            ) ??
            0,
        status: '${hiArg == null ? 'pending' : (hiArg['status'] ?? 'pending')}',
        statusOrder:
            '${hiArg == null ? 'delivery' : (hiArg['status_order'] ?? 'delivery')}',
        createdAt:
            '${hiArg == null ? DateTime.now().toIso8601String() : (hiArg['created_at'] ?? DateTime.now().toIso8601String())}',
      );
    }

    await fetch(silent: argId != null);

    _poll = Timer.periodic(
      Duration(seconds: pollSeconds),
      (_) => fetch(silent: true, forceNetwork: true),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetch(silent: true, forceNetwork: true);
    }
  }

  @override
  void onClose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// يحوّل أي رد إلى List<Map>
  List<Map<String, dynamic>> _coerceList(dynamic res) {
    try {
      dynamic root = res;

      if (root is String) {
        root = jsonDecode(root);
      }

      if (root is Map && root['orders'] is List) {
        return (root['orders'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (root is Map && root['data'] is List) {
        return (root['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (root is List) {
        return root.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}

    return const <Map<String, dynamic>>[];
  }

  Future<void> fetch({bool silent = false, bool forceNetwork = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    int? uid;

    try {
      if (!silent) loading(true);

      uid = await Session.userId();
      _isDemo = await Session.isDemo(); // 🆕 قراءة حالة الحساب التجريبي

      // 🆕 لو الحساب تجريبي أو user_id = 0 → لا نعرض طلبات ولا كاش
      if (_isDemo || uid == 0) {
        current.clear();
        history.clear();
        _stickyUntil.clear();

        if (!silent) {
          Get.snackbar(
            'حساب تجريبي',
            'لا يمكن عرض الطلبات لحساب تجريبي.\nسجّل الدخول بحساب حقيقي لعرض طلباتك.',
            snackPosition: SnackPosition.BOTTOM,
          );
        }

        return;
      }

      // ✅ الكاش يُحمّل مرة واحدة فقط عند أول دخول، وليس مع كل Polling.
      // سابقاً كان الكاش القديم يرجّع الطلب للحالي حتى بعد اكتماله من السيرفر.
      if (!_cacheLoadedOnce &&
          !forceNetwork &&
          current.isEmpty &&
          history.isEmpty) {
        await _loadCache(uid!);
        _cacheLoadedOnce = true;
      }

      // أهم نقطة: تأكّد Env.ordersList = 'get_orders.php'
      final res = await _api.get(
        Env.ordersList,
        params: {
          'user_id': '$uid',
          'status': 'all', // رجّع كل الحالات ونحن نقسّم محليًا
          't': '${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      // DEBUG
      try {
        final pretty = const JsonEncoder.withIndent(
          '  ',
        ).convert(res is String ? jsonDecode(res) : res);
        Get.log('MyOrders.fetch raw: $pretty');
      } catch (_) {
        Get.log('MyOrders.fetch raw: $res');
      }

      final list = _coerceList(res);
      final serverIds = <int>{};

      final cur = <UserOrder>[];
      final his = <UserOrder>[];

      for (final m in list) {
        final o = UserOrder.fromJson(m);
        final st = _normalize(o.status);
        if (o.id > 0) serverIds.add(o.id);

        if (_currentSet.contains(st)) {
          cur.add(
            UserOrder(
              id: o.id,
              total: o.total,
              status: st,
              statusOrder: _normalizeStatusOrder(o.statusOrder),
              createdAt: o.createdAt,
              itemsCount: o.itemsCount,
            ),
          );
        } else if (_doneSet.contains(st) || _cancelSet.contains(st)) {
          his.add(
            UserOrder(
              id: o.id,
              total: o.total,
              status: st,
              statusOrder: _normalizeStatusOrder(o.statusOrder),
              createdAt: o.createdAt,
              itemsCount: o.itemsCount,
            ),
          );
        } else {
          // لو حالة غير معروفة، خلّيها في current مؤقتًا
          cur.add(
            UserOrder(
              id: o.id,
              total: o.total,
              status: st,
              statusOrder: _normalizeStatusOrder(o.statusOrder),
              createdAt: o.createdAt,
              itemsCount: o.itemsCount,
            ),
          );
        }
      }

      // أي طلب رجع من السيرفر لا نعود نعتمد على نسخته المحلية القديمة.
      for (final id in serverIds) {
        _localSeeds.remove(id);
        _stickyUntil.remove(id);
      }

      // دمج المثبتة محليًا فقط لو السيرفر لم يرجعها نهائيًا، ولم تصبح موجودة في السجل.
      final keep = <UserOrder>[];
      for (final o in current) {
        if (_isSticky(o.id) &&
            !serverIds.contains(o.id) &&
            !cur.any((x) => x.id == o.id) &&
            !his.any((x) => x.id == o.id)) {
          keep.add(o);
        }
      }

      cur.addAll(keep);
      _mergeLocalSeeds(cur, his);

      cur.sort((a, b) => b.id.compareTo(a.id));
      his.sort((a, b) => b.id.compareTo(a.id));

      current.assignAll(cur);
      history.assignAll(his);

      // ✅ حفظ النتيجة الجديدة في الكاش
      await _saveCache(uid!);
    } catch (e) {
      // عند الخطأ نحاول نعرض الكاش (لو موجود)
      if (uid != null && !_isDemo && uid != 0) {
        await _loadCache(uid);
      }

      if (!silent) {
        Get.snackbar(
          'تنبيه',
          _niceError(e),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      _isFetching = false;
      if (!silent) loading(false);
    }
  }

  String formatDate(String createdAt) {
    try {
      final dt =
          DateTime.tryParse(createdAt.replaceAll('/', '-')) ?? DateTime.now();
      return DateFormat('d MMM, HH:mm', 'en').format(dt).toUpperCase();
    } catch (_) {
      return createdAt;
    }
  }

  (String, Color) statusLabel(UserOrder o) {
    final st = _normalize(o.status);

    if (_doneSet.contains(st) || st == 'delivered') {
      return ('✅ مكتملة', const Color(0xFF1FA85B));
    }

    if (_cancelSet.contains(st)) {
      if (st == 'rejected') return ('مرفوض', const Color(0xFFE53935));
      return ('ملغي', const Color(0xFFE53935));
    }

    switch (st) {
      case 'pending':
      case 'paid':
        return ('⏳ بانتظار القبول', const Color(0xFFFB8C00));

      case 'processing':
      case 'ready_for_driver':
      case 'searching_driver':
      case 'driver_offered':
        if (isPickupOrder(o)) {
          return ('🍳 جاري التحضير', const Color(0xFF7B1FA2));
        }
        return (
          '🍳 جاري التحضير / جاري البحث عن سائق',
          const Color(0xFF7B1FA2),
        );

      // ✅ طلب استلام من المطعم جاهز
      case 'ready_pickup':
        return ('✅ الطلب جاهز', const Color(0xFF1FA85B));

      case 'assigned':
      case 'driver_to_pickup':
        if (isPickupOrder(o)) {
          return ('🍳 جاري التحضير', const Color(0xFF7B1FA2));
        }
        return ('🚗 جاري التحضير / تم تعيين سائق', const Color(0xFF00897B));

      case 'on_the_way':
      case 'out_for_delivery':
      case 'delivering':
      case 'handover':
        return ('🏃 جاري التوصيل', const Color(0xFFE65100));

      default:
        return (st, const Color(0xFF757575));
    }
  }

  // ================== إضافات بسيطة لرسائل ودّية ==================

  String _niceError(Object e) {
    final t = e.toString().toLowerCase();

    // مهلة انتهت
    if (e is TimeoutException || t.contains('timeout')) {
      return 'انتهت مهلة الاتصال. تأكّد من الإنترنت وحاول من جديد.';
    }

    // عدم وجود إنترنت / DNS / Socket
    if (_looksLikeOffline(t) || e is SocketException) {
      return 'لا يوجد اتصال بالإنترنت حالياً. رجاءً تحقّق من الشبكة ثم أعد المحاولة.';
    }

    // أخطاء عامة/غير معروفة
    return 'حدث خلل أثناء جلب الطلبات. حاول لاحقاً.';
  }

  bool _looksLikeOffline(String t) {
    return t.contains('failed host lookup') ||
        t.contains('socketexception') ||
        t.contains('network is unreachable') ||
        t.contains('connection refused') ||
        t.contains('handshake') ||
        t.contains('dns');
  }
}
