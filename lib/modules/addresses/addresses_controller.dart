import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/home/home_controller.dart';

import '../../core/session.dart';
import '../../core/api_service.dart';
import '../../data/models/address.dart';
import '../../data/repositories/address_repository.dart';

// ✅ لإبلاغ الهوم عند تغيير العنوان الافتراضي
import 'package:get_storage/get_storage.dart'; // ✅ كاش بسيط للعناوين

class AddressesController extends GetxController {
  late final AddressRepository repo;

  AddressesController() {
    // ضمان وجود ApiService حتى لو ما تسجّل في AppBinding
    final api = Get.isRegistered<ApiService>()
        ? Get.find<ApiService>()
        : Get.put<ApiService>(ApiService(), permanent: true);
    repo = AddressRepository(api);
  }

  /// حالة التحميل والحفظ
  final loading = false.obs;
  final saving = false.obs;

  /// قائمة العناوين
  final items = <Address>[].obs;

  // ✅✅ تعديل بسيط: نخزن pickMode في Rx مرة واحدة
  final pickModeRx = false.obs;

  /// وضع اختيار العنوان (من شاشة أخرى)
  bool get pickMode => pickModeRx.value;

  /// معرف المستخدم
  int userId = 0;

  /// 🆕 هل المستخدم حساب تجريبي/زائر؟
  final isGuest = false.obs;

  /// قفل لمنع النقر المتكرر أثناء التعيين كافتراضي
  final isSettingDefault = false.obs;

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

  // ignore: unused_element
  String _friendlyHttp(int code) {
    if (code == 400) return 'البيانات غير مكتملة أو غير صالحة.';
    if (code == 401 || code == 403) {
      return '⛔ غير مصرح. سجّل الدخول ثم حاول مجدداً.';
    }
    if (code == 404) return '🔎 الخدمة غير متاحة حالياً.';
    if (code == 409) return 'العنوان موجود مسبقاً.';
    if (code == 429) {
      return '🚦 محاولات كثيرة خلال وقت قصير. انتظر قليلاً ثم أعد المحاولة.';
    }
    if (code >= 500 && code <= 504) {
      return '🛠️ الخدمة غير متاحة مؤقتاً. نقوم بالصيانة أو يوجد ضغط كبير.';
    }
    return 'تعذّر التواصل مع الخادم (HTTP $code). حاول لاحقاً.';
  }

  // ======================================================================

  // =================== كاش العناوين لكل مستخدم ===================
  late final GetStorage _box;
  static const int _cacheMaxAgeMinutes = 5;

  String get _cacheKey => 'addresses_user_${userId}_v1';
  String get _cacheTsKey => '${_cacheKey}_ts';

  void _initCacheBox() {
    try {
      // في الغالب GetStorage.init() معمول في main، لو مش معمول ما يضر
      _box = GetStorage();
    } catch (_) {
      _box = GetStorage();
    }
  }

  bool _isCacheFresh() {
    try {
      final ts = _box.read(_cacheTsKey);
      if (ts is int) {
        final savedAt = DateTime.fromMillisecondsSinceEpoch(ts);
        final diff = DateTime.now().difference(savedAt).inMinutes;
        return diff < _cacheMaxAgeMinutes;
      }
    } catch (_) {}
    return false;
  }

  void _loadCachedAddresses() {
    if (userId == 0) return;
    try {
      if (!_isCacheFresh()) return;
      final raw = _box.read(_cacheKey);
      if (raw is List) {
        final list = raw.map((e) {
          final m = Map<String, dynamic>.from(e as Map);
          return Address(
            id: m['id'] is int
                ? m['id'] as int
                : int.tryParse('${m['id'] ?? 0}') ?? 0,
            userId: m['userId'] is int
                ? m['userId'] as int
                : int.tryParse('${m['userId'] ?? m['user_id'] ?? 0}') ?? 0,
            label: (m['label'] ?? '').toString(),
            lat: (m['lat'] is num)
                ? (m['lat'] as num).toDouble()
                : double.tryParse('${m['lat'] ?? 0}') ?? 0,
            lng: (m['lng'] is num)
                ? (m['lng'] as num).toDouble()
                : double.tryParse('${m['lng'] ?? 0}') ?? 0,
            addressText: (m['addressText'] ?? m['address_text'] ?? '')
                .toString(),
            isDefault: m['isDefault'] is int
                ? m['isDefault'] as int
                : int.tryParse('${m['isDefault'] ?? m['is_default'] ?? 0}') ??
                      0,
            createdAt: (m['createdAt'] ?? m['created_at'] ?? '').toString(),
          );
        }).toList();
        items.assignAll(list);
      }
    } catch (_) {
      // أي خطأ في الكاش نتجاهله بصمت
    }
  }

