import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';
import 'package:mandena/modules/cart/cart_controller.dart';
import 'package:mandena/modules/favorites/favorites_controller.dart';

import '../../core/session.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/api_service.dart';
import '../../app_routes.dart';
import '../../core/theme_service.dart';
import '../root/root_controller.dart';

class AccountController extends GetxController {
  final UserRepository _repo = UserRepository(ApiService());
  final loading = false.obs;
  final user = Rxn<UserModel>();

  final isDarkMode = false.obs;

  DateTime? _lastSnackAt;
  static const _snackThrottle = Duration(seconds: 4);

  void _showUserError(
    String msg, {
    String title = 'تعذّر إتمام العملية',
    VoidCallback? onRetry,
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
      backgroundColor: const Color(0xFF1F2937),
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
          if (onRetry != null) onRetry();
        },
        child: Text(
          onRetry != null ? 'إعادة المحاولة' : 'إغلاق',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      duration: const Duration(seconds: 4),
    );
  }

  void _showInfo(String msg, {String title = 'تنبيه'}) {
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
      backgroundColor: const Color(0xFF374151),
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
      duration: const Duration(seconds: 3),
    );
  }

  String _friendlyMessage(Object e) {
    final t = e.toString().toLowerCase();

    if (t.contains('delete_account.php') ||
        t.contains('تعذّر حذف الحساب') ||
        t.contains('خطأ sql')) {
      return 'تعذّر حذف الحساب من الخادم.\nحاول مرة أخرى بعد قليل.';
    }

    if (t.contains('failed host lookup') ||
        t.contains('socketexception') ||
        t.contains('network is unreachable') ||
        t.contains('network_error') ||
        t.contains('no address associated with hostname')) {
      return '⚠️ لا يوجد اتصال بالإنترنت.';
    }

    if (t.contains('timeout') || t.contains('deadline exceeded')) {
      return '⏳ انتهت مهلة الاتصال.';
    }

    if (t.contains('handshakeexception') || t.contains('certificate')) {
      return '🔐 مشكلة اتصال بالخادم.';
    }

    if (t.contains('formatexception') || t.contains('json')) {
      return '⚠️ خطأ في البيانات.';
    }

    return 'حدث خطأ غير متوقع.';
  }

  String _friendlyHttp(int code) {
    if (code == 401 || code == 403) {
      return '⛔ غير مصرح.';
    }
    if (code == 404) return 'الخدمة غير متاحة.';
    if (code == 429) {
      return '🚦 محاولات كثيرة. انتظر قليلاً.';
    }
    if (code >= 500 && code <= 504) {
      return '🛠️ خطأ بالخادم.';
    }
    return 'HTTP $code';
  }

  void goToAddress() {
    Get.toNamed(AppRoutes.addresses);
  }

  int? _lastBoundUserId;
  late final GetStorage _box;

  static const String _kProfileKey = 'account_profile_v1';
  static const String _kProfileTsKey = 'account_profile_ts_v1';
  static const int _cacheMaxAgeMinutes = 5;
  static const String _kDarkModeKey = 'app_dark_mode_v1';

  @override
  void onInit() {
    super.onInit();
    _initCache();
  }

  Future<void> _initCache() async {
    try {
      await GetStorage.init();
    } catch (_) {}

    _box = GetStorage();

    isDarkMode.value = ThemeService().theme == ThemeMode.dark;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);

    _loadCachedProfile();
  }

  bool _isCacheFresh() {
    try {
      final ts = _box.read(_kProfileTsKey);
      if (ts is int) {
        final savedAt = DateTime.fromMillisecondsSinceEpoch(ts);
        final diff = DateTime.now().difference(savedAt).inMinutes;
        return diff < _cacheMaxAgeMinutes;
      }
    } catch (_) {}
    return false;
  }

  void _loadCachedProfile() {
    try {
      if (!_isCacheFresh()) return;
      final raw = _box.read(_kProfileKey);
      if (raw is Map) {
        final map = Map<String, dynamic>.from(raw);
        final u = UserModel.fromJson(map);
        user.value = u;
      }
    } catch (_) {}
  }

  void _cacheProfile(UserModel u) {
    try {
      _box.write(_kProfileKey, u.toJson());
      _box.write(_kProfileTsKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  Future<void> toggleDarkMode() async {
    final newVal = !isDarkMode.value;
    isDarkMode.value = newVal;

    try {
      await _box.write(_kDarkModeKey, newVal);
    } catch (_) {}

    Get.changeThemeMode(newVal ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  void onReady() {
    super.onReady();
    fetchProfile();
  }

  Future<void> _rebindControllersIfNeeded() async {
    final currentId = await Session.userId();
    if (_lastBoundUserId == currentId) return;
    _lastBoundUserId = currentId;

    try {
      await Get.find<CartController>().bindToCurrentUser();
    } catch (_) {}
    try {
      await Get.find<FavoritesController>().bindToCurrentUser();
    } catch (_) {}
  }

  Future<void> applyCurrentSession() async {
    await _rebindControllersIfNeeded();
    await fetchProfile();
  }

  Future<void> fetchProfile() async {
    try {
      loading(true);

      final local = await Session.readLoggedIn();

      bool isDemo = false;
      try {
        final dynamic rawId = local?['id'] ?? local?['user_id'] ?? 0;
        final int idNum = (rawId is int) ? rawId : int.tryParse('$rawId') ?? 0;
        final bool guestFlag = (local?['is_guest'] == true);
        final bool demoFlag = (local?['is_demo'] == true);
        isDemo = demoFlag || guestFlag || idNum == 0;
      } catch (_) {
        isDemo = false;
      }

      if (isDemo) {
        final demoJson = <String, dynamic>{
          'id': 0,
          'user_id': 0,
          'name': 'حساب تجريبي',
          'phone': '',
          'address_title': 'عنوان تجريبي',
          'address': 'عنوان تجريبي',
        };

        try {
          final u = UserModel.fromJson(demoJson);
          user.value = u;
        } catch (_) {
          user.value = null;
        }

        return;
      }

      int? id = int.tryParse('${local?['id'] ?? ''}');
      String phone = (local?['phone'] ?? '').toString();

      if (id == null && phone.isEmpty) {
        user.value = null;
        return;
      }

      final u = await _repo.getProfile(id: id, phone: phone);
      user.value = u;

      await Session.saveLoggedIn(user: u.toJson());
      _cacheProfile(u);
    } catch (e) {
      final txt = e.toString();
      final m = RegExp(r'HTTP\s*([0-9]{3})').firstMatch(txt);
      if (m != null) {
        final code = int.tryParse(m.group(1) ?? '');
        _showUserError(_friendlyHttp(code ?? 0));
      } else {
        _showUserError(_friendlyMessage(e));
      }
    } finally {
      loading(false);
    }
  }

  Future<void> logout() async {
    await Session.clear();
    user.value = null;
    _lastBoundUserId = -1;
    await _rebindControllersIfNeeded();

    try {
      final root = Get.find<RootController>();
      root.changeTab(0);
    } catch (_) {}

    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final local = await Session.readLoggedIn();
    bool isDemo = false;

    try {
      final dynamic rawId = local?['id'] ?? local?['user_id'] ?? 0;
      final int idNum = (rawId is int) ? rawId : int.tryParse('$rawId') ?? 0;
      isDemo =
          (local?['is_guest'] == true) ||
          (local?['is_demo'] == true) ||
          idNum == 0;
    } catch (_) {
      isDemo = false;
    }

    if (isDemo) {
      _showInfo(
        'هذا حساب تجريبي ولا يمكن تغيير كلمة المرور.\nسجّل الدخول بحسابك الحقيقي لاستخدام هذا الإجراء.',
      );
      return;
    }

    if (user.value == null) {
      _showInfo('سجّل الدخول أولاً');
      return;
    }

    if (oldPassword.isEmpty) {
      _showUserError('أدخل كلمة المرور الحالية.');
      return;
    }
    if (newPassword.length < 6) {
      _showUserError('كلمة المرور الجديدة قصيرة جداً.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showUserError('كلمة المرور الجديدة غير متطابقة.');
      return;
    }

    final confirmed =
        await Get.dialog<bool>(
          Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('تأكيد تغيير كلمة المرور'),
              content: const Text(
                'سيتم تغيير كلمة مرور حسابك.\nبعد التغيير سيتم تسجيل خروجك.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text(
                    'متابعة',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      loading(true);

      final id = user.value!.id;
      final phone = user.value!.phone;

      await _repo.changePassword(
        id: id,
        phone: phone.isNotEmpty ? phone : null,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      _showInfo(
        'تم تغيير كلمة المرور بنجاح.\nسيتم تسجيل خروجك الآن.',
        title: 'تم التغيير',
      );
      await logout();
    } catch (e) {
      final txt = e.toString().toLowerCase();
      if (txt.contains('old_password') ||
          txt.contains('wrong') ||
          txt.contains('current')) {
        _showUserError('كلمة المرور الحالية غير صحيحة.');
      } else {
        final m = RegExp(r'HTTP\s*([0-9]{3})').firstMatch(e.toString());
        if (m != null) {
          final code = int.tryParse(m.group(1) ?? '');
          _showUserError(_friendlyHttp(code ?? 0));
        } else {
          _showUserError(_friendlyMessage(e));
        }
      }
    } finally {
      loading(false);
    }
  }

  Future<void> deleteAccount() async {
    final local = await Session.readLoggedIn();
    bool isDemo = false;

    try {
      final dynamic rawId = local?['id'] ?? local?['user_id'] ?? 0;
      final int idNum = (rawId is int) ? rawId : int.tryParse('$rawId') ?? 0;
      isDemo =
          (local?['is_guest'] == true) ||
          (local?['is_demo'] == true) ||
          idNum == 0;
    } catch (_) {
      isDemo = false;
    }

    if (isDemo) {
      _showInfo(
        'لا يمكن حذف الحساب التجريبي.\nاستخدم حساباً حقيقياً لتنفيذ هذا الإجراء.',
      );
      return;
    }

    if (user.value == null) {
      _showInfo('سجّل الدخول أولاً');
      return;
    }

    try {
      loading(true);

      final id = user.value!.id;
      final phone = user.value!.phone;

      await _repo.deleteAccount(id: id, phone: phone);

      _showInfo('تم حذف الحساب نهائياً.', title: 'تم الحذف');
      await logout();
    } catch (e) {
      final txt = e.toString();
      final m = RegExp(r'HTTP\s*([0-9]{3})').firstMatch(txt);
      if (m != null) {
        final code = int.tryParse(m.group(1) ?? '');
        _showUserError(_friendlyHttp(code ?? 0));
      } else {
        _showUserError(_friendlyMessage(e));
      }
    } finally {
      loading(false);
    }
  }

  void goToOrders() async {
    final local = await Session.readLoggedIn();
    bool isDemo = false;

    try {
      final dynamic rawId = local?['id'] ?? local?['user_id'] ?? 0;
      final int idNum = (rawId is int) ? rawId : int.tryParse('$rawId') ?? 0;
      isDemo =
          (local?['is_demo'] == true) ||
          (local?['is_guest'] == true) ||
          idNum == 0;
    } catch (_) {
      isDemo = false;
    }

    if (isDemo) {
      _showInfo(
        'هذا حساب تجريبي للتصفح فقط.\nلا يمكنك عرض الطلبات.\nسجّل الدخول بحسابك الحقيقي.',
      );
      return;
    }

    Get.toNamed(AppRoutes.orders);
  }

  void goToCart() async {
    final local = await Session.readLoggedIn();
    bool isDemo = false;
    try {
      final dynamic rawId = local?['id'] ?? local?['user_id'] ?? 0;
      final int idNum = (rawId is int) ? rawId : int.tryParse('$rawId') ?? 0;
      final bool guestFlag = (local?['is_guest'] == true);
      final bool demoFlag = (local?['is_demo'] == true);
      isDemo = demoFlag || guestFlag || idNum == 0;
    } catch (_) {
      isDemo = false;
    }

    if (isDemo) {
      _showInfo('هذا حساب تجريبي للتصفح فقط.\nلا يمكنك استخدام السلة.');
      return;
    }

    Get.toNamed(AppRoutes.cart);
  }

  void goToFavorites() => Get.toNamed(AppRoutes.favorites);

  void openProfileView() {
    if (user.value == null) {
      _showInfo('سجّل الدخول أولاً');
      return;
    }
    Get.toNamed(AppRoutes.profileView, arguments: user.value);
  }

  void openDevelopers() {
    Get.toNamed(AppRoutes.developersView);
  }
}
