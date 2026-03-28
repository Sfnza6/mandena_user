import '../../core/api_service.dart';
import '../models/user.dart';

class AuthRepository {
  final ApiService _api;
  AuthRepository([ApiService? api]) : _api = api ?? ApiService();

  // يفحص إذا كان الرد ناجحًا (يدعم عدة صيغ شائعة)
  bool _statusOk(dynamic res) {
    if (res is Map) {
      final ok = res['ok'];
      if (ok is bool) return ok;
      if (ok is num) return ok != 0;

      final status = res['status']?.toString().toLowerCase().trim();
      if (status != null && status.isNotEmpty) {
        return status == 'ok' ||
            status == 'success' ||
            status == 'true' ||
            status == '1';
      }
    }
    return false;
  }

  // يستخرج خريطة المستخدم من هيكل الرد (مرن)
  Map<String, dynamic>? _extractUser(dynamic res) {
    if (res is Map) {
      final candidates = [
        res['user'],
        res['data'],
        res['payload'],
        res, // أحيانًا تكون الحقول مباشرة داخل الجذر
      ];
      for (final c in candidates) {
        if (c is Map<String, dynamic> &&
            (c['id'] != null || c['username'] != null || c['phone'] != null)) {
          return c;
        }
      }
    } else if (res is List && res.isNotEmpty && res.first is Map) {
      return Map<String, dynamic>.from(res.first as Map);
    }
    return null;
  }

  /// تسجيل مستخدم جديد
  Future<UserModel> register({
    required String username,
    required String phone,
    required String password,
  }) async {
    // انتبه: **بدون سلاش** في بداية المسار
    final res = await _api.postForm('register.php', {
      'username': username,
      'phone': phone,
      'password': password,
    });

    if (_statusOk(res)) {
      final u = _extractUser(res);
      if (u != null) return UserModel.fromJson(u);
      throw Exception('REGISTER_SUCCESS_NO_USER');
    }

    throw Exception((res['message'])?.toString() ?? 'REGISTER_FAILED');
  }

  /// تسجيل الدخول
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    // انتبه: **بدون سلاش** في بداية المسار (كان سبب 404)
    final res = await _api.postForm('login.php', {
      'phone': phone,
      'password': password,
    });

    if (_statusOk(res)) {
      final u = _extractUser(res);
      if (u != null) return UserModel.fromJson(u);
      throw Exception('LOGIN_SUCCESS_NO_USER');
    }

    throw Exception((res['message'])?.toString() ?? 'LOGIN_FAILED');
  }

  /// ✅ فحص هل رقم الهاتف مسجّل مسبقاً في النظام أم لا
  /// يستخدم check_phone_exists.php ويرجع true لو الرقم موجود
  Future<bool> checkPhoneExists(String phone) async {
    try {
      final res = await _api.postForm('check_phone_exists.php', {
        'phone': phone,
      });

      // ignore: unnecessary_type_check
      if (res is Map) {
        // نحاول نفهم الـ status
        final status = (res['status'] ?? '').toString().toLowerCase().trim();
        final existsRaw = res['exists'];

        final exists =
            (existsRaw is bool && existsRaw == true) ||
            (existsRaw is num && existsRaw != 0) ||
            (existsRaw is String &&
                (existsRaw == '1' || existsRaw.toLowerCase().trim() == 'true'));

        // لو الـ status = ok نرجّع قيمة exists كما هي
        if (status == 'ok' || status == 'success' || status == 'true') {
          return exists;
        }

        // حتى لو status مش مضبوط لكن عندنا exists = true → نثق فيها
        if (exists) return true;

        return false;
      }

      // لو الرد مش Map نرجّع false كافتراضي
    } catch (_) {
      // في حالة أي خطأ شبكة أو JSON نرجّع false (ما نطيحش التطبيق)
      return false;
    }
  }
}