  void _cacheAddresses(List<Address> list) {
    if (userId == 0) return;
    try {
      final data = list
          .map(
            (a) => {
              'id': a.id,
              'userId': a.userId,
              'label': a.label,
              'lat': a.lat,
              'lng': a.lng,
              'addressText': a.addressText,
              'isDefault': a.isDefault,
              'createdAt': a.createdAt,
            },
          )
          .toList();
      _box.write(_cacheKey, data);
      _box.write(_cacheTsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // تجاهل أي خطأ في التخزين
    }
  }
  // =====================================================

  @override
  void onInit() {
    super.onInit();
    _initCacheBox();

    // ✅✅ تعديل: قراءة pickMode من arguments مرة واحدة وتخزينه
    try {
      pickModeRx.value = (Get.arguments?['pickMode'] ?? false) == true;
    } catch (_) {
      pickModeRx.value = false;
    }

    _initUser();
  }

  Future<void> _initUser() async {
    try {
      userId = await Session.userId() ?? 0;
      isGuest.value = (userId == 0); // 🆕 ضبط فلاغ الحساب التجريبي
      debugPrint('[AddressesController] userId=$userId, pickMode=$pickMode');
    } catch (e) {
      debugPrint('[AddressesController] Session.userId error: $e');
      userId = 0;
      isGuest.value = true;
    }

    // 👇 حالة الحساب التجريبي / الزائر
    if (userId == 0) {
      items.clear();
      _showInfo(
        'أنت حالياً تستخدم حساباً تجريبياً.\n'
        'لا يمكن حفظ أو استخدام عناوين للتوصيل في هذا الوضع.\n'
        'من فضلك سجّل الدخول أو أنشئ حساباً جديداً لتفعيل العناوين.',
        title: 'العناوين في الحساب التجريبي',
      );
      return;
    }

    // أولاً حاول نقرأ من الكاش (لو متوفر وجديد)
    _loadCachedAddresses();

    // ثم حمّل من السيرفر لتحديث البيانات + إظهار رد واضح عند الدخول
    await load(showResultMessage: true);
  }

  /// تحميل عناوين المستخدم
  Future<void> load({bool showResultMessage = false}) async {
    loading.value = true;
    try {
      debugPrint('[AddressesController] fetching addresses for user=$userId');
      final list = await repo.fetch(userId);
      items.assignAll(list);
      debugPrint('[AddressesController] fetched ${list.length} address(es)');

      // ✅ خزّن آخر عناوين في الكاش
      _cacheAddresses(list);

      // ✅ رسالة واضحة عند الدخول (أو عند الاستدعاء مع showResultMessage)
      if (showResultMessage) {
        if (items.isEmpty) {
          _showInfo(
            'لا توجد عناوين محفوظة حتى الآن.\nاستخدم زر "إضافة عنوان جديد".',
            title: 'العناوين',
          );
        } else {
          _showSuccess(
            'تم تحميل عناوينك بنجاح.\nيمكنك الآن اختيار عنوان للتوصيل.',
            title: 'العناوين',
          );
        }
      }
    } catch (e, st) {
      // رسالة ودّية بدل التقنية
      _showUserError(_friendlyMessage(e), onRetry: () => load());
      debugPrint('[AddressesController.load] $e');
      debugPrint(st.toString());
    } finally {
      loading.value = false;
    }
  }

  /// فتح شاشة تعديل/إضافة (لو عندك شاشة مستقلة غير الـ bottom sheet)
  Future<void> addOrEdit([Address? existing]) async {
    // 🛑 منع الحساب التجريبي من إضافة/تعديل العناوين (احتياطاً لو حاول من مكان آخر)
    if (userId == 0) {
      _showInfo(
        'لا يمكن إضافة أو تعديل العناوين أثناء استخدام الحساب التجريبي.\n'
        'يرجى تسجيل الدخول بحساب حقيقي لتفعيل هذه الميزة.',
        title: 'الحساب التجريبي',
      );
      return;
    }

    final result = await Get.toNamed(
      '/address_edit',
      arguments: {'address': existing},
    );
    if (result == true) await load();
  }

  /// حذف عنوان
  Future<void> delete(Address a) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد الحذف', textDirection: TextDirection.rtl),
        content: Text(
          'هل تريد حذف "${a.label}"؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      debugPrint('[AddressesController] delete id=${a.id} user=$userId');
      await repo.delete(a.id, userId);
      items.removeWhere((x) => x.id == a.id);
      _showSuccess('تم حذف العنوان');

      // حدّث الكاش بعد الحذف
      _cacheAddresses(items.toList());
    } catch (e, st) {
      _showUserError(_friendlyMessage(e), onRetry: () => delete(a));
      debugPrint('[AddressesController.delete] $e');
      debugPrint(st.toString());
    }
  }

