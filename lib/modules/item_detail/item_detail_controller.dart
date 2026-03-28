import 'dart:convert'; // ← للكاش
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // ← لإظهار سناك ملوّن أنيق
import 'package:shared_preferences/shared_preferences.dart'; // ← للكاش
import '../../data/models/item.dart';
import '../../core/api_service.dart';
import '../../core/session.dart';
import '../favorites/favorites_controller.dart';
import '../cart/cart_controller.dart';

// ================== 🆕 منطق الحساب التجريبي ==================
bool _isDemoUser(int? id, bool demoFlag) {
  return (id == null || id == 0 || demoFlag == true);
}
// =============================================================

/// موديل بسيط للخيار (إضافة/حذف)
class AddonOption {
  final int id;
  final String name;
  final double price;
  final bool selected;

  const AddonOption({
    required this.id,
    required this.name,
    this.price = 0,
    this.selected = false,
  });

  AddonOption copyWith({bool? selected}) => AddonOption(
    id: id,
    name: name,
    price: price,
    selected: selected ?? this.selected,
  );

  factory AddonOption.fromJson(Map<String, dynamic> j) {
    return AddonOption(
      id: int.tryParse('${j['id'] ?? j['option_id'] ?? 0}') ?? 0,
      name: (j['name'] ?? j['title'] ?? '').toString(),
      price: double.tryParse('${j['price'] ?? 0}') ?? 0.0,
      selected: (j['selected']?.toString().toLowerCase() == 'true'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'selected': selected,
  };
}

/// موديل تعليق صنف
class ItemComment {
  final int id;
  final int userId;
  final String userName;
  final String comment;
  final DateTime? createdAt;

  ItemComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    this.createdAt,
  });

  factory ItemComment.fromJson(Map<String, dynamic> j) {
    final createdStr = (j['created_at'] ?? j['date'] ?? '').toString();
    DateTime? dt;
    if (createdStr.isNotEmpty) {
      try {
        dt = DateTime.tryParse(createdStr);
      } catch (_) {}
    }
    return ItemComment(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      userId: int.tryParse('${j['user_id'] ?? 0}') ?? 0,
      userName:
          (j['user_name'] ?? j['name'] ?? j['full_name'] ?? 'مستخدم مجهول')
              .toString(),
      comment: (j['comment'] ?? j['text'] ?? '').toString(),
      createdAt: dt,
    );
  }
}

class ItemDetailController extends GetxController {
  late final ItemModel item;
  final _api = ApiService();

  final qty = 1.obs;
  final isAdding = false.obs;
  final isFavorite = false.obs;

  final additions = <AddonOption>[].obs;
  final removals = <AddonOption>[].obs;

  int? _userId;

  /// 🆕 هل المستخدم Demo؟
  bool _isDemo = false;

  int? get currentUserId => _userId;

  final selectedStars = 5.obs;
  final ratingBusy = false.obs;
  final avgRating = 0.0.obs;
  final ratingMsg = ''.obs;

  final comments = <ItemComment>[].obs;
  final loadingComments = false.obs;
  final commentBusy = false.obs;

