import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/models/offer.dart';
import '../data/models/category.dart';
import '../data/models/item.dart';
import '../data/repositories/home_repository.dart';
import '../core/api_service.dart';
import '../core/session.dart';
import '../core/app_colors.dart';

// 🔹 ربط مع كنترولر السلة
import '../modules/cart/cart_controller.dart';
import '../modules/favorites/favorites_controller.dart';
// 🔹 موديل العنوان لاستخدامه عند تأكيد المكان من الهوم
import '../data/models/address.dart';

class HomeController extends GetxController {
  final repo = HomeRepository();
  final _api = ApiService();

  /// اسم العنوان الظاهر في الهيدر (يُحمَّل من السيرفر)
  final location = ''.obs;

  final loadingOffers = false.obs;
  final loadingCats = false.obs;
  final loadingMost = false.obs;
  final loadingTop = false.obs;
  final loadingAddress = false.obs; // تحميل عنوان الهيدر

  final offers = <OfferModel>[].obs;
  final categories = <CategoryModel>[].obs;
  final mostOrdered = <ItemModel>[].obs;
  final topRated = <ItemModel>[].obs;

  // =================== البحث ===================
  final searchCtrl = TextEditingController();
  final searchQuery = ''.obs;
  final searchResults = <ItemModel>[].obs;
  final loadingSearch = false.obs;

  Timer? _searchDebounce;
  int _searchSerial = 0;

  bool get isSearching => searchQuery.value.trim().isNotEmpty;