  /// اختيار العنوان عند وضع الاختيار
  void pick(Address a) {
    if (pickMode) {
      debugPrint('[AddressesController] pick => ${a.id}');
      Get.back(result: a);
    }
  }

  // مُساعد داخلي: يرجّع نسخة جديدة من Address مع isDefault = flag
  Address _withDefault(Address src, int flag) => Address(
    id: src.id,
    userId: src.userId,
    label: src.label,
    lat: src.lat,
    lng: src.lng,
    addressText: src.addressText,
    isDefault: flag,
    createdAt: src.createdAt,
  );

  /// تعيين كعنوان افتراضي (تحديث لحظي + تراجع عند الفشل)
  Future<void> setDefault(Address a) async {
    if (isSettingDefault.value) return; // منع الضغط المتكرر
    isSettingDefault.value = true;

    // تحديث فوري للواجهة (Optimistic UI)
    final oldIdx = items.indexWhere((e) => e.isDefault == 1);
    final newIdx = items.indexWhere((e) => e.id == a.id);

    if (newIdx == -1) {
      isSettingDefault.value = false;
      return;
    }

    final prevId = (oldIdx >= 0) ? items[oldIdx].id : null;

    if (oldIdx >= 0) items[oldIdx] = _withDefault(items[oldIdx], 0);
    items[newIdx] = _withDefault(items[newIdx], 1);
    items.refresh();

    try {
      debugPrint(
        '>>> set_default_address: user=$userId, id=${a.id}, prev=$prevId',
      );
      await repo.setDefault(a.id, userId);
      _showSuccess('تم التعيين كعنوان افتراضي');

      // إعادة تحميل هادئة لضمان التطابق مع السيرفر
      await load();

      // 🆕 إبلاغ الهوم بأن العنوان الافتراضي تغيّر
      try {
        final home = Get.find<HomeController>();
        home.refreshDefaultAddressFromOutside();
      } catch (e) {
        debugPrint(
          '[AddressesController.setDefault] no HomeController found: $e',
        );
      }
    } catch (e, st) {
      // تراجع إذا فشل الطلب
      if (oldIdx >= 0) items[oldIdx] = _withDefault(items[oldIdx], 1);
      items[newIdx] = _withDefault(items[newIdx], 0);
      items.refresh();

      _showUserError(_friendlyMessage(e), onRetry: () => setDefault(a));
      debugPrint('[AddressesController.setDefault] $e');
      debugPrint(st.toString());
    } finally {
      isSettingDefault.value = false;
    }
  }
}
