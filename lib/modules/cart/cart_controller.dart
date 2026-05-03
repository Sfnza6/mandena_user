import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/core/api_service.dart';
import 'package:mandena/core/session.dart';
import 'package:mandena/data/models/address.dart';
import 'package:mandena/modules/branch/branch_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartController extends GetxController {
  final _api = ApiService();

  final isBusy = false.obs;

  final cart = <Map<String, dynamic>>[].obs;

  final subtotal = 0.0.obs;
  final delivery = 0.0.obs;
  final services = 0.0.obs;

  double get total => subtotal.value + delivery.value + services.value;

  int get itemsCount {
    try {
      return cart.fold<int>(
        0,
        (sum, item) => sum + _toInt(item['quantity'], 0),
      );
    } catch (_) {
      return 0;
    }
  }

  int? _userId;

  final selectedAddress = Rxn<Address>();
  final selectedAddressName = ''.obs;

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
      snackPosition: SnackPosition.TOP,
      borderRadius: 16,
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      backgroundColor: bg,
      boxShadows: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
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

  void _showSuccess(String msg, {String title = 'تم'}) {
    _showSnack(bg: const Color(0xFF065F46), title: title, msg: msg, seconds: 3);
  }

  String _friendlyMessage(Object e) {
    final t = e.toString().toLowerCase();

    if (t.contains('failed host lookup') ||
        t.contains('socketexception') ||
        t.contains('network is unreachable') ||
        t.contains('network_error') ||
        t.contains('no address associated with hostname') ||
        t.contains('connection closed before full header was received') ||
        t.contains('connection terminated during handshake') ||
        t.contains('لا يوجد اتصال')) {
      return '⚠️ لا يوجد اتصال بالإنترنت.\nتحقّق من الشبكة ثم أعد المحاولة.';
    }

    if (t.contains('timeout') ||
        t.contains('timed out') ||
        t.contains('deadline exceeded')) {
      return '⏳ انتهت مهلة الاتصال.\nحاول مجددًا بعد لحظات.';
    }

    if (t.contains('handshakeexception') ||
        t.contains('certificate') ||
        t.contains('ssl')) {
      return '🔐 حدثت مشكلة أمان مؤقتة أثناء الاتصال بالخادم.\nحاول مرة أخرى لاحقًا.';
    }

    if (t.contains('json') ||
        t.contains('formatexception') ||
        t.contains('unexpected character') ||
        t.contains('non-json response')) {
      return '⚠️ حدث خلل في البيانات المستلمة من الخادم.\nأعد المحاولة بعد قليل.';
    }

    return 'حدث خطأ غير متوقع.\nيرجى المحاولة لاحقًا.';
  }

  int _currentBranchId() {
    try {
      if (Get.isRegistered<BranchController>()) {
        return Get.find<BranchController>().selectedBranchId.value;
      }
    } catch (_) {}
    return 0;
  }

  String get _cartCacheKey => _userId == null
      ? 'cart_user_0_branch_${_currentBranchId()}'
      : 'cart_user_${_userId!}_branch_${_currentBranchId()}';

  double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }

  int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  Map<String, dynamic>? _asMap(dynamic res) {
    try {
      if (res == null) return null;
      if (res is Map<String, dynamic>) return res;
      if (res is Map) return Map<String, dynamic>.from(res);

      final s = res.toString().trim();
      if (s.isEmpty) return null;

      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  Future<void> _saveCartToCache() async {
    if (_userId == null || _userId == 0) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final data = {
        'cart': cart.toList(),
        'subtotal': subtotal.value,
        'delivery': delivery.value,
        'services': services.value,
      };
      await sp.setString(_cartCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadCartFromCache() async {
    if (_userId == null || _userId == 0) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_cartCacheKey);
      if (s == null || s.isEmpty) return;

      final data = jsonDecode(s);
      if (data is! Map) return;

      final list = (data['cart'] as List?) ?? const [];
      cart.assignAll(
        list
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList(),
      );

      subtotal.value = _toDouble(data['subtotal']);
      delivery.value = _toDouble(data['delivery']);
      services.value = _toDouble(data['services']);
    } catch (_) {}
  }

  Future<void> clearForBranchChange() async {
    await switchBranchContext();
  }

  Future<void> switchBranchContext() async {
    cart.clear();
    subtotal.value = 0;
    delivery.value = 0;
    services.value = 0;

    if (_userId != null && _userId! > 0) {
      await _loadCartFromCache();
      await load();
      await _loadDefaultAddressName();
    } else {
      selectedAddress.value = null;
      selectedAddressName.value = '';
    }

    update();
  }

  Future<bool> _ensureBoundToSession() async {
    final currentUserId = await Session.userId();
    if (currentUserId != _userId) {
      await bindToCurrentUser();
    }
    return _userId != null && _userId! > 0;
  }

  @override
  void onInit() {
    super.onInit();
    bindToCurrentUser();
  }

  Future<void> bindToCurrentUser() async {
    _userId = await Session.userId();

    cart.clear();
    subtotal.value = 0;
    delivery.value = 0;
    services.value = 0;

    if (_userId != null && _userId! > 0) {
      await _loadCartFromCache();
      await load();
      await _loadDefaultAddressName();
    } else {
      selectedAddressName.value = '';
      selectedAddress.value = null;
    }

    update();
  }

  List<Map<String, dynamic>> _parseAddons(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map<Map<String, dynamic>>((a) {
      final m = Map<String, dynamic>.from(a as Map);
      return {
        'id': _toInt(m['id']),
        'name': (m['name'] ?? '').toString(),
        'price': _toDouble(m['price']),
        'qty': _toInt(m['qty'], 0),
        'image_url': (m['image_url'] ?? '').toString(),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _parseRemovals(Map<String, dynamic> e) {
    dynamic raw = e['removals'];
    raw ??= e['components_rem'];
    raw ??= e['removes'];
    raw ??= e['removed'];
    raw ??= e['item_removes'];

    final List<Map<String, dynamic>> removals = [];
    if (raw is List) {
      for (final x in raw) {
        if (x is Map) {
          final m = Map<String, dynamic>.from(x);
          removals.add({
            'id': _toInt(m['id']),
            'name': (m['name'] ?? m['title'] ?? m['label'] ?? '').toString(),
          });
        } else {
          removals.add({'id': 0, 'name': x.toString()});
        }
      }
    }
    return removals;
  }

  Future<void> load() async {
    if (!await _ensureBoundToSession()) return;

    isBusy.value = true;
    try {
      final res = await _api.get(
        'get_cart.php',
        params: {'user_id': '$_userId'},
      );

      final r = _asMap(res);
      if (r == null) {
        throw Exception('INVALID_CART_RESPONSE');
      }

      final ok =
          r['ok'] == true || r['status'] == 'success' || r['status'] == 'ok';

      if (!ok) {
        throw Exception((r['message'] ?? 'فشل تحميل السلة').toString());
      }

      final rawList = (r['cart'] is List)
          ? (r['cart'] as List)
          : (r['data'] is List)
          ? (r['data'] as List)
          : const [];

      final list = rawList.map<Map<String, dynamic>>((raw) {
        final e = Map<String, dynamic>.from(raw as Map);

        final cartItemId = e['cart_item_id'] ?? e['cart_id'] ?? e['id'] ?? 0;
        final itemId = e['item_id'] ?? e['product_id'] ?? 0;
        final price = _toDouble(e['price']);
        final qty = _toInt(e['quantity'], 1);

        final addons = _parseAddons(e['addons']);
        final removals = _parseRemovals(e);

        final addonsTotalPerUnit = addons.fold<double>(
          0.0,
          (s, a) => s + (_toDouble(a['price']) * _toInt(a['qty'])),
        );

        final serverUnitTotal = e['unit_total'] != null
            ? _toDouble(e['unit_total'])
            : null;
        final unitTotal = serverUnitTotal ?? (price + addonsTotalPerUnit);

        final serverLineTotal = e['line_total'] != null
            ? _toDouble(e['line_total'])
            : null;
        final lineTotal = serverLineTotal ?? (unitTotal * qty);

        return {
          ...e,
          'cart_item_id': _toInt(cartItemId),
          'item_id': _toInt(itemId),
          'name': (e['name'] ?? '').toString(),
          'short_desc': (e['short_desc'] ?? '').toString(),
          'image_url': (e['image_url'] ?? '').toString(),
          'price': price,
          'quantity': qty,
          'addons': addons,
          'removals': removals,
          'unit_total': unitTotal,
          'line_total': lineTotal,
        };
      }).toList();

      cart.assignAll(list);

      final serverSubtotal = r['subtotal'] != null
          ? _toDouble(r['subtotal'])
          : null;

      subtotal.value =
          serverSubtotal ??
          cart.fold<double>(0.0, (s, e) => s + _toDouble(e['line_total']));

      delivery.value = _toDouble(r['delivery']);
      services.value = _toDouble(r['services']);

      await _saveCartToCache();
    } catch (e) {
      await _loadCartFromCache();
      _showUserError(_friendlyMessage(e), onRetry: load);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> add(int itemId, {int qty = 1, bool showSnack = true}) async {
    if (!await _ensureBoundToSession()) return;
    try {
      final res = await _api.post(
        'add_to_cart.php',
        body: {'user_id': '$_userId', 'item_id': '$itemId', 'quantity': '$qty'},
      );

      final m = _asMap(res);
      if (m != null &&
          m['status'] != 'success' &&
          m['ok'] != true &&
          m['message'] != null) {
        throw Exception(m['message'].toString());
      }

      await load();
      if (showSnack) {
        _showSuccess('تمت إضافة الصنف إلى السلة');
      }
    } catch (e) {
      _showUserError(
        _friendlyMessage(e),
        onRetry: () => add(itemId, qty: qty, showSnack: showSnack),
      );
    }
  }

  Future<void> setQty(int itemId, int qty) async {
    if (!await _ensureBoundToSession()) return;
    try {
      final row = cart.firstWhereOrNull((e) => _toInt(e['item_id']) == itemId);
      final cartItemId = _toInt(row?['cart_item_id']);
      await _api.post(
        'update_cart_item.php',
        body: {
          'user_id': '$_userId',
          'item_id': '$itemId',
          if (cartItemId > 0) 'cart_item_id': '$cartItemId',
          'quantity': '$qty',
        },
      );
      await load();
    } catch (e) {
      _showUserError(_friendlyMessage(e), onRetry: () => setQty(itemId, qty));
    }
  }

  Future<void> inc(int itemId) async {
    final row = cart.firstWhereOrNull((e) => _toInt(e['item_id']) == itemId);
    final q = _toInt(row?['quantity']) + 1;
    await setQty(itemId, q);
  }

  Future<void> dec(int itemId) async {
    final row = cart.firstWhereOrNull((e) => _toInt(e['item_id']) == itemId);
    final q = _toInt(row?['quantity']) - 1;
    await setQty(itemId, q < 0 ? 0 : q);
  }

  Future<void> remove(int itemId) async {
    if (_userId == null) return;
    try {
      final row = cart.firstWhereOrNull((e) => _toInt(e['item_id']) == itemId);
      final cartItemId = _toInt(row?['cart_item_id']);
      await _api.post(
        'remove_cart_item.php',
        body: {
          'user_id': '$_userId',
          'item_id': '$itemId',
          if (cartItemId > 0) 'cart_item_id': '$cartItemId',
        },
      );
      await load();
    } catch (e) {
      _showUserError(_friendlyMessage(e), onRetry: () => remove(itemId));
    }
  }

  Future<void> setQtyByCartId(int cartItemId, int qty) async {
    if (_userId == null) return;

    final itemId = _findItemIdByCartId(cartItemId);

    try {
      await _api.post(
        'update_cart_item.php',
        body: {
          'user_id': '$_userId',
          'cart_item_id': '$cartItemId',
          if (itemId != null) 'item_id': '$itemId',
          'quantity': '$qty',
        },
      );
      await load();
    } catch (e) {
      _showUserError(
        _friendlyMessage(e),
        onRetry: () => setQtyByCartId(cartItemId, qty),
      );
    }
  }

  Future<void> incByCartId(int cartItemId) async {
    final row = cart.firstWhereOrNull(
      (e) => _toInt(e['cart_item_id']) == cartItemId,
    );
    final q = _toInt(row?['quantity']) + 1;
    await setQtyByCartId(cartItemId, q);
  }

  Future<void> decByCartId(int cartItemId) async {
    final row = cart.firstWhereOrNull(
      (e) => _toInt(e['cart_item_id']) == cartItemId,
    );
    final q = _toInt(row?['quantity']) - 1;
    await setQtyByCartId(cartItemId, q < 0 ? 0 : q);
  }

  Future<void> removeByCartId(int cartItemId) async {
    if (_userId == null) return;
    final itemId = _findItemIdByCartId(cartItemId);
    try {
      await _api.post(
        'remove_cart_item.php',
        body: {
          'user_id': '$_userId',
          'cart_item_id': '$cartItemId',
          if (itemId != null) 'item_id': '$itemId',
        },
      );
      await load();
    } catch (e) {
      _showUserError(
        _friendlyMessage(e),
        onRetry: () => removeByCartId(cartItemId),
      );
    }
  }

  int? _findItemIdByCartId(int cartItemId) {
    final row = cart.firstWhereOrNull(
      (e) => _toInt(e['cart_item_id']) == cartItemId,
    );
    final id = row?['item_id'];
    return id == null ? null : _toInt(id);
  }

  Future<void> setAddonQty(int itemId, int addonId, int qty) async {
    if (_userId == null) return;
    try {
      await _api.post(
        'update_cart_extra.php',
        body: {
          'user_id': '$_userId',
          'item_id': '$itemId',
          'extra_id': '$addonId',
          'qty': '$qty',
        },
      );
      await load();
    } catch (e) {
      _showUserError(
        _friendlyMessage(e),
        onRetry: () => setAddonQty(itemId, addonId, qty),
      );
    }
  }

  Future<void> incAddon(int itemId, int addonId) async {
    final row = cart.firstWhereOrNull((e) => _toInt(e['item_id']) == itemId);
    if (row == null) return;
    final addons = (row['addons'] as List).cast<Map<String, dynamic>>();
    final m = addons.firstWhereOrNull((a) => _toInt(a['id']) == addonId);
    final current = _toInt(m?['qty']);
    await setAddonQty(itemId, addonId, current + 1);
  }

  Future<void> decAddon(int itemId, int addonId) async {
    final row = cart.firstWhereOrNull((e) => _toInt(e['item_id']) == itemId);
    if (row == null) return;
    final addons = (row['addons'] as List).cast<Map<String, dynamic>>();
    final m = addons.firstWhereOrNull((a) => _toInt(a['id']) == addonId);
    final current = _toInt(m?['qty']);
    final next = current - 1;
    await setAddonQty(itemId, addonId, next < 0 ? 0 : next);
  }

  Future<void> setAddonQtyByCartId(int cartItemId, int addonId, int qty) async {
    if (_userId == null) return;
    final itemId = _findItemIdByCartId(cartItemId);
    try {
      await _api.post(
        'update_cart_extra.php',
        body: {
          'user_id': '$_userId',
          'cart_item_id': '$cartItemId',
          if (itemId != null) 'item_id': '$itemId',
          'extra_id': '$addonId',
          'qty': '$qty',
        },
      );
      await load();
    } catch (e) {
      _showUserError(
        _friendlyMessage(e),
        onRetry: () => setAddonQtyByCartId(cartItemId, addonId, qty),
      );
    }
  }

  Future<void> incAddonByCartId(int cartItemId, int addonId) async {
    final row = cart.firstWhereOrNull(
      (e) => _toInt(e['cart_item_id']) == cartItemId,
    );
    if (row == null) return;
    final addons = (row['addons'] as List).cast<Map<String, dynamic>>();
    final m = addons.firstWhereOrNull((a) => _toInt(a['id']) == addonId);
    final current = _toInt(m?['qty']);
    await setAddonQtyByCartId(cartItemId, addonId, current + 1);
  }

  Future<void> decAddonByCartId(int cartItemId, int addonId) async {
    final row = cart.firstWhereOrNull(
      (e) => _toInt(e['cart_item_id']) == cartItemId,
    );
    if (row == null) return;
    final addons = (row['addons'] as List).cast<Map<String, dynamic>>();
    final m = addons.firstWhereOrNull((a) => _toInt(a['id']) == addonId);
    final current = _toInt(m?['qty']);
    final next = current - 1;
    await setAddonQtyByCartId(cartItemId, addonId, next < 0 ? 0 : next);
  }

  void setSelectedAddress(Address a) {
    selectedAddress.value = a;
    final displayName = (a.label.isNotEmpty ? a.label : a.addressText).trim();
    selectedAddressName.value = displayName;
    update();
  }

  Future<void> _loadDefaultAddressName() async {
    if (_userId == null || _userId == 0) {
      selectedAddressName.value = '';
      selectedAddress.value = null;
      return;
    }

    try {
      final res = await _api.get(
        'get_user_addresses.php',
        params: {
          'user_id': '$_userId',
          't': '${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      dynamic jsonObj = res;
      if (res is String) {
        try {
          jsonObj = jsonDecode(res);
        } catch (_) {}
      }

      List list = const [];
      if (jsonObj is Map &&
          jsonObj['status'] == 'success' &&
          jsonObj['data'] is List) {
        list = jsonObj['data'];
      } else if (jsonObj is Map && jsonObj['addresses'] is List) {
        list = jsonObj['addresses'];
      } else if (jsonObj is List) {
        list = jsonObj;
      }

      if (list.isEmpty) {
        selectedAddressName.value = '';
        selectedAddress.value = null;
        return;
      }

      Map<String, dynamic>? def;
      for (final e in list) {
        final m = Map<String, dynamic>.from(e as Map);
        final isDefStr =
            (m['is_default'] ?? m['default'] ?? m['isDefault'] ?? 0).toString();
        final isDef = isDefStr == '1' || isDefStr.toLowerCase() == 'true';
        if (isDef) {
          def = m;
          break;
        }
      }

      def ??= Map<String, dynamic>.from(list.first as Map);

      Address? addr;
      try {
        addr = Address.fromJson(def);
      } catch (_) {}

      if (addr != null) {
        selectedAddress.value = addr;
        final nameFromAddr = addr.label.trim().isNotEmpty
            ? addr.label.trim()
            : addr.addressText.trim();
        selectedAddressName.value = nameFromAddr;
        return;
      }

      final fallbackName = (def['name'] ?? def['label'] ?? def['title'] ?? '')
          .toString()
          .trim();

      selectedAddressName.value = fallbackName;
    } catch (e) {
      debugPrint('load default address for cart error: $e');
    }
  }

  Future<void> clear() async {
    if (_userId == null) return;
    try {
      await _api.post('clear_cart.php', body: {'user_id': '$_userId'});
      await load();
      _showSuccess('تم تفريغ السلة');
    } catch (e) {
      try {
        final ids = cart.map<int>((e) => _toInt(e['item_id'])).toList();
        for (final id in ids) {
          try {
            await _api.post(
              'remove_cart_item.php',
              body: {'user_id': '$_userId', 'item_id': '$id'},
            );
          } catch (_) {}
        }
        await load();
      } catch (_) {
        _showUserError(_friendlyMessage(e), onRetry: clear);
      }
    }
  }
}