  void onSearchChanged(String value) {
    final q = value.trim();
    searchQuery.value = q;
    _applySearchLocal();

    _searchDebounce?.cancel();
    if (q.isEmpty) {
      loadingSearch.value = false;
      searchResults.clear();
      return;
    }

    // فلترة فورية محلياً، وبعدها طلب خفيف من السيرفر حتى تظهر كل الأصناف وليس الرائج فقط.
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      _searchFromServer(q);
    });
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    searchCtrl.clear();
    searchQuery.value = '';
    searchResults.clear();
    loadingSearch.value = false;
  }

  String _canon(String v) {
    return v
        .toLowerCase()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ـ', '')
        .trim();
  }

  bool _matchesItem(ItemModel item, String q) {
    final key = _canon(q);
    if (key.isEmpty) return false;
    return _canon(item.name).contains(key) ||
        _canon(item.description).contains(key);
  }

  void _applySearchLocal() {
    final q = searchQuery.value.trim();
    if (q.isEmpty) {
      searchResults.clear();
      return;
    }

    final Map<int, ItemModel> merged = {};
    for (final it in mostOrdered) {
      merged[it.id] = it;
    }
    for (final it in topRated) {
      merged[it.id] = it;
    }

    final result = merged.values
        .where((item) => _matchesItem(item, q))
        .toList();
    _sortSearchResults(result, q);
    searchResults.assignAll(result);
  }

  void _sortSearchResults(List<ItemModel> result, String q) {
    final key = _canon(q);
    result.sort((a, b) {
      final an = _canon(a.name);
      final bn = _canon(b.name);
      final aStarts = an.startsWith(key) ? 0 : 1;
      final bStarts = bn.startsWith(key) ? 0 : 1;
      if (aStarts != bStarts) return aStarts.compareTo(bStarts);
      return an.compareTo(bn);
    });
  }

  Future<void> _searchFromServer(String q) async {
    final mySerial = ++_searchSerial;
    try {
      loadingSearch.value = true;
      final list = await repo.searchItems(q);

      if (mySerial != _searchSerial) return;
      if (searchQuery.value.trim() != q) return;

      final filtered = list.where((item) => _matchesItem(item, q)).toList();
      _sortSearchResults(filtered, q);
      searchResults.assignAll(filtered);
    } catch (_) {
      // نترك النتائج المحلية كما هي، حتى لا يختفي البحث عند ضعف الإنترنت.
    } finally {
      if (mySerial == _searchSerial) {
        loadingSearch.value = false;
      }
    }
  }

  // =================== إضافات إدارة الأخطاء/الإنترنت ===================

  final netError = false.obs; // هل يوجد خطأ شبكي/عام؟
  final netMsg = '⚠️ لا يوجد اتصال بالإنترنت'.obs; // الرسالة المعروضة

  DateTime? _lastSnackAt;
  static const _snackThrottle = Duration(seconds: 4);

  /// 🆕 فلاغ داخلي لضمان أن رسالة "الحساب التجريبي" تظهر مرة واحدة فقط
  bool _demoErrorShown = false;

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

    if (t.contains(' 401') || t.contains('unauthorized')) {
      return '🔒 يلزم تسجيل الدخول للمتابعة.';
    }

    if (t.contains(' 403') || t.contains('forbidden')) {
      return '⛔ الوصول مرفوض. يرجى المحاولة بحساب مصرح.';
    }

    if (t.contains(' 404') || t.contains('not found')) {
      return '🔎 لم يتم العثور على المطلوب حالياً.';
    }

    if (t.contains(' 500') ||
        t.contains(' 502') ||
        t.contains(' 503') ||
        t.contains(' 504') ||
        t.contains('internal server error') ||
        t.contains('bad gateway') ||
        t.contains('service unavailable') ||
        t.contains('gateway timeout')) {
      return '🛠️ الخدمة غير متاحة مؤقتاً.\nنقوم بالصيانة أو يوجد ضغط كبير.';
    }

    if (t.contains('formatexception') ||
        t.contains('unexpected character') ||
        t.contains('json')) {
      return '⚠️ حدث خلل في البيانات المستلمة.\nسنحاول إصلاحه، جرّب لاحقاً.';
    }

    if (t.contains('handshakeexception') ||
        t.contains('certificate') ||
        t.contains('ssl')) {
      return '🔐 مشكلة أمان مؤقتة أثناء الاتصال بالخادم.\nيرجى المحاولة لاحقاً.';
    }

    return 'حدث خطأ غير متوقع.\nيرجى المحاولة لاحقاً.';
  }

  void _showUserError(String msg) {
    final now = DateTime.now();

    // 🆕 لو الرسالة خاصة بالحساب التجريبي → لا نظهرها إلا مرة واحدة فقط
    if (msg.contains('حساب تجريبي للتصفح فقط')) {
      if (_demoErrorShown) {
        // تم عرض الرسالة سابقاً في هذه الجلسة، لا نعيدها
        return;
      }
      _demoErrorShown = true;
    }

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
      // 🆕 لون أزرق كحلي مثل باقي رسائل النظام
      backgroundColor: const Color(0xFF0B2148),
      messageText: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تعذّر إتمام العملية',
              style: TextStyle(
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
          retry();
        },
        child: const Text(
          'إعادة المحاولة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      duration: const Duration(seconds: 4),
    );
  }

  void _handleError(Object e) {
    final pretty = _friendlyMessage(e);
    netError.value = true;
    netMsg.value = pretty;
    _showUserError(pretty);
  }

  Future<void> refreshDefaultAddressFromOutside() async {
    try {
      await _loadDefaultAddressFromServer();
    } catch (e) {
      debugPrint('refreshDefaultAddressFromOutside error: $e');
    }
  }

  Future<void> retry() async {
    netError.value = false;
    await refreshAll();
  }

  // =====================================================================

  late final GetStorage _box;

  // مفاتيح الكاش للهوم
  static const String _kOffersKey = 'home_offers_v1';
  static const String _kCatsKey = 'home_cats_v1';
  static const String _kMostKey = 'home_most_v1';
  static const String _kTopKey = 'home_top_v1';

  /// ⏱️ عمر الكاش بالدقائق (تقدر تزيده أو تنقصه)
  static const int _cacheMaxAgeMinutes = 5;

  String _tsKey(String base) => '${base}_ts';

  /// هل هذا الكاش مازال حديثاً بما يكفي للاستخدام؟
  bool _isCacheFresh(String key) {
    try {
      final ts = _box.read(_tsKey(key));
      if (ts is int) {
        final savedAt = DateTime.fromMillisecondsSinceEpoch(ts);
        final diff = DateTime.now().difference(savedAt).inMinutes;
        return diff < _cacheMaxAgeMinutes;
      }
    } catch (_) {}

    // لو ما فيه تايم ستامب (نسخة قديمة من التطبيق) نعتبره صالح
    return true;
  }

  // 🔹 الكنترولر الخاص بالسلة
  late final CartController _cart;

  /// فلاغ داخلي: هل تم تأكيد أن المستخدم في نفس العنوان في هذه الجلسة؟
  bool _addressConfirmedForCart = false;

  /// 🆕 فلاغ داخلي للحساب التجريبي/الزائر
  bool _demoMode = false;
  bool get isDemoMode => _demoMode;

  /// عدد الأصناف في السلة (مجموع الكميات) – يُستخدم في Badge الأيقونة
  int get cartCount {
    try {
      // 🆕 في الحساب التجريبي نظهر دائماً 0 حتى لو كانت السلة تحتوي بيانات قديمة
      if (_demoMode) return 0;

      final list = _cart.cart; // RxList → يحسّ Obx بالتغيير
      int sum = 0;
      for (final e in list) {
        final q = (e['quantity'] as num?)?.toInt() ?? 0;
        sum += q;
      }
      return sum;
    } catch (_) {
      return 0;
    }
  }

  /// 🆕 نخزّن آخر عنوان افتراضي كامل (من الـ API) لاستخدامه عند تأكيد "نعم، في نفس المكان"
  Map<String, dynamic>? _defaultAddressRaw;

  /// 🆕 فحص هل المستخدم الحالي حساب تجريبي/زائر (id=0 أو is_demo/is_guest)
  Future<bool> _isDemoUser() async {
    try {
      final local = await Session.readLoggedIn();
      if (local == null) return false;

      final dynamic rawId = local['id'] ?? local['user_id'] ?? 0;
      final int idNum = (rawId is int) ? rawId : int.tryParse('$rawId') ?? 0;
      final bool guestFlag = local['is_guest'] == true;
      final bool demoFlag = local['is_demo'] == true;

      final v = demoFlag || guestFlag || idNum == 0;
      _demoMode = v; // نحفظه للاستخدام المتكرر
      return v;
    } catch (_) {
      return false;
    }
  }

  @override
  void onInit() {
    super.onInit();

    // 🔹 الحصول على CartController (مُسجّل في initialBinding في main)
    _cart = Get.find<CartController>();

    _initStorage();

    // 🆕 تحديد هل المستخدم الحالي حساب تجريبي
    _isDemoUser().then((isDemo) {
      if (isDemo) {
        // تعيين عنوان تجريبي مباشرة
        if (location.value.trim().isEmpty) {
          setLocationName('عنوان تجريبي', persist: false);
        }
      }
    });

    _loadDefaultAddressFromServer().then((_) => refreshAll());
  }

  /// 🔹 عند جاهزية الشاشة (بعد أول Frame) → نعرض رسالة تأكيد الموقع مرة واحدة
  @override
  void onReady() {
    super.onReady();

    // نخليها بعد شوية عشان نضمن إن الهوم اشتغلت والعنوان حاول يتحمّل
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // 🆕 في الحساب التجريبي: لا نُجبر المستخدم على إضافة عنوان ولا نعرض بوكس "نفس المكان"
        if (await _isDemoUser()) {
          if (location.value.trim().isEmpty) {
            setLocationName('عنوان تجريبي', persist: false);
          }
          return;
        }

        // لو ما فيش عنوان محمّل حاول تجلبه مرة ثانية
        if (location.value.trim().isEmpty) {
          await _loadDefaultAddressFromServer();
        }

        // 🆕 لو ما زال ما فيش عنوان نهائيًا → إجبار المستخدم على إضافة عنوان
        if (location.value.trim().isEmpty) {
          await _forceUserToHaveAddress();
        }

        // لو بعد الإلزام أصبح عنده عنوان، نكمل بالسؤال العادي "هل أنت في نفس المكان؟"
        if (location.value.trim().isEmpty) return;

        // لو ما أكّدش في هذه الجلسة → أظهر السؤال الآن (عند فتح الهوم)
        if (!_addressConfirmedForCart) {
          await _ensureAddressForCart();
        }
      } catch (_) {
        // نتجاهل أي خطأ هنا عشان ما نكسر الهوم
      }
    });
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }

  Future<void> _initStorage() async {
    try {
      await GetStorage.init();
      _box = GetStorage();
    } catch (_) {
      _box = GetStorage();
    }
    _loadCachedHomeData();
  }

  /// حفظ قائمة في التخزين (كاش) كـ JSON + حفظ وقت الحفظ
  void _cacheList(String key, List<Map<String, dynamic>> data) {
    try {
      final jsonStr = jsonEncode(data);
      _box.write(key, jsonStr);
      _box.write(_tsKey(key), DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// تحميل بيانات الهوم من الكاش (فقط لو الكاش حديث)
  void _loadCachedHomeData() {
    try {
      // العروض
      final oStr = _box.read(_kOffersKey);
      if (oStr is String && oStr.isNotEmpty && _isCacheFresh(_kOffersKey)) {
        final decoded = jsonDecode(oStr) as List;
        final list = decoded
            .map((e) => OfferModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        offers.assignAll(list);
      }

      // الأقسام
      final cStr = _box.read(_kCatsKey);
      if (cStr is String && cStr.isNotEmpty && _isCacheFresh(_kCatsKey)) {
        final decoded = jsonDecode(cStr) as List;
        final list = decoded
            .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        categories.assignAll(list);
      }

      // الأكثر طلباً
      final mStr = _box.read(_kMostKey);
      if (mStr is String && mStr.isNotEmpty && _isCacheFresh(_kMostKey)) {
        final decoded = jsonDecode(mStr) as List;
        final list = decoded
            .map((e) => ItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        mostOrdered.assignAll(list);
      }

      // الأعلى تقييماً
      final tStr = _box.read(_kTopKey);
      if (tStr is String && tStr.isNotEmpty && _isCacheFresh(_kTopKey)) {
        final decoded = jsonDecode(tStr) as List;
        final list = decoded
            .map((e) => ItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        topRated.assignAll(list);
      }

      _applySearchLocal();
    } catch (_) {
      // نتجاهل أي خطأ بالكاش بصمت
    }
  }

  Future<void> openAddresses() async {
    // في الحساب التجريبي نسمح له يشوف الشاشة لو عندك منطق خاص،
    // لكن عملياً لن يكون هناك عنوان حقيقي في السيرفر
    await Get.toNamed('/addresses');

    // بعد الرجوع: حمّل العنوان الافتراضي من جديد
    await _loadDefaultAddressFromServer();

    // بعد تعديل العنوان، يحتاج تأكيد جديد للسلة
    _addressConfirmedForCart = false;
  }

  void openSearch() {
    Get.toNamed('/search');
  }

  void setLocationName(String name, {bool persist = true}) {
    final v = name.trim();
    location.value = v;

    if (persist) {
      try {
        _box.write('default_address_name', v);
      } catch (_) {}
    }
  }

  Future<void> _loadDefaultAddressFromServer() async {
    loadingAddress.value = true;
    try {
      // 🆕 في الحساب التجريبي: نستخدم عنواناً افتراضياً فقط بدون طلب من السيرفر
      if (await _isDemoUser()) {
        setLocationName('عنوان تجريبي', persist: false);
        _defaultAddressRaw = null;
        return;
      }

      final uid = await Session.userId();
      if (uid == null || uid == 0) {
        setLocationName('', persist: false);
        _defaultAddressRaw = null;
        return;
      }

      final res = await _api.get(
        'get_user_addresses.php',
        params: {
          'user_id': '$uid',
          't': '${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      dynamic jsonObj;
      try {
        jsonObj = res is String ? jsonDecode(res) : res;
      } catch (_) {
        jsonObj = res;
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
        setLocationName('', persist: false);
        _defaultAddressRaw = null;
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

      // 🆕 حفظ نسخة خام من العنوان الافتراضي لاستخدامها عند تأكيد "نعم، في نفس المكان"
      _defaultAddressRaw = def;

      final name = (def['name'] ?? def['label'] ?? def['title'] ?? '')
          .toString()
          .trim();

      setLocationName(name, persist: true);
    } catch (e) {
      debugPrint('load default address error: $e');

      final cached = _box.read('default_address_name');
      if (cached is String && cached.trim().isNotEmpty) {
        setLocationName(cached, persist: false);
      } else {
        setLocationName('', persist: false);
      }
      _defaultAddressRaw = null;
      _handleError(e);
    } finally {
      loadingAddress.value = false;
    }
  }

  Future<void> handleBranchChanged() async {
    offers.clear();
    categories.clear();
    mostOrdered.clear();
    topRated.clear();
    searchResults.clear();

    try {
      _box.remove(_kOffersKey);
      _box.remove(_kCatsKey);
      _box.remove(_kMostKey);
      _box.remove(_kTopKey);
    } catch (_) {}

    if (Get.isRegistered<FavoritesController>()) {
      await Get.find<FavoritesController>().load();
    }

    await refreshAll();
  }

  Future<void> refreshAll() async {
    netError.value = false;
    try {
      await Future.wait([
        fetchOffers(),
        fetchCategories(),
        fetchMostOrdered(),
        fetchTopRated(),
      ]);
      _applySearchLocal();
    } catch (e) {
      _handleError(e);
    }
  }

  /* ======================= جلب البيانات ======================= */

  Future<void> fetchOffers() async {
    loadingOffers.value = true;
    try {
      final list = await repo.fetchOffers();
      offers.assignAll(list);
      offers.refresh();

      _cacheList(_kOffersKey, list.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('fetchOffers error: $e');
      _handleError(e);
    } finally {
      loadingOffers.value = false;
    }
  }

  Future<void> fetchCategories() async {
    loadingCats.value = true;
    try {
      final list = await repo.fetchCategories();
      categories
        ..assignAll(list)
        ..refresh();
      update();

      _cacheList(_kCatsKey, list.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('fetchCategories error: $e');
      _handleError(e);
    } finally {
      loadingCats.value = false;
    }
  }

  Future<void> fetchMostOrdered() async {
    loadingMost.value = true;
    try {
      final list = await repo.fetchMostOrdered();
      mostOrdered.assignAll(list);
      _applySearchLocal();

      _cacheList(_kMostKey, list.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('fetchMostOrdered error: $e');
      _handleError(e);
    } finally {
      loadingMost.value = false;
    }
  }

  Future<void> fetchTopRated() async {
    loadingTop.value = true;
    try {
      final list = await repo.fetchTopRated();
      topRated.assignAll(list);
      _applySearchLocal();

      _cacheList(_kTopKey, list.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('fetchTopRated error: $e');
      _handleError(e);
    } finally {
      loadingTop.value = false;
    }
  }

  /* ======================= إضافة للسلة من الهوم ======================= */

  int? _extractItemId(ItemModel item) {
    // نستخدم dynamic عشان ما نكسر الكومبايل مهما كان شكل ItemModel
    final dyn = item as dynamic;

    try {
      final v = dyn.id;
      if (v is int) return v;
    } catch (_) {}

    try {
      final v = dyn.itemId;
      if (v is int) return v;
    } catch (_) {}

    try {
      final v = dyn.item_id;
      if (v is int) return v;
    } catch (_) {}

    return null;
  }

  String _extractItemName(ItemModel item) {
    final dyn = item as dynamic;
    try {
      final v = dyn.name;
      if (v is String && v.trim().isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = dyn.title;
      if (v is String && v.trim().isNotEmpty) return v;
    } catch (_) {}
    return 'الصنف';
  }

  /// 🆕 دالة مشتركة لتثبيت العنوان الحالي في السلة
  Future<void> confirmCurrentAddressForCart() async {
    _addressConfirmedForCart = true;

    final currentTitle = location.value.trim();

    try {
      if (_defaultAddressRaw != null) {
        final a = Address.fromJson(_defaultAddressRaw!);
        _cart.setSelectedAddress(a);
      } else {
        _cart.selectedAddressName.value = currentTitle;
      }
    } catch (_) {
      try {
        _cart.selectedAddressName.value = currentTitle;
      } catch (_) {}
    }
  }

  /// ✅ يسأل أول مرة: هل أنت في نفس المكان؟ أو تريد تغيير العنوان؟
  /// يظهر من الأعلى حتى يكون أخف على المستخدم عند بداية التطبيق.
  Future<bool> _ensureAddressForCart() async {
    final currentTitle = location.value.trim();

    // لو ما فيش عنوان أساساً → افتح شاشة العناوين مباشرة
    if (currentTitle.isEmpty) {
      await openAddresses();
      return false;
    }

    // لو سبق وأكد في هذه الجلسة → لا تسأله مرة أخرى
    if (_addressConfirmedForCart) return true;

    bool? answer;

    await Get.dialog<void>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFCF6),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withOpacity(.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.brand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'هل أنت في نفس المكان؟',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'سنتعامل مع هذا العنوان في حساب رسوم التوصيل وتتبع الطلب.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              answer = false;
                              Get.back();
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.brand.withOpacity(.85),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'تغيير المكان',
                              style: TextStyle(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              answer = true;
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brand,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'نعم، في نفس المكان',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(.18),
    );

    if (answer == true) {
      // ✅ تثبيت العنوان في السلة بنفس منطق "نعم في نفس المكان"
      await confirmCurrentAddressForCart();
      return true;
    }

    if (answer == false) {
      await openAddresses();
      return false;
    }

    // نظرياً مش هنوصل لهنا لأن البوكس مش قابل للإغلاق بدون اختيار
    return false;
  }

  /// 🆕 بوكس إجباري يظهر فقط عندما لا يوجد أي عنوان للمستخدم
  Future<void> _forceUserToHaveAddress() async {
    // نكرر لحد ما يصير عنده عنوان فعليًا
    while (true) {
      // نحاول إعادة تحميل العنوان من السيرفر (يمكن يكون أُضيف من جهاز آخر)
      await _loadDefaultAddressFromServer();

      if (location.value.trim().isNotEmpty) {
        // أصبح عنده عنوان → نخرج من الحلقة
        break;
      }

      bool? goAdd;

      await Get.bottomSheet(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFCF6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withOpacity(.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.brand.withOpacity(.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'أضف عنوان التوصيل',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'لا يمكنك إكمال الطلبات بدون إضافة عنوان للتوصيل.\nيرجى إضافة عنوانك الآن للاستمرار في استخدام التطبيق.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.brand.withOpacity(.28)),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.place_rounded,
                        size: 20,
                        color: AppColors.brand,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لم يتم اختيار أي عنوان بعد',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      goAdd = true;
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'إضافة عنوان الآن (إجباري)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        isScrollControlled: true,
        isDismissible: false, // ❗ لا يمكن إغلاقه بالضغط خارج
        enableDrag: false, // ❗ ولا بالسحب لتحت
      );

      if (goAdd == true) {
        await openAddresses();
        // بعد الرجوع من شاشة العناوين → تُعاد الحلقة، ولو أضاف عنوان تخرج
      }
    }
  }

  /// 🆕 فتح السلة من الهوم مع مراعاة الحساب التجريبي
  Future<void> handleOpenCart() async {
    if (await _isDemoUser()) {
      _showUserError(
        'هذا حساب تجريبي للتصفح فقط.\nلا يمكنك استخدام السلة أو إتمام الطلبات.',
      );
      return;
    }
    Get.toNamed('/cart');
  }

  Future<void> addItemToCart(ItemModel item) async {
    // 🆕 منع الإضافة في وضع الحساب التجريبي/الزائر
    if (await _isDemoUser()) {
      _showUserError(
        'هذا حساب تجريبي للتصفح فقط.\nلا يمكنك إضافة الأصناف إلى السلة أو تنفيذ الطلبات.',
      );
      return;
    }

    final itemId = _extractItemId(item);
    if (itemId == null || itemId == 0) {
      _showUserError('لا يمكن إضافة هذا الصنف حالياً، يرجى تحديث الصفحة.');
      return;
    }

    // ❌ لم نعد نسأل هنا عن العنوان
    // ✅ الرسالة تظهر عند فتح التطبيق فقط (onReady)
    try {
      // 🔹 استدعاء منطق السلة الرسمي: add(itemId)
      await _cart.add(itemId, qty: 1, showSnack: false);
      final name = _extractItemName(item);

      // Snackbar خفيف يعلم المستخدم أن الصنف أُضيف
      Get.rawSnackbar(
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        borderRadius: 16,
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor: const Color(0xFF111827),
        messageText: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF34D399),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تمت إضافة "$name" إلى السلة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('addItemToCart error: $e');
      _showUserError('تعذّر إضافة الصنف إلى السلة، حاول مرة أخرى.');
    }
  }

  bool isItemFavorite(int itemId) {
    try {
      if (!Get.isRegistered<FavoritesController>()) return false;
      return Get.find<FavoritesController>().isFavorite(itemId);
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleFavoriteFromHome(ItemModel item) async {
    if (await _isDemoUser()) {
      _showUserError(
        'هذا حساب تجريبي للتصفح فقط.\nلا يمكنك تعديل المفضلة من الحساب التجريبي.',
      );
      return;
    }

    if (!Get.isRegistered<FavoritesController>()) {
      Get.put(FavoritesController(), permanent: true);
    }

    try {
      await Get.find<FavoritesController>().toggleFromHome(item);
    } catch (e) {
      debugPrint('toggleFavoriteFromHome error: $e');
      _showUserError('تعذّر تعديل المفضلة حالياً.');
    }
  }
}
