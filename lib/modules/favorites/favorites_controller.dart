// lib/modules/favorites/favorites_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mandena/core/api_service.dart';
import 'package:mandena/core/session.dart';
import 'package:mandena/modules/branch/branch_controller.dart'
    show BranchController;

import '../../app_routes.dart';
import '../../data/models/item.dart';

class FavoritesController extends GetxController {
  final _api = ApiService();

  final isBusy = false.obs;
  final favIds = <int>{}.obs;
  final favorites = <Map<String, dynamic>>[].obs;

  int? _userId;

  final GetStorage _box = GetStorage();
  static const String _favCachePrefix = 'favorites_cache_v1_';

  // ===================== رسائل ودّية + Snackbar أنيق ======================
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
      return '⚠️ لا يوجد اتصال بالإنترنت.\nتحقّق من الشبكة ثم أعد المحاولة.';
    }
    if (t.contains('timeout') ||
        t.contains('timed out') ||
        t.contains('deadline exceeded')) {
      return '⏳ انتهت مهلة الاتصال.\nحاول مجدداً بعد لحظات.';
    }
    if (t.contains('handshakeexception') ||
        t.contains('certificate') ||
        t.contains('ssl')) {
      return '🔐 مشكلة أمان مؤقتة أثناء الاتصال بالخادم.\nيرجى المحاولة لاحقاً.';
    }
    if (t.contains('formatexception') ||
        t.contains('unexpected character') ||
        t.contains('json')) {
      return '⚠️ حدث خلل في البيانات المستلمة.\nسنحاول إصلاحه، جرّب لاحقاً.';
    }
    return 'حدث خطأ غير متوقع.\nيرجى المحاولة لاحقاً.';
  }
  // ======================================================================

  int _currentBranchId() {
    try {
      if (Get.isRegistered<BranchController>()) {
        return Get.find<BranchController>().selectedBranchId.value;
      }
    } catch (_) {}
    return 0;
  }

  String _favKey() =>
      '$_favCachePrefix${_userId ?? 0}_branch_${_currentBranchId()}';

  void _cacheFavorites() {
    try {
      final jsonStr = jsonEncode(favorites.toList());
      _box.write(_favKey(), jsonStr);
    } catch (_) {}
  }

  void _loadCached() {
    if (_userId == null) return;
    try {
      final raw = _box.read(_favKey());
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          favorites.assignAll(list);
          favIds
            ..clear()
            ..addAll(
              list.map(
                (e) => int.tryParse('${e['item_id'] ?? e['id'] ?? 0}') ?? 0,
              ),
            );
        }
      }
    } catch (_) {
      // تجاهل أي مشكلة بالكاش
    }
  }

  Future<void> clearForBranchChange() async {
    await switchBranchContext();
  }

  Future<void> switchBranchContext() async {
    favorites.clear();
    favIds.clear();

    if (_userId != null && _userId! > 0) {
      _loadCached();
      await load();
    }

    update();
  }

  bool isFavorite(int itemId) => favIds.contains(itemId);

  void markFavoriteAdded(int itemId, {Map<String, dynamic>? itemData}) {
    favIds.add(itemId);

    if (itemData != null) {
      final normalized = Map<String, dynamic>.from(itemData);
      normalized['item_id'] =
          normalized['item_id'] ?? normalized['id'] ?? itemId;

      final index = favorites.indexWhere(
        (e) => (int.tryParse('${e['item_id'] ?? e['id'] ?? 0}') ?? 0) == itemId,
      );

      if (index >= 0) {
        favorites[index] = normalized;
      } else {
        favorites.insert(0, normalized);
      }
    }

    favorites.refresh();
    favIds.refresh();
    _cacheFavorites();
    update();
  }

  void markFavoriteRemoved(int itemId) {
    favIds.remove(itemId);
    favorites.removeWhere(
      (e) => (int.tryParse('${e['item_id'] ?? e['id'] ?? 0}') ?? 0) == itemId,
    );
    favorites.refresh();
    favIds.refresh();
    _cacheFavorites();
    update();
  }

  Future<void> toggleFromHome(ItemModel item) async {
    final itemId = item.id;
    final wasFav = isFavorite(itemId);
    await toggle(itemId);

    if (!wasFav && isFavorite(itemId)) {
      markFavoriteAdded(itemId, itemData: item.toJson());
    } else if (wasFav && !isFavorite(itemId)) {
      markFavoriteRemoved(itemId);
    }
  }

  @override
  void onInit() {
    super.onInit();
    bindToCurrentUser(); // تحميل أولي
  }

  /// ← تستدعيها بعد أي Login/Logout
  Future<void> bindToCurrentUser() async {
    _userId = await Session.userId();
    favorites.clear();
    favIds.clear();
    if (_userId != null && _userId! > 0) {
      // أولاً نحاول نقرأ من الكاش لعرض فوري
      _loadCached();
      // ثم نحدّث من السيرفر
      await load();
    }
    update();
  }

  Future<void> load() async {
    if (_userId == null) return;
    isBusy.value = true;
    try {
      final r = await _api.get(
        'get_favorites.php',
        params: {'user_id': '$_userId', 'branch_id': '${_currentBranchId()}'},
      );
      if (r['ok'] == true) {
        final list = (r['favorites'] as List).cast<Map<String, dynamic>>();
        favorites.assignAll(list);
        favIds
          ..clear()
          ..addAll(list.map((e) => int.tryParse('${e['item_id']}') ?? 0));

        // 🔹 حفظ في الكاش للمستخدم الحالي
        _cacheFavorites();
      } else {
        _showInfo('تعذّر تحميل المفضلة مؤقتاً.');
      }
    } catch (e) {
      _showUserError(_friendlyMessage(e), onRetry: () => load());
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> toggle(int itemId) async {
    if (_userId == null) {
      _showInfo('الرجاء تسجيل الدخول أولاً');
      return;
    }

    final wasFav = favIds.contains(itemId);

    // تفادي نقرات متتالية أثناء التنفيذ
    if (isBusy.value) return;
    isBusy.value = true;

    try {
      if (wasFav) {
        // تفاؤلي: حدث الواجهة سريعاً
        favIds.remove(itemId);
        final old = favorites.toList();
        favorites.removeWhere(
          (e) => (int.tryParse('${e['item_id']}') ?? 0) == itemId,
        );

        try {
          await _api.post(
            'remove_favorite.php',
            body: {
              'user_id': '$_userId',
              'item_id': '$itemId',
              'branch_id': '${_currentBranchId()}',
            },
          );
          _showInfo('أُزيل من المفضلة', title: 'تم');
          _cacheFavorites();
        } catch (e) {
          // تراجع عن التفاؤلي
          favIds.add(itemId);
          favorites.assignAll(old);
          rethrow;
        }
      } else {
        try {
          await _api.post(
            'add_favorite.php',
            body: {
              'user_id': '$_userId',
              'item_id': '$itemId',
              'branch_id': '${_currentBranchId()}',
            },
          );
          // نعيد التحميل لضمان التزامن مع السيرفر
          await load();
          _showSuccess('أُضيف إلى المفضلة');
        } catch (e) {
          rethrow;
        }
      }
    } catch (e) {
      _showUserError(_friendlyMessage(e), onRetry: () => toggle(itemId));
    } finally {
      isBusy.value = false;
    }
  }

  // ====== تحويل خريطة المفضلة إلى ItemModel بشكل آمن ======
  ItemModel _mapToItem(Map<String, dynamic> m) {
    final id = int.tryParse('${m['item_id'] ?? m['id'] ?? 0}') ?? 0;
    final name = (m['name'] ?? m['item_name'] ?? '').toString();
    final desc = (m['description'] ?? m['item_description'] ?? '').toString();
    final img = (m['image_url'] ?? m['imageUrl'] ?? m['item_image'] ?? '')
        .toString();
    final price =
        double.tryParse('${m['price'] ?? m['item_price'] ?? 0}') ?? 0.0;
    final discount = (m['discount'] ?? m['item_discount'])?.toString();
    final categoryId =
        int.tryParse('${m['category_id'] ?? m['cat_id'] ?? 0}') ?? 0;

    final dynamic isActiveValue = (() {
      final v = m['is_active'] ?? m['active'] ?? m['status'] ?? '1';
      final s = v?.toString().toLowerCase();
      if (s == '1' || s == 'true' || s == 'yes') return true;
      if (s == '0' || s == 'false' || s == 'no') return false;
      return true;
    })();

    final dynamic quotaUsed =
        int.tryParse(
          '${m['quota_used'] ?? m['quotaUsed'] ?? m['quota'] ?? 0}',
        ) ??
        double.tryParse(
          '${m['quota_used'] ?? m['quotaUsed'] ?? m['quota'] ?? 0}',
        ) ??
        0;

    return ItemModel(
      id: id,
      name: name,
      description: desc,
      imageUrl: img,
      price: price,
      discount: discount,
      categoryId: categoryId,
      isActive: isActiveValue,
      quotaUsed: quotaUsed,
    );
  }

  /// ——— فتح تفاصيل الصنف من شاشة المفضلة ———
  void openFavDetail(Map<String, dynamic> favMap) {
    final item = _mapToItem(favMap);
    Get.toNamed(AppRoutes.itemDetail, arguments: item.toJson());
  }
}
