// lib/core/auth_service.dart
import 'package:get/get.dart';
import 'session.dart';

class AuthService extends GetxService {
  final userId = RxnInt();

  Future<AuthService> init() async {
    await Session.init();
    userId.value = await Session.userId();
    return this;
  }

  Future<void> login(Map<String, dynamic> user) async {
    await Session.saveLoggedIn(user: user);
    final id = int.tryParse('${user['id'] ?? user['user_id'] ?? ''}');
    userId.value = id;
  }

  Future<void> logout() async {
    await Session.clear();
    userId.value = null;
  }

  /// في حال حفظت الجلسة يدويًا: حدث الـ userId من التخزين
  Future<void> refreshFromStorage() async {
    userId.value = await Session.userId();
  }

  bool get isLoggedIn => (userId.value ?? 0) > 0;
}
