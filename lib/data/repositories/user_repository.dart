// lib/data/repositories/user_repository.dart
import 'dart:convert';
import '../../core/api_service.dart';
import '../models/user.dart';

class UserRepository {
  final ApiService _api;
  UserRepository(this._api);

  dynamic _normalize(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }
    return data;
  }

  Map<String, dynamic>? _asMapOrFirst(dynamic x) {
    if (x is Map<String, dynamic>) return x;
    if (x is List) {
      for (final e in x) {
        if (e is Map<String, dynamic>) return e;
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractUser(dynamic data) {
    if (data == null) return null;

    // لو كان الجذر مصفوفة/كائن
    final root = _asMapOrFirst(data);
    if (root != null &&
        (root['id'] != null ||
            root['username'] != null ||
            root['phone'] != null)) {
      return root;
    }

    // لو كان الجذر Map وفيه مفاتيح متوقعة
    if (data is Map) {
      final keys = ['user', 'data', 'payload'];
      for (final k in keys) {
        final candidate = _asMapOrFirst(data[k]);
        if (candidate != null &&
            (candidate['id'] != null ||
                candidate['username'] != null ||
                candidate['phone'] != null)) {
          return candidate;
        }
      }
    }
    return null;
  }

  String _short(dynamic v) {
    final s = v.toString();
    return s.length > 280 ? '${s.substring(0, 280)}…' : s;
  }

  Future<UserModel> getProfile({int? id, String? phone}) async {
    if (id == null && (phone == null || phone.isEmpty)) {
      throw Exception('يجب تمرير id أو phone لجلب البروفايل');
    }

    final raw = await _api.get(
      'get_user.php',
      params: {
        if (id != null) 'id': '$id',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    final data = _normalize(raw);
    final j = _extractUser(data);
    if (j == null) {
      throw Exception(
        'استجابة غير متوقعة من الخادم أثناء جلب البروفايل: ${_short(raw)}',
      );
    }
    return UserModel.fromJson(j);
  }

  Future<bool> updateProfile(UserModel u) async {
    final res = await _api.post(
      'update_user.php',
      body: {
        'id': '${u.id}',
        'username': u.username,
        'phone': u.phone,
        if (u.avatarUrl.isNotEmpty) 'avatar_url': u.avatarUrl,
      },
    );

    if (res is Map) {
      final ok = res['ok'];
      final status = res['status']?.toString().toLowerCase().trim();
      final success =
          (ok == true) ||
          (ok is num && ok != 0) ||
          status == 'ok' ||
          status == 'success' ||
          status == 'true' ||
          status == '1';
      if (success) return true;
      if (res['message'] != null) throw Exception(res['message'].toString());
    }
    return false;
  }

  /// حذف الحساب نهائياً من الخادم
  Future<void> deleteAccount({int? id, String? phone}) async {
    if (id == null && (phone == null || phone.isEmpty)) {
      throw Exception('يجب تمرير id أو phone لحذف الحساب');
    }

    final body = <String, dynamic>{
      if (id != null) 'id': '$id',
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };

    final res = await _api.post(
      'delete_account.php',
      body: body,
    );

    if (res is Map) {
      // نحاول نقرأ كل الاحتمالات الممكنة للـ status / ok
      final statusRaw =
          res['status'] ?? res['ok'] ?? res['success'] ?? res['deleted'] ?? '';
      final status = statusRaw.toString().toLowerCase().trim();

      final codeField = res['code'] ?? res['status_code'];

      final success =
          status == 'ok' ||
          status == 'success' ||
          status == 'true' ||
          status == '1' ||
          status == 'deleted' ||
          (codeField is int && codeField >= 200 && codeField < 300);

      if (success) {
        // حذف ناجح
        return;
      }

      // لو السيرفر رجّع رسالة خطأ، نظهرها كما هي
      if (res['message'] != null) {
        throw Exception(res['message'].toString());
      }
      if (res['error'] != null) {
        throw Exception(res['error'].toString());
      }

      throw Exception('تعذّر حذف الحساب. استجابة غير متوقعة: ${_short(res)}');
    }

    // لو الرد مش Map أصلاً
    throw Exception('تعذّر حذف الحساب. رد غير معروف من الخادم: ${_short(res)}');
  }

  /// ✅ تغيير كلمة مرور المستخدم الحالي
  Future<void> changePassword({
    int? id,
    String? phone,
    required String oldPassword,
    required String newPassword,
  }) async {
    if (id == null && (phone == null || phone.isEmpty)) {
      throw Exception('مطلوب id أو phone لتغيير كلمة المرور');
    }

    final body = <String, dynamic>{
      if (id != null) 'id': '$id',
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'old_password': oldPassword,
      'new_password': newPassword,
    };

    final res = await _api.post(
      'change_password.php',
      body: body,
    );

    if (res is Map) {
      final ok = res['ok'];
      final status = res['status']?.toString().toLowerCase().trim();
      final success =
          (ok == true) ||
          (ok is num && ok != 0) ||
          status == 'ok' ||
          status == 'success' ||
          status == 'true' ||
          status == '1';

      if (success) return;

      if (res['message'] != null) {
        throw Exception(res['message'].toString());
      }
      if (res['error'] != null) {
        throw Exception(res['error'].toString());
      }

      throw Exception('تعذّر تغيير كلمة المرور. استجابة غير متوقعة: ${_short(res)}');
    }

    throw Exception('تعذّر تغيير كلمة المرور. رد غير معروف من الخادم: ${_short(res)}');
  }
}
