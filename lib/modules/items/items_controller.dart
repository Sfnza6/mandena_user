// lib/modules/items/items_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../core/api_service.dart';
import '../../data/models/item.dart';
import '../../data/repositories/items_repository.dart';
import '../../app_routes.dart';
import '../../home/widgets/hero_tags.dart';

class ItemsController extends GetxController {
  final ItemsRepository _repo = ItemsRepository(ApiService());

  // حالة/قوائم
  final loading = false.obs;
  final items = <ItemModel>[].obs;
  final filtered = <ItemModel>[].obs;

  // فلترة وبحث
  final searchCtrl = TextEditingController();
  final RxnInt activeCategoryId = RxnInt();
  final pageTitle = 'الأصناف'.obs;

  // تخزين للكاش
  final GetStorage _box = GetStorage();
  static const String _itemsCachePrefix = 'items_cache_v1_';

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
    String title = 'تعذّر تحميل الأصناف',
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
      return '⏳ انتهت مهلة الاتصال.\nجرّب مرة ثانية بعد لحظات.';
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

  String _cacheKeyFor(int? categoryId) =>
      '$_itemsCachePrefix${categoryId ?? 0}';

  void _cacheItems(List<ItemModel> list, {int? categoryId}) {
    try {
      final data = list.map((e) => e.toJson()).toList();
      final jsonStr = jsonEncode(data);
      _box.write(_cacheKeyFor(categoryId), jsonStr);
    } catch (_) {}
  }

  void _loadCached({int? categoryId}) {
    try {
      final raw = _box.read(_cacheKeyFor(categoryId));
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded
              .map((e) => ItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          items.assignAll(list);
          _applyFilters();
        }
      }
    } catch (_) {
      // تجاهل أي مشكلة بالكاش
    }
  }

  @override
  void onInit() {
    super.onInit();
    // تحميل باراميترات القسم
    final args = Get.arguments;
    if (args is Map) {
      activeCategoryId.value = args['categoryId'] as int?;
      final name = (args['categoryName'] ?? '').toString();
      if (name.isNotEmpty) pageTitle.value = name;
    }
  }

  @override
  void onReady() {
    super.onReady();
    // أولاً نحاول نعرض من الكاش (إن وجد)
    _loadCached(categoryId: activeCategoryId.value);
    // ثم نحدّث من الـ API
    fetchItems(categoryId: activeCategoryId.value);
  }

  void onSearchChanged(String _) => _applyFilters();

  void _applyFilters() {
    final q = searchCtrl.text.trim();
    final cat = activeCategoryId.value;

    Iterable<ItemModel> base = items;
    if (cat != null) base = base.where((e) => e.categoryId == cat);
    if (q.isNotEmpty) {
      base = base.where(
        (e) =>
            e.name.toLowerCase().contains(q.toLowerCase()) ||
            e.description.toLowerCase().contains(q.toLowerCase()),
      );
    }
    filtered.assignAll(base);
  }

  Future<void> fetchItems({int? categoryId}) async {
    try {
      loading(true);
      final list = await _repo.fetchItems(categoryId: categoryId);
      items.assignAll(list);
      _applyFilters(); // يفلتر محليًا لو السيرفر رجّع كل الأصناف

      // 🔹 حفظ في الكاش حسب القسم
      _cacheItems(list, categoryId: categoryId);

      if (items.isEmpty) {
        _showInfo('لا توجد أصناف حالياً في هذا القسم.');
      }
    } catch (e) {
      items.clear();
      filtered.clear();
      _showUserError(
        _friendlyMessage(e),
        onRetry: () => fetchItems(categoryId: categoryId),
      );
    } finally {
      loading(false);
    }
  }

  /// ——— فتح تفاصيل الصنف من شاشة الأصناف ———
  void openDetail(ItemModel item, {String? heroTag}) {
    final tag = heroTag ?? itemHeroTagFromModel(item, scope: 'items-grid');
    Get.toNamed(
      AppRoutes.itemDetail,
      arguments: withItemHeroArg(item.toJson(), tag),
    );
  }
}
