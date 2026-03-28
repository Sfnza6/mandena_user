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
  final String createdAt;
  final int itemsCount;

  UserOrder({
    required this.id,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.itemsCount,
  });

  factory UserOrder.fromJson(Map<String, dynamic> j) => UserOrder(
    id: int.tryParse('${j['id']}') ?? 0,
    total: (j['total'] is num)
        ? (j['total'] as num).toDouble()
        : (double.tryParse('${j['total'] ?? 0}') ?? 0.0),
    status: (j['normalized_status'] ?? j['status'] ?? '').toString(),
    createdAt: (j['created_at'] ?? '').toString(),
    itemsCount: int.tryParse('${j['items_count'] ?? j['count'] ?? 0}') ?? 0,
  );

  // ✅ لتحويل الطلب إلى JSON للتخزين في الكاش
  Map<String, dynamic> toJson() => {
    'id': id,
    'total': total,
    'status': status,
    'created_at': createdAt,
    'items_count': itemsCount,
  };
}

class MyOrdersController extends GetxController {
  final _api = ApiService();

  final loading = false.obs;
  final current = <UserOrder>[].obs;
  final history = <UserOrder>[].obs;

  Timer? _poll;
  final pollSeconds = 8;
  final tabIndex = 0.obs; // 0: حاليًا، 1: السجل

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
    'processing',
    'assigned',
    'delivering',
    'out_for_delivery',
    'ready',
    'paid', // في حال كانت موجودة من طلبات قديمة
  };
  static const _doneSet = {'success', 'delivered', 'complete', 'completed'};
  static const _cancelSet = {'cancelled', 'canceled', 'rejected', 'failed'};

  String _normalize(String s) {
    final x = s.toLowerCase().trim();
    if ([
      'approved',
      'accepted',
      'preparing',
      'in_prep',
      'readying',
    ].contains(x)) {
      return 'processing';
    }
    return x;
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
    // استلام orderId للتثبيت (اختياري)
    final hiArg = Get.arguments is Map ? (Get.arguments as Map) : null;
    final argId = hiArg != null
        ? int.tryParse('${hiArg['highlightOrderId'] ?? ''}')
        : null;
    if (argId != null) {
      _stickyUntil[argId] = DateTime.now().add(_stickyDuration);
    }

    await fetch();
    _poll = Timer.periodic(
      Duration(seconds: pollSeconds),
      (_) => fetch(silent: true),
    );
  }

  @override
  void onClose() {
    _poll?.cancel();
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

  Future<void> fetch({bool silent = false}) async {
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

      // ✅ أولاً: حمّل آخر نسخة من الكاش (تعطي إحساس سرعة)
      await _loadCache(uid!);

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

      final cur = <UserOrder>[];
      final his = <UserOrder>[];

      for (final m in list) {
        final o = UserOrder.fromJson(m);
        final st = _normalize(o.status);

        if (_currentSet.contains(st)) {
          cur.add(
            UserOrder(
              id: o.id,
              total: o.total,
              status: st,
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
              createdAt: o.createdAt,
              itemsCount: o.itemsCount,
            ),
          );
        }
      }

      // دمج المثبتة محليًا لو السيرفر ما رجّعها لحظيًا
      final keep = <UserOrder>[];
      for (final o in current) {
        if (_isSticky(o.id) && !cur.any((x) => x.id == o.id)) {
          keep.add(o);
        }
      }
      cur.addAll(keep);

      cur.sort((a, b) => b.id.compareTo(a.id));
      his.sort((a, b) => b.id.compareTo(a.id));
      current.assignAll(cur);
      history.assignAll(his);

      // ✅ حفظ النتيجة الجديدة في الكاش
      await _saveCache(uid);
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
    if (_doneSet.contains(st)) return ('مكتمل', const Color(0xFF1FA85B));
    if (_cancelSet.contains(st)) return ('غير مكتمل', const Color(0xFFE53935));
    switch (st) {
      case 'pending':
      case 'paid': // نعرض الطلب المدفوع (لو وجد) كـ معلّق أيضاً
        return ('معلّق', const Color(0xFFFB8C00));
      case 'processing':
        return ('قيد التحضير', const Color(0xFF1976D2));
      case 'assigned':
      case 'delivering':
      case 'out_for_delivery':
        return ('جاري التوصيل', const Color(0xFF00897B));
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