  /// 🆕 هل آخر محاولة addToCart نجحت فعلاً؟
  final lastAddSuccess = false.obs;

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
    final t = e.toString().toLowerCase();
    if (t.contains('failed host lookup') ||
        t.contains('socketexception') ||
        t.contains('network is unreachable') ||
        t.contains('network_error') ||
        t.contains('no address associated with hostname') ||
        t.contains('لا يوجد اتصال')) {
      return '⚠️ لا يوجد اتصال بالإنترنت.';
    }
    if (t.contains('timeout') ||
        t.contains('timed out') ||
        t.contains('deadline exceeded')) {
      return '⏳ انتهت مهلة الاتصال.';
    }
    if (t.contains('handshakeexception') ||
        t.contains('certificate') ||
        t.contains('ssl')) {
      return '🔐 مشكلة أمان مؤقتة.';
    }
    if (t.contains('formatexception') ||
        t.contains('unexpected character') ||
        t.contains('json')) {
      return '⚠️ خطأ بالبيانات.';
    }
    return 'حدث خطأ غير متوقع.';
  }

  Map<String, dynamic>? _normalizeResponse(dynamic res) {
    // لو الرد بالفعل Map
    if (res is Map<String, dynamic>) return res;
    if (res is Map) return Map<String, dynamic>.from(res);

    // لو الرد نص
    if (res is String) {
      final s = res.trim();

      // 🔥 حماية — لو الرد فارغ أو HTML → نرجع Map فارغة
      if (s.isEmpty ||
          s.startsWith('<') ||
          s.startsWith('Warning') ||
          s.startsWith('Notice')) {
        return {};
      }

      try {
        final decoded = jsonDecode(s);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        // 🔥 منع FormatException نهائياً
        return {};
      }
    }

    return {};
  }

  bool _isOkResponse(Map<String, dynamic> m) {
    final okVal = m['ok'];
    final statusVal = m['status'];
    final successVal = m['success'];

    final okStr = '${okVal ?? ''}'.toLowerCase();
    final statusStr = '${statusVal ?? ''}'.toLowerCase();
    final successStr = '${successVal ?? ''}'.toLowerCase();

    return (okVal == true) ||
        okStr == '1' ||
        okStr == 'true' ||
        statusStr == 'ok' ||
        statusStr == 'success' ||
        successStr == '1' ||
        successStr == 'true';
  }

  // =========================== 🆕 تحديث بيانات المستخدم/الديمو من السيشن ===========================
  Future<void> _refreshUserDemoFromSession() async {
    try {
      final local = await Session.readLoggedIn();
      if (local != null) {
        final dynamic rawId = local['id'] ?? local['user_id'] ?? 0;
        final int idNum = (rawId is int) ? rawId : int.tryParse('$rawId') ?? 0;
        final bool guestFlag = local['is_guest'] == true;
        final bool demoFlag = local['is_demo'] == true;

        _userId = idNum;
        _isDemo = demoFlag || guestFlag || idNum == 0;
      } else {
        _userId = await Session.userId();
        _isDemo = await Session.isDemo();
      }
    } catch (_) {
      try {
        _userId ??= await Session.userId();
      } catch (_) {}
    }
  }

  // =========================== 🆕 منطق Demo الأساس ===========================
  Future<bool> _checkDemoBlock(String actionName) async {
    // نضمن دائماً قراءة أحدث حالة من السيشن
    await _refreshUserDemoFromSession();

    if (_isDemoUser(_userId, _isDemo)) {
      _showInfo(
        'هذا حساب تجريبي — لا يمكنك $actionName.\nيرجى إنشاء حساب حقيقي.',
        title: 'حساب تجريبي',
      );
      return true;
    }
    return false;
  }

  /// 🆕 دالة علنية تستخدمها الواجهات قبل المفضلة
  Future<bool> checkDemoBeforeFavorite() async {
    // ترجع true لو العملية ممنوعة (حساب تجريبي)
    return _checkDemoBlock("تعديل المفضلة");
  }
  // ===================================================================

  Future<void> editComment(int commentId, String newText) async {
    if (await _checkDemoBlock("تعديل التعليق")) return;

    if (newText.trim().isEmpty) {
      _showInfo('اكتب شيئاً لتعديل التعليق');
      return;
    }
    if (!await _ensureUser()) return;

    try {
      final raw = await _api.post(
        'edit_item_comment.php',
        body: {
          'comment_id': '$commentId',
          'user_id': '$_userId',
          'comment': newText.trim(),
        },
      );

      final res = _normalizeResponse(raw);
      if (res != null && _isOkResponse(res)) {
        _showSuccess('تم تعديل التعليق');
        await fetchComments();
      } else {
        final err = (res?['error'] ?? res?['message'] ?? '').toString().trim();
        if (err.isNotEmpty) {
          _showUserError(err);
        } else {
          _showInfo('تعذّر تعديل التعليق حالياً');
        }
      }
    } catch (e) {
      _showUserError(_friendlyMessage(e));
    }
  }

  Future<void> deleteComment(int commentId) async {
    if (await _checkDemoBlock("حذف التعليق")) return;

    if (!await _ensureUser()) return;

    try {
      final raw = await _api.post(
        'delete_item_comment.php',
        body: {'comment_id': '$commentId', 'user_id': '$_userId'},
      );

      final res = _normalizeResponse(raw);
      if (res != null && _isOkResponse(res)) {
        _showSuccess('تم حذف التعليق');
        await fetchComments();
      } else {
        final err = (res?['error'] ?? res?['message'] ?? '').toString().trim();
        if (err.isNotEmpty) {
          _showUserError(err);
        } else {
          _showInfo('تعذّر حذف التعليق حالياً');
        }
      }
    } catch (e) {
      _showUserError(_friendlyMessage(e));
    }
  }

  static const String _kOptionsKeyPrefix = 'item_opts_';

  String get _optionsCacheKey => '$_kOptionsKeyPrefix${item.id}';

  Future<void> _saveOptionsToCache() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final data = {
        'additions': additions.map((a) => a.toJson()).toList(),
        'removals': removals.map((r) => r.toJson()).toList(),
      };
      await sp.setString(_optionsCacheKey, jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _loadOptionsFromCache() async {
    if (additions.isNotEmpty || removals.isNotEmpty) return;
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_optionsCacheKey);
      if (s == null || s.isEmpty) return;

      final data = jsonDecode(s);
      if (data is! Map) return;

      final addSrc = (data['additions'] as List?) ?? const [];
      final remSrc = (data['removals'] as List?) ?? const [];

      final adds = addSrc
          .map((e) => AddonOption.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final rems = remSrc
          .map((e) => AddonOption.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      additions.assignAll(adds);
      removals.assignAll(rems);
    } catch (_) {}
  }

  @override
  void onInit() {
    super.onInit();
    _readItemFromArgs();
    try {
      avgRating.value = (item.rating).toDouble();
    } catch (_) {
      avgRating.value = 0.0;
    }

    _loadOptionsFromArgs();
    _loadOptionsFromCache();
    _fetchOptionsFromApi();
    _loadUser();
    _refreshAvgFromServer(); // هذي اللي تعدّل من الـ API
    fetchComments();
  }

  Future<void> _loadUser() async {
    try {
      _userId = await Session.userId();
      _isDemo = await Session.isDemo(); // 🆕 إضافة مهمة
      if (_userId != null && _userId! > 0 && !_isDemo) {
        await checkFavorite();
      }
    } catch (_) {}
  }

  Future<bool> _ensureUser() async {
    // تحديث آخر حالة من السيشن دائماً قبل أي عملية
    await _refreshUserDemoFromSession();

    if (_isDemoUser(_userId, _isDemo)) {
      _showInfo(
        'هذا حساب تجريبي — لا يمكن تنفيذ العملية.',
        title: 'حساب تجريبي',
      );
      return false;
    }

    if (_userId != null && _userId! > 0) return true;

    _userId = await Session.userId();
    if (_isDemoUser(_userId, _isDemo)) {
      _showInfo(
        'هذا حساب تجريبي — لا يمكن تنفيذ العملية.',
        title: 'حساب تجريبي',
      );
      return false;
    }

    if (_userId == null || _userId == 0) {
      _showInfo('يرجى تسجيل الدخول أولاً', title: 'تنبيه');
      return false;
    }

    return true;
  }

  void _readItemFromArgs() {
    final args = Get.arguments;
    if (args is ItemModel) {
      item = args;
      return;
    }
    if (args is Map) {
      try {
        item = ItemModel.fromJson(Map<String, dynamic>.from(args));
        return;
      } catch (e) {
        if (kDebugMode) debugPrint('item parse error: $e');
      }
    }
    throw Exception('لم يتم تمرير الصنف إلى صفحة التفاصيل');
  }

  void _loadOptionsFromArgs() {
    final args = Get.arguments;
    if (args is Map) {
      final addSrc = args['additions'];
      final remSrc = args['removals'];
      if (addSrc is List) {
        additions.assignAll(
          addSrc.map((e) => AddonOption.fromJson(Map<String, dynamic>.from(e))),
        );
      }
      if (remSrc is List) {
        removals.assignAll(
          remSrc.map((e) => AddonOption.fromJson(Map<String, dynamic>.from(e))),
        );
      }
    }
  }

  Future<void> _fetchOptionsFromApi() async {
    try {
      final res = await _api.get(
        'get_item_components.php',
        params: {'item_id': '${item.id}'},
      );
      if (res is Map && (res['ok'] == true || '${res['ok']}' == '1')) {
        final addSrc = (res['additions'] as List?) ?? const [];
        final remSrc = (res['removals'] as List?) ?? const [];
        additions.assignAll(
          addSrc.map((e) => AddonOption.fromJson(Map<String, dynamic>.from(e))),
        );
        removals.assignAll(
          remSrc.map((e) => AddonOption.fromJson(Map<String, dynamic>.from(e))),
        );
        await _saveOptionsToCache();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetch options error: $e');
      }
      _showInfo('تعذّر تحميل المكوّنات حالياً.');
    }
  }

  void incQty() => qty.value++;
  void decQty() {
    if (qty.value > 1) qty.value--;
  }

  void toggleAddition(int i) {
    final a = additions[i];
    additions[i] = a.copyWith(selected: !a.selected);
  }

  void toggleRemoval(int i) {
    final r = removals[i];
    removals[i] = r.copyWith(selected: !r.selected);
  }

  Future<void> toggleFavorite() async {
    // نتأكد أولاً إن بيانات المستخدم والحساب التجريبي محمّلة
    if (_userId == null) {
      try {
        await _loadUser();
      } catch (_) {}
    }

    if (await _checkDemoBlock("تعديل المفضلة")) return;

    if (!await _ensureUser()) return;
    final fav = isFavorite.value;

    try {
      if (fav) {
        // ===========================
        //       إزالة من المفضلة
        // ===========================
        final raw = await _api.post(
          'remove_favorite.php',
          body: {'user_id': '$_userId', 'item_id': '${item.id}'},
        );

        final res = _normalizeResponse(raw) ?? {};
        if (res.isNotEmpty) {
          // مجرد استخدام بسيط حتى لا يظهر تحذير المتغيّر غير المستخدم
        }

        isFavorite.value = false;
        if (Get.isRegistered<FavoritesController>()) {
          Get.find<FavoritesController>().markFavoriteRemoved(item.id);
        }
        _showInfo('تمت إزالة المنتج من المفضلة', title: 'المفضلة');
      } else {
        // ===========================
        //       إضافة للمفضلة
        // ===========================
        final raw = await _api.post(
          'add_favorite.php',
          body: {'user_id': '$_userId', 'item_id': '${item.id}'},
        );

        final res = _normalizeResponse(raw) ?? {};
        if (res.isNotEmpty) {
          // مجرد استخدام بسيط حتى لا يظهر تحذير المتغيّر غير المستخدم
        }

        isFavorite.value = true;
        if (Get.isRegistered<FavoritesController>()) {
          Get.find<FavoritesController>().markFavoriteAdded(
            item.id,
            itemData: item.toJson(),
          );
        }
        _showSuccess('تمت إضافة المنتج إلى المفضلة بنجاح', title: 'تم');
      }
    } catch (e) {
      // لو حصل خطأ (غالباً invalid parameters للحساب التجريبي)
      // في وضع الديمو نعرض رسالة خاصة، وليس "حدث خطأ غير متوقع"
      if (_isDemoUser(_userId, _isDemo)) {
        _showInfo(
          'هذا حساب تجريبي — لا يمكن تعديل المفضلة.',
          title: 'حساب تجريبي',
        );
      } else {
        _showUserError(_friendlyMessage(e), onRetry: () => toggleFavorite());
      }
    }
  }

  Future<void> checkFavorite() async {
    if (_userId == null || _isDemo) return;
    try {
      final r = await _api.get(
        'get_favorites.php',
        params: {'user_id': '$_userId', 'item_id': '${item.id}'},
      );
      if (r is Map) {
        final ok =
            (r['ok'] == true) ||
            ('${r['ok']}'.toLowerCase() == '1') ||
            ('${r['status']}'.toLowerCase() == 'ok');
        final isFavResp =
            (r['is_favorite'] == true) ||
            ('${r['is_favorite']}'.toLowerCase() == '1') ||
            ('${r['favorite']}'.toLowerCase() == '1');
        if (ok && isFavResp) isFavorite.value = true;
      }
    } catch (_) {}
  }

  double get additionsCost =>
      additions.where((e) => e.selected).fold(0.0, (s, e) => s + e.price);

  double get unitTotal => (item.price) + additionsCost;

  double get total => unitTotal * qty.value;

  Future<void> addToCart() async {
    // 🧱 منع الإضافة في وضع الحساب التجريبي (مع رسالة واضحة)
    lastAddSuccess.value = false;

    if (await _checkDemoBlock("إضافة المنتج للسلة")) {
      lastAddSuccess.value = false;
      return;
    }

    if (isAdding.value) return;
    isAdding.value = true;
    try {
      if (!await _ensureUser()) {
        lastAddSuccess.value = false;
        return;
      }

      final selectedAdds = additions
          .where((e) => e.selected)
          .map((e) => e.id)
          .toList();
      final selectedAddNames = additions
          .where((e) => e.selected)
          .map((e) => e.name)
          .toList();
      final selectedRems = removals
          .where((e) => e.selected)
          .map((e) => e.id)
          .toList();

      final res = await _api.postForm('add_to_cart.php', {
        'user_id': '$_userId',
        'item_id': '${item.id}',
        'quantity': '${qty.value}',
        'qty': '${qty.value}',
        'additions': selectedAdds.join(','),
        'removals': selectedRems.join(','),
        'selected_components': jsonEncode(selectedAddNames),
        'components': jsonEncode(selectedAddNames),
      });

      // ignore: unnecessary_type_check
      if (res is Map && (res['ok'] == true || '${res['ok']}' == '1')) {
        // تحديث عداد السلة فقط للحساب الحقيقي
        final cart = Get.isRegistered<CartController>()
            ? Get.find<CartController>()
            : null;
        await cart?.load();

        if (!_isDemoUser(_userId, _isDemo)) {
          _showSnack(
            bg: const Color(0xFF065F46),
            title: 'تمت الإضافة',
            msg: 'تمت إضافة المنتج إلى السلة بنجاح.',
            actionLabel: 'اذهب للسلة',
            onAction: () => Get.toNamed('/cart'),
            seconds: 4,
          );
        }
        lastAddSuccess.value = true;
      } else {
        lastAddSuccess.value = false;
      }
    } catch (e) {
      // في وضع الديمو نعرض رسالة خاصة
      lastAddSuccess.value = false;
      if (_isDemoUser(_userId, _isDemo)) {
        _showInfo(
          'هذا حساب تجريبي — لا يمكن إضافة المنتج للسلة.',
          title: 'حساب تجريبي',
        );
      } else {
        _showUserError(_friendlyMessage(e), onRetry: () => addToCart());
      }
    } finally {
      isAdding.value = false;
    }
  }

  Future<void> _refreshAvgFromServer() async {
    try {
      final res = await _api.get(
        'receiver_get_items.php',
        params: {'item_id': '${item.id}'},
      );

      Map<String, dynamic>? m;
      if (res is List && res.isNotEmpty && res.first is Map) {
        m = Map<String, dynamic>.from(res.first as Map);
      } else if (res is Map &&
          res['items'] is List &&
          (res['items'] as List).isNotEmpty) {
        m = Map<String, dynamic>.from((res['items'] as List).first as Map);
      }

      if (m != null) {
        // 🆕 نقرأ rating أو avg_rating، ونحدّث فقط لو القيمة > 0
        final r =
            double.tryParse('${m['rating'] ?? m['avg_rating'] ?? 0}') ?? 0.0;

        if (r > 0) {
          avgRating.value = r;
        }
        // لو السيرفر رجّع 0 أو فاضي → نخلي القيمة القديمة كما هي
      }
    } catch (_) {}
  }

  Future<void> submitRating(String? comment) async {
    if (await _checkDemoBlock("إرسال التقييم")) return;

    if (ratingBusy.value) return;
    if (!await _ensureUser()) return;

    ratingBusy.value = true;
    ratingMsg.value = '';
    try {
      final res = await _api.post(
        'rate_item.php',
        body: {
          'user_id': '$_userId',
          'item_id': '${item.id}',
          'stars': '${selectedStars.value}',
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );

      if (res is Map && (res['ok'] == true || '${res['ok']}' == '1')) {
        final newAvg = double.tryParse('${res['avg_rating'] ?? ''}');
        if (newAvg != null && newAvg > 0) {
          avgRating.value = newAvg;
        } else {
          await _refreshAvgFromServer();
        }
        ratingMsg.value = 'تم حفظ تقييمك بنجاح';
        _showSuccess('شكراً لمشاركتك رأيك!');
      } else {
        ratingMsg.value = 'تعذّر حفظ التقييم';
        _showInfo('تعذّر حفظ التقييم حالياً.');
      }
    } catch (e) {
      ratingMsg.value = _friendlyMessage(e);
      _showUserError(ratingMsg.value, onRetry: () => submitRating(comment));
    } finally {
      ratingBusy.value = false;
    }
  }

  Future<void> fetchComments() async {
    loadingComments.value = true;
    try {
      final res = await _api.get(
        'get_item_comments.php',
        params: {'item_id': '${item.id}'},
      );

      List list = const [];
      if (res is List) {
        list = res;
      } else if (res is Map && res['comments'] is List) {
        list = res['comments'];
      }

      final parsed = list
          .map((e) => ItemComment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      comments.assignAll(parsed);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('fetchComments error: $e');
      }
    } finally {
      loadingComments.value = false;
    }
  }

  Future<void> submitComment(String text) async {
    if (await _checkDemoBlock("إضافة تعليق")) return;

    final content = text.trim();
    if (content.isEmpty) {
      _showInfo('اكتب تعليقاً أولاً');
      return;
    }
    if (commentBusy.value) return;
    if (!await _ensureUser()) return;

    commentBusy.value = true;
    try {
      final res = await _api.post(
        'add_item_comment.php',
        body: {
          'user_id': '$_userId',
          'item_id': '${item.id}',
          'comment': content,
        },
      );

      if (res is Map &&
          (res['ok'] == true ||
              '${res['ok']}'.toLowerCase() == '1' ||
              '${res['status']}'.toString().toLowerCase() == 'success')) {
        _showSuccess('تم إضافة تعليقك بنجاح');
        await fetchComments();
      } else {
        final err =
            (res is Map ? '${res['error'] ?? res['message'] ?? ''}' : '')
                .toString()
                .trim();
        if (err.isNotEmpty) {
          _showUserError(err);
        } else {
          _showInfo('تعذّر حفظ التعليق حالياً.');
        }
      }
    } catch (e) {
      _showUserError(_friendlyMessage(e), onRetry: () => submitComment(text));
    } finally {
      commentBusy.value = false;
    }
  }
}
