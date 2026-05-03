import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:http/http.dart' as http;
import 'package:mandena/app_routes.dart';
import 'package:mandena/core/api_service.dart';
import 'package:mandena/core/session.dart';
import 'package:mandena/data/models/address.dart';
import 'package:mandena/modules/cart/cart_controller.dart';
import 'package:mandena/modules/orders/my_orders_controller.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ للكاش

class CheckoutController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final addressCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  /// 0 = كاش, 1 = بطاقة/أونلاين
  final payment = 0.obs;

  /// 'delivery' | 'pickup' | 'internal_pickup'
  final statusOrder = 'delivery'.obs;

  /// cash | yesser | masrafy | sahari | bank | ...
  final gatewayKey = 'cash'.obs;

  final destLat = RxnDouble();
  final destLng = RxnDouble();

  final pickupLat = RxnDouble();
  final pickupLng = RxnDouble();

  final isPlacing = false.obs;

  final _api = ApiService();
  late final CartController cart;

  int? _userId;

  // ───────── رسائل Snackbar ─────────

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
    if (_lastSnackAt != null &&
        now.difference(_lastSnackAt!) < _snackThrottle) {
      return;
    }
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
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              msg,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontSize: 13.5,
                height: 1.3,
              ),
            ),
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      duration: Duration(seconds: seconds),
    );
  }

  void _showUserError(
    String msg, {
    String title = 'تعذّر إتمام العملية',
    VoidCallback? onRetry,
  }) {
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
    return e.toString();
  }

  // ───────── كاش لمسودة شاشة الـ Checkout ─────────

  DateTime? _lastCacheSaveAt;
  static const _cacheThrottle = Duration(seconds: 2);

  String get _cacheKey => 'checkout_draft_v1_user_${_userId ?? 0}';

  Future<void> _saveCheckoutToCache() async {
    // لو ما فيش يوزر حالي، مالهاش معنى نخزن
    if (_userId == null || _userId == 0) return;

    final now = DateTime.now();
    if (_lastCacheSaveAt != null &&
        now.difference(_lastCacheSaveAt!) < _cacheThrottle) {
      return;
    }
    _lastCacheSaveAt = now;

    try {
      final sp = await SharedPreferences.getInstance();
      final data = {
        'address': addressCtrl.text,
        'note': noteCtrl.text,
        'payment': payment.value,
        'statusOrder': statusOrder.value,
        'gatewayKey': gatewayKey.value,
        'destLat': destLat.value,
        'destLng': destLng.value,
        'pickupLat': pickupLat.value,
        'pickupLng': pickupLng.value,
      };
      await sp.setString(_cacheKey, jsonEncode(data));
    } catch (_) {
      // نتجاهل أي خطأ في الكاش بصمت
    }
  }

  Future<void> _loadCheckoutFromCache() async {
    if (_userId == null || _userId == 0) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_cacheKey);
      if (s == null || s.isEmpty) return;

      final data = jsonDecode(s);
      if (data is! Map) return;

      // ما نطيحش فوق عنوان جاينا من السلة أو الـ Session
      final cachedAddress = (data['address'] ?? '').toString();
      if (addressCtrl.text.trim().isEmpty && cachedAddress.isNotEmpty) {
        addressCtrl.text = cachedAddress;
      }

      final cachedNote = (data['note'] ?? '').toString();
      if (cachedNote.isNotEmpty && noteCtrl.text.trim().isEmpty) {
        noteCtrl.text = cachedNote;
      }

      final pay = data['payment'];
      final payInt = (pay is num) ? pay.toInt() : int.tryParse('${pay ?? ''}');
      if (payInt != null && (payInt == 0 || payInt == 1)) {
        payment.value = payInt;
      }

      final so = data['statusOrder']?.toString();
      if (so == 'delivery' || so == 'pickup' || so == 'internal_pickup') {
        statusOrder.value = so!;
      }

      final gw = data['gatewayKey']?.toString();
      if (gw != null && gw.isNotEmpty) {
        gatewayKey.value = gw;
      }

      final dLat = data['destLat'];
      final dLng = data['destLng'];
      if (destLat.value == null && dLat is num) {
        destLat.value = dLat.toDouble();
      }
      if (destLng.value == null && dLng is num) {
        destLng.value = dLng.toDouble();
      }

      final pLat = data['pickupLat'];
      final pLng = data['pickupLng'];
      if (pickupLat.value == null && pLat is num) {
        pickupLat.value = pLat.toDouble();
      }
      if (pickupLng.value == null && pLng is num) {
        pickupLng.value = pLng.toDouble();
      }
    } catch (_) {
      // تجاهل بصمت
    }
  }

  Future<void> _clearCheckoutCache() async {
    if (_userId == null || _userId == 0) return;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_cacheKey);
    } catch (_) {
      // تجاهل بصمت
    }
  }

  // ────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    cart = Get.find<CartController>();

    // 👇 مراقبة تغيير نوع الطلب (توصيل / استلام خارجي / استلام داخلي)
    ever<String>(statusOrder, (mode) async {
      if (mode == 'pickup' || mode == 'internal_pickup') {
        _applyPickupDeliveryFee();
      } else if (mode == 'delivery') {
        await _restoreDeliveryFee();
      }
      _saveCheckoutToCache(); // ✅ نحفظ التغيير
    });

    // 👇 لو تغيّر نوع الدفع (كاش/أونلاين) نخزّنه
    ever<int>(payment, (_) {
      _saveCheckoutToCache();
    });

    // 👇 حفظ المسودة عند تعديل النصوص
    addressCtrl.addListener(() {
      _saveCheckoutToCache();
    });
    noteCtrl.addListener(() {
      _saveCheckoutToCache();
    });
  }

  @override
  Future<void> onReady() async {
    super.onReady();
    _userId = await Session.userId();

    // عنوان مخزّن في جلسة المستخدم (لو عندك حقل address في جدول users)
    final u = await Session.readLoggedIn();
    if (u != null) {
      final savedAddress = (u['address'] ?? '').toString();
      if (savedAddress.isNotEmpty) {
        addressCtrl.text = savedAddress;
      }
    }

    // 👇 هنا نستخدم العنوان الافتراضي القادم من السلة (بدون حذف أي منطق آخر)
    final a = cart.selectedAddress.value;
    if (a != null) {
      _applySelectedAddress(a);
    } else {
      // لو حفظت فقط الاسم كنص في CartController.selectedAddressName
      try {
        // نحاول قراءة الاسم الافتراضي بدون كسر التطبيق لو الفيلد مش موجود
        final dynamic maybeRx = (cart as dynamic).selectedAddressName;
        if (maybeRx != null) {
          final String name = (maybeRx.value as String?)?.trim() ?? '';
          if (name.isNotEmpty) {
            addressCtrl.text = name;
          }
        }
      } catch (_) {
        // تجاهل بصمت لو ما فيه selectedAddressName
      }
    }

    // 👈 في الأخير، نحاول نرجّع مسودة قديمة لو موجودة
    await _loadCheckoutFromCache();
  }

  String? req(String? v, String label) {
    if (v == null || v.trim().isEmpty) return 'أدخل $label';
    return null;
  }

  double _asDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  List<Map<String, dynamic>> _serializeCartItems() {
    final list = <Map<String, dynamic>>[];

    for (final raw in cart.cart) {
      final m = Map<String, dynamic>.from(raw as Map);

      final int itemId =
          int.tryParse('${m['item_id'] ?? m['id'] ?? m['itemId'] ?? ''}') ?? 0;
      final String title = (m['title'] ?? m['name'] ?? '').toString();
      final int quantity =
          int.tryParse('${m['quantity'] ?? m['qty'] ?? 1}') ?? 1;

      double unitPrice = _asDouble(m['unit_price'], _asDouble(m['price'], 0.0));

      final String imageUrl = (m['image_url'] ?? m['image'] ?? '').toString();

      final additionsRaw =
          (m['additions'] ?? m['extras'] ?? []) as List? ?? const [];
      final removalsRaw = (m['removals'] ?? []) as List? ?? const [];

      final additions = additionsRaw.map<Map<String, dynamic>>((e) {
        final mm = Map<String, dynamic>.from(e as Map);
        return {
          'id': mm['id'],
          'name': (mm['name'] ?? '').toString(),
          'price': _asDouble(mm['price'], 0.0),
        };
      }).toList();

      final removals = removalsRaw.map<Map<String, dynamic>>((e) {
        final mm = Map<String, dynamic>.from(e as Map);
        return {'id': mm['id'], 'name': (mm['name'] ?? '').toString()};
      }).toList();

      list.add({
        'item_id': itemId,
        'title': title,
        'quantity': quantity,
        'unit_price': unitPrice,
        'image_url': imageUrl,
        'additions': additions,
        'removals': removals,
      });
    }

    return list;
  }

  double get _total {
    try {
      final t = cart.total;
      // ignore: unnecessary_type_check
      if (t is num) return t.toDouble();
    } catch (_) {}

    double sum = 0.0;
    for (final raw in cart.cart) {
      final m = Map<String, dynamic>.from(raw as Map);
      final qty = int.tryParse('${m['quantity'] ?? m['qty'] ?? 1}') ?? 1;
      final unit = _asDouble(m['unit_price'], _asDouble(m['price'], 0.0));
      sum += unit * qty;
    }
    return sum;
  }

  Future<void> pickAddress() async {
    final result = await Get.toNamed(
      AppRoutes.addresses,
      arguments: {'pickMode': true},
    );
    if (result != null && result is Address) {
      _applySelectedAddress(result);
      try {
        cart.setSelectedAddress(result);
      } catch (_) {}
    }
  }

  void _applySelectedAddress(Address a) {
    addressCtrl.text = a.label;
    destLat.value = a.lat;
    destLng.value = a.lng;
    refreshDeliveryFee();
    _saveCheckoutToCache(); // ✅ حفظ العنوان المختار
  }

  // 👇 لما تختار استلام خارجي أو استلام داخلي → رسوم التوصيل = 0 فقط
  void _applyPickupDeliveryFee() {
    try {
      cart.delivery.value = 0;
      cart.subtotal.refresh();
    } catch (_) {}
  }

  // 👇 لما ترجع لتوصيل → يرجع يحسب الرسوم من API (لو العنوان موجود)
  Future<void> _restoreDeliveryFee() async {
    await refreshDeliveryFee();
  }

  Future<void> refreshDeliveryFee() async {
    final lat = destLat.value;
    final lng = destLng.value;
    if (lat == null || lng == null) return;

    try {
      final r = await _api.get(
        'delivery/calc_delivery.php',
        params: {
          'dest_lat': lat.toString(),
          'dest_lng': lng.toString(),
          if (pickupLat.value != null)
            'pickup_lat': pickupLat.value!.toString(),
          if (pickupLng.value != null)
            'pickup_lng': pickupLng.value!.toString(),
        },
      );

      if (r is Map && r['ok'] == true) {
        final fee = (r['delivery_fee'] as num).toDouble();
        cart.delivery.value = fee;
        cart.subtotal.refresh();
      } else {
        if (r is Map && r['message'] != null) {
          if (kDebugMode) {
            debugPrint('calc_delivery message: ${r['message']}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('refreshDeliveryFee error: $e');
      _showInfo('تعذّر حساب رسوم التوصيل حالياً.\nسنحاول مرة أخرى لاحقاً.');
    }
  }

  // ───────── إعدادات بوابة مسارات (MITF/Yusor) ─────────

  /// ✅ Production الحقيقي عندك يشتغل عبر Proxy على evoranta.ly (HTTPS + mTLS من السيرفر)
  static const String _mitfBaseDirect =
      'https://yussor-pay-online.mitflink.ly:40120/YusorOnline'; // (موجود كمرجع فقط)
  static const String _mitfBaseProxy = 'https://evoranta.ly/payments/mitf';

  /// ✅ في الإنتاج: لازم يكون true (لأن Flutter ما يقدرش يعمل mTLS بالشهادة اللي عند السيرفر)
  static const bool _viaProxy = true;

  /// ⚠️ كانت بيانات اختبار — نخليها موجودة “بدون حذف” لكن ما نستخدمها في Production
  // ignore: unused_field
  static const _merchantCreds = {
    'userId': 0,
    'pin': '',
    'providerId': 0,
    'authUserType': 0,
  };

  /// ⚠️ كانت بيانات اختبار — نخليها موجودة “بدون حذف” لكن ما نستخدمها في Production
  // ignore: unused_field
  static const _posCreds = {
    'userId': 0,
    'pin': '',
    'providerId': 0,
    'authUserType': 1,
  };

  /// ✅ في الإنتاج: ما فيش رقم افتراضي — المستخدم يدخل رقم البطاقة
  static const String _testIdentityCard = '';

  /// ✅ Production: السيرفر هو اللي يقرأ (MITF_USER_ID / MITF_PIN / MITF_PROVIDER) من ENV
  /// لذلك Flutter يرسل Body فارغ أو بسيط.
  Map<String, dynamic> get _activeCreds {
    // نرجّع Map فاضي لتفعيل Signin من السيرفر باستخدام ENV
    return <String, dynamic>{};
  }

  void setGateway(String key) {
    gatewayKey.value = key;
    _saveCheckoutToCache(); // ✅ حفظ خيار البوابة
  }

  String _endpoint(String apiName) {
    if (_viaProxy) {
      switch (apiName) {
        case 'Signin':
          return '$_mitfBaseProxy/signin.php';
        case 'OpenSession':
          return '$_mitfBaseProxy/open_session.php';
        case 'CompleteSession':
          return '$_mitfBaseProxy/complete_session.php';
        default:
          return '$_mitfBaseProxy/$apiName';
      }
    } else {
      return '$_mitfBaseDirect/api/OnlinePaymentServices/$apiName';
    }
  }

  bool _isOk(Map res) {
    return res['ok'] == true ||
        res['success'] == true ||
        res['status'] == 'ok' ||
        res['status'] == 'success' ||
        res['type'] == 1;
  }

  String _firstMessage(Map res, {String fallback = 'عملية مكتملة'}) {
    if (res['messages'] is List && (res['messages'] as List).isNotEmpty) {
      return '${(res['messages'] as List).first}';
    }
    if (res['message'] != null) return '${res['message']}';
    if (res['error'] != null) return '${res['error']}';
    return fallback;
  }

  Map<String, dynamic> _contentAsMap(Map res) {
    final c = res['content'];
    if (c is Map) return Map<String, dynamic>.from(c);
    if (c is String && c.trim().isNotEmpty) {
      try {
        final m = jsonDecode(c);
        if (m is Map) return Map<String, dynamic>.from(m);
      } catch (_) {}
      return {'value': c};
    }
    return <String, dynamic>{};
  }

  String? _extractToken(Map<String, dynamic> content) {
    final direct =
        content['value'] ?? content['token'] ?? content['access_token'];
    if (direct != null) return direct.toString();

    final inner = content['content'];
    if (inner is Map) {
      final innerMap = inner.cast<String, dynamic>();
      final nested =
          innerMap['value'] ?? innerMap['token'] ?? innerMap['access_token'];
      if (nested != null) return nested.toString();
    }

    return null;
  }

  Future<Map<String, dynamic>> _httpJsonPost(
    String url,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final resp = await http
        .post(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (headers != null) ...headers,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));

    final text = resp.body.isEmpty ? '{}' : resp.body;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{
        'type': 0,
        'messages': ['Bad JSON shape'],
        'content': null,
      };
    } catch (_) {
      return <String, dynamic>{
        'type': 0,
        'messages': ['Non-JSON response', 'status=${resp.statusCode}'],
        'content': {'raw': text},
      };
    }
  }

  Future<(bool ok, String msg, Map<String, dynamic> content)>
  _mitfSignin() async {
    final url = _endpoint('Signin');

    /// ✅ Production: السيرفر يعتمد على ENV + mTLS
    /// نرسل body فاضي أو بسيط (مهم ما نرسلش بيانات حساسة)
    final res = await _httpJsonPost(url, _activeCreds);

    final ok = _isOk(res);
    final msg = _firstMessage(
      res,
      fallback: ok ? 'تم تسجيل الدخول' : 'فشل الدخول',
    );
    final content = _contentAsMap(res);

    return (ok, msg, content);
  }

  Future<(bool ok, String msg, Map<String, dynamic> content)> _mitfOpenSession({
    required int amount,
    required String identityCard,
    required String transactionId,
    int onlineOperation = 1,
    Map<String, dynamic>? signinContent,
  }) async {
    final url = _endpoint('OpenSession');

    final token = _extractToken(signinContent ?? {});
    final headers = <String, String>{};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    String? bank;
    switch (gatewayKey.value) {
      case 'masrafy':
        bank = 'gumhouria';
        break;
      case 'yesser':
        bank = 'tejari';
        break;
      case 'sahari':
        bank = 'sahari';
        break;
      default:
        bank = null;
    }

    final body = <String, dynamic>{
      'amount': amount,
      'identityCard': identityCard,
      'transactionId': transactionId,
      'onlineOperation': onlineOperation,
      'gateway': gatewayKey.value,
      if (bank != null) 'bank': bank,

      /// ✅ نرسل token كذلك في body (احتياط) لأن proxy PHP يدعمه
      if (token != null && token.isNotEmpty) 'token': token,
    };

    final res = await _httpJsonPost(
      url,
      body,
      headers: headers.isEmpty ? null : headers,
    );

    if (kDebugMode) debugPrint('MITF OpenSession => $res');

    final ok = _isOk(res);
    final msg = _firstMessage(
      res,
      fallback: ok ? 'تم فتح الجلسة' : 'فشل فتح الجلسة',
    );
    final content = _contentAsMap(res);

    return (ok, msg, content);
  }

  Future<(bool ok, String msg)> _mitfCompleteSession({
    required String otp,
    Map<String, dynamic>? openSessionContent,
  }) async {
    final url = _endpoint('CompleteSession');

    final sessionToken = _extractToken(openSessionContent ?? {});
    final body = <String, dynamic>{
      'otp': otp,
      'token': sessionToken,
      'gateway': gatewayKey.value,
    };

    final res = await _httpJsonPost(url, body);

    final ok = _isOk(res);
    final msg = _firstMessage(
      res,
      fallback: ok ? 'تمت عملية الدفع' : 'فشل إكمال العملية',
    );

    return (ok, msg);
  }

  Future<String?> _askForIdentityCard(String preset) async {
    /// ✅ Production: نخلي القيمة الافتراضية اللي تمررها أنت (أو فاضية)
    final ctrl = TextEditingController(
      text: preset.isNotEmpty ? preset : _testIdentityCard,
    );
    String? result;

    await Get.defaultDialog(
      title: 'رقم بطاقة الزبون',
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'أدخل رقم البطاقة (IdentityCard)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      textCancel: 'إلغاء',
      textConfirm: 'متابعة',
      onConfirm: () {
        final v = ctrl.text.trim();
        if (v.isEmpty) return;
        result = v;
        Get.back();
      },
      onCancel: () {},
    );

    return result;
  }

  Future<String?> _askForOtp() async {
    final ctrl = TextEditingController();
    String? result;

    await Get.defaultDialog(
      title: 'رمز التحقق (OTP)',
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            const SizedBox(height: 6),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'أدخل رمز OTP الذي وصلك',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      textCancel: 'إلغاء',
      textConfirm: 'تأكيد',
      onConfirm: () {
        final v = ctrl.text.trim();
        if (v.isEmpty) return;
        result = v;
        Get.back();
      },
      onCancel: () {},
    );

    return result;
  }

  String _genTxId() {
    final r = Random().nextInt(99999).toString().padLeft(5, '0');
    return 'EV-${_userId ?? 0}-${DateTime.now().millisecondsSinceEpoch}-$r';
  }

  Future<void> mitfSelfTest() async {
    isPlacing.value = true;
    try {
      final (ok, msg, _) = await _mitfSignin();
      if (ok) {
        _showSuccess('اتصال ناجح ببوابة مسارات: $msg', title: 'اختبار الاتصال');
      } else {
        _showUserError('فشل تسجيل الدخول: $msg');
      }
    } catch (e) {
      _showUserError(_friendlyMessage(e));
    } finally {
      isPlacing.value = false;
    }
  }

  /// ⭐ هنا نعامل حالة ITEM_DISABLED:
  /// - نظهر رسالة للمستخدم
  /// - نحدّث السلة cart.load()
  /// - لا نعمل refresh للهوم نهائيًا (حسب طلبك)
  Future<bool> _handleItemDisabledFromRes(dynamic res) async {
    try {
      if (res is Map &&
          (res['code'] == 'ITEM_DISABLED' || res['code'] == 'item_disabled')) {
        final String itemName = (res['item_name'] ?? '').toString().trim();
        final String serverMsg = (res['message'] ?? '').toString().trim();

        final msg = serverMsg.isNotEmpty
            ? serverMsg
            : (itemName.isNotEmpty
                  ? 'الصنف "$itemName" لم يعد متوفراً حالياً.'
                  : 'أحد الأصناف في السلة لم يعد متوفراً حالياً.');

        _showUserError(msg, title: 'صنف غير متوفر');

        // ✅ نحدّث السلة فقط (بدون تحديث الهوم)
        try {
          await cart.load();
        } catch (_) {}

        return true;
      }
    } catch (_) {}

    return false;
  }

  /// ✅ فحص مسبق لتوفر الأصناف قبل الدخول لمسار الدفع أونلاين
  /// - يستخدم create_order.php مع check_only=1
  /// - لو ITEM_DISABLED → نفس الرسالة + تحديث السلة + إيقاف المسار قبل الـ OTP
  Future<bool> _precheckItemsBeforeOnline() async {
    try {
      final items = _serializeCartItems();

      final body = <String, String>{
        'user_id': _userId.toString(),
        'address': addressCtrl.text.trim(),
        'payment': payment.value.toString(), // 1 = أونلاين
        'total': _total.toStringAsFixed(2),
        'status_order': statusOrder.value,
        'notes': noteCtrl.text.trim(),
        'initial_status': 'pending',
        'gateway': gatewayKey.value,
        'items_json': jsonEncode(items),
        'check_only': '1', // 🔥 أهم شيء
        if (destLat.value != null) 'dest_lat': destLat.value!.toString(),
        if (destLng.value != null) 'dest_lng': destLng.value!.toString(),
        if (pickupLat.value != null) 'pickup_lat': pickupLat.value!.toString(),
        if (pickupLng.value != null) 'pickup_lng': pickupLng.value!.toString(),
      };

      final res = await _api.post('create_order.php', body: body);

      // لو رجع ITEM_DISABLED → رسالة + تحديث السلة + إيقاف
      if (await _handleItemDisabledFromRes(res)) {
        return false;
      }

      final bool ok =
          (res is Map) &&
          (res['ok'] == true ||
              res['success'] == true ||
              res['status'] == 'ok' ||
              res['status'] == 'success' ||
              res['type'] == 1);

      if (!ok) {
        final msg =
            (res is Map && (res['message'] != null || res['messages'] != null))
            ? (res['message']?.toString() ??
                  (res['messages'] as List?)?.first?.toString() ??
                  'تعذّر التحقق من الأصناف قبل الدفع')
            : 'تعذّر التحقق من الأصناف قبل الدفع';

        _showUserError(msg);
        return false;
      }

      // ✅ كل شيء تمام
      return true;
    } catch (e) {
      _showUserError(_friendlyMessage(e));
      return false;
    }
  }

  Future<void> _handleOnlineFlowAndPlace() async {
    final (okSignin, msgSignin, signinContent) = await _mitfSignin();
    if (!okSignin) {
      _showUserError('فشل الدخول للبوابة: $msgSignin');
      return;
    }

    final identity = await _askForIdentityCard('');
    if (identity == null) {
      _showInfo('تم إلغاء عملية الدفع.');
      return;
    }

    final int amount = _total.round();
    final txId = _genTxId();

    final (okOpen, msgOpen, openContent) = await _mitfOpenSession(
      amount: amount,
      identityCard: identity,
      transactionId: txId,
      signinContent: signinContent,
    );

    if (!okOpen) {
      _showUserError('لم نستطع فتح جلسة الدفع: $msgOpen');
      return;
    }

    final otp = await _askForOtp();
    if (otp == null) {
      _showInfo('تم إلغاء عملية الدفع.');
      return;
    }

    final (okComplete, msgComplete) = await _mitfCompleteSession(
      otp: otp,
      openSessionContent: openContent,
    );

    if (!okComplete) {
      _showUserError('فشل إتمام الدفع: $msgComplete');
      return;
    }

    try {
      final items = _serializeCartItems();

      final body = <String, String>{
        'user_id': _userId.toString(),
        'address': addressCtrl.text.trim(),
        'payment': '1',
        'total': _total.toStringAsFixed(2),
        'status_order': statusOrder.value,
        'notes': '${noteCtrl.text.trim()} | MITF:$txId (${gatewayKey.value})',
        'initial_status': 'pending',
        'gateway': gatewayKey.value,
        if (destLat.value != null) 'dest_lat': destLat.value!.toString(),
        if (destLng.value != null) 'dest_lng': destLng.value!.toString(),
        if (pickupLat.value != null) 'pickup_lat': pickupLat.value!.toString(),
        if (pickupLng.value != null) 'pickup_lng': pickupLng.value!.toString(),
        'items_json': jsonEncode(items),
      };

      final res = await _api.post('create_order.php', body: body);

      // 🔴 لو صنف مقفول → رسالة + تحديث سلة فقط + إنهاء
      if (await _handleItemDisabledFromRes(res)) {
        return;
      }

      final bool ok =
          (res is Map) &&
          (res['ok'] == true ||
              res['success'] == true ||
              res['status'] == 'ok' ||
              res['status'] == 'success' ||
              res['type'] == 1);

      if (!ok) {
        final msg =
            (res is Map && (res['message'] != null || res['messages'] != null))
            ? (res['message']?.toString() ??
                  (res['messages'] as List?)?.first?.toString() ??
                  'تعذّر إنشاء الطلب بعد الدفع')
            : 'تعذّر إنشاء الطلب بعد الدفع';
        throw Exception(msg);
      }

      // ignore: unnecessary_type_check
      final orderId = (res is Map && res['order_id'] != null)
          ? int.tryParse(res['order_id'].toString())
          : null;

      await cart.clear();
      await _clearCheckoutCache(); // ✅ تنظيف المسودة بعد نجاح الطلب

      _showSuccess(
        orderId == null
            ? 'تم الدفع وإرسال الطلب بنجاح'
            : 'تم الدفع وإرسال طلبك بنجاح (رقم الطلب: $orderId)',
        title: 'تم',
      );

      _seedOrderInMyOrders(
        orderId: orderId,
        total: _total,
        itemsCount: items.length,
      );

      _openMyOrdersAfterSuccess(
        orderId: orderId,
        total: _total,
        itemsCount: items.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('placeOrder(after online) error: $e');
      }
      _showUserError(_friendlyMessage(e));
    }
  }

  Future<void> placeOrder() async {
    if (_userId == null) {
      _showInfo('الرجاء تسجيل الدخول أولاً', title: 'تنبيه');
      return;
    }

    if (statusOrder.value == 'delivery') {
      if (!(formKey.currentState?.validate() ?? false)) return;
    }

    if (cart.cart.isEmpty) {
      _showInfo('السلة فارغة', title: 'تنبيه');
      return;
    }

    // نخزن آخر حالة قبل الإرسال (احتياط)
    _saveCheckoutToCache();

    if (payment.value == 1) {
      isPlacing.value = true;
      try {
        // ✅ أولاً: فحص توفر الأصناف قبل الدخول لمسار الـ OTP
        final okPre = await _precheckItemsBeforeOnline();
        if (!okPre) {
          return;
        }

        // ✅ ثانياً: كل شيء تمام → نكمل لمسار الدفع أونلاين
        await _handleOnlineFlowAndPlace();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('online flow error: $e');
        }
        _showUserError(_friendlyMessage(e));
      } finally {
        isPlacing.value = false;
      }
      return;
    }

    isPlacing.value = true;
    try {
      final items = _serializeCartItems();

      final body = <String, String>{
        'user_id': _userId.toString(),
        'address': addressCtrl.text.trim(),
        'payment': payment.value.toString(),
        'total': _total.toStringAsFixed(2),
        'status_order': statusOrder.value,
        'notes': noteCtrl.text.trim(),
        'initial_status': 'pending',
        'gateway': gatewayKey.value,
        if (destLat.value != null) 'dest_lat': destLat.value!.toString(),
        if (destLng.value != null) 'dest_lng': destLng.value!.toString(),
        if (pickupLat.value != null) 'pickup_lat': pickupLat.value!.toString(),
        if (pickupLng.value != null) 'pickup_lng': pickupLng.value!.toString(),
        'items_json': jsonEncode(items),
      };

      final res = await _api.post('create_order.php', body: body);

      // 🔴 لو صنف مقفول → رسالة + تحديث سلة فقط + إنهاء
      if (await _handleItemDisabledFromRes(res)) {
        return;
      }

      final bool ok =
          (res is Map) &&
          (res['ok'] == true ||
              res['success'] == true ||
              res['status'] == 'ok' ||
              res['status'] == 'success' ||
              res['type'] == 1);

      if (!ok) {
        final msg =
            (res is Map && (res['message'] != null || res['messages'] != null))
            ? (res['message']?.toString() ??
                  (res['messages'] as List?)?.first?.toString() ??
                  'تعذّر إنشاء الطلب')
            : 'تعذّر إنشاء الطلب';
        throw Exception(msg);
      }

      // ignore: unnecessary_type_check
      final orderId = (res is Map && res['order_id'] != null)
          ? int.tryParse(res['order_id'].toString())
          : null;

      await cart.clear();
      await _clearCheckoutCache(); // ✅ تنظيف الكاش بعد نجاح الطلب

      _showSuccess(
        orderId == null
            ? 'تم إرسال طلبك بنجاح'
            : 'تم إرسال طلبك بنجاح (رقم الطلب: $orderId)',
        title: 'تم',
      );

      _seedOrderInMyOrders(
        orderId: orderId,
        total: _total,
        itemsCount: items.length,
      );

      _openMyOrdersAfterSuccess(
        orderId: orderId,
        total: _total,
        itemsCount: items.length,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('placeOrder error: $e');
      }
      _showUserError(_friendlyMessage(e));
    } finally {
      isPlacing.value = false;
    }
  }

  void _seedOrderInMyOrders({
    required int? orderId,
    required double total,
    required int itemsCount,
  }) {
    if (orderId == null || orderId <= 0) return;

    try {
      if (Get.isRegistered<MyOrdersController>()) {
        final orders = Get.find<MyOrdersController>();
        orders.seedOrder(
          orderId: orderId,
          total: total,
          itemsCount: itemsCount,
          status: 'pending',
          statusOrder: statusOrder.value,
          createdAt: DateTime.now().toIso8601String(),
        );
        orders.fetch(silent: true);
      }
    } catch (_) {}
  }

  void _openMyOrdersAfterSuccess({
    required int? orderId,
    required double total,
    required int itemsCount,
  }) {
    final args = {
      'highlightOrderId': orderId,
      'total': total.toStringAsFixed(2),
      'items_count': itemsCount,
      'status': 'pending',
      'status_order': statusOrder.value,
      'created_at': DateTime.now().toIso8601String(),
    };

    Get.offNamedUntil(
      '/my-orders',
      (route) {
        final name = route.settings.name ?? '';

        // بعد إتمام الطلب نحذف صفحة الدفع والسلة من مسار الرجوع.
        // لو كان المستخدم جاي من تفاصيل صنف، الرجوع من طلباتي يرجعه للتفاصيل مباشرة.
        // ولو ما فيش تفاصيل صنف في المسار، نخلي أول صفحة موجودة حتى ما يصيرش مسار فارغ.
        if (name == AppRoutes.itemDetail || name == AppRoutes.home) {
          return true;
        }

        return route.isFirst;
      },
      parameters: {'tab': 'current'},
      arguments: args,
    );
  }

  @override
  void onClose() {
    addressCtrl.dispose();
    noteCtrl.dispose();
    super.onClose();
  }
}
