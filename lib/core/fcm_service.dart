import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'api_service.dart'; // عدّل المسار حسب مشروعك
import 'session.dart'; // لو عندك Session لحفظ userId مثلاً

class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  static Future<void> initForLoggedInUser() async {
    if (_initialized) return;
    _initialized = true;

    // 1) طلب صلاحيات الإشعار (خاصة على iOS، بس نخليها عامة)
    await _requestPermission();

    // 2) جلب التوكن الحالي
    final token = await _messaging.getToken();
    debugPrint('🔥 FCM Token: $token');

    // 3) حفظه في السيرفر لو فيه يوزر مسجل
    final userId = Session.userId; // غيّرها حسب عندك
    if (token != null) {
      await _sendTokenToServer(userId as int, token);
    }

    // 4) في حال تغيّر التوكن
    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('♻️ New FCM Token: $newToken');
      final uId = Session.userId;
      await _sendTokenToServer(uId as int, newToken);
    });

    // 5) الاستماع للرسائل في الواجهة
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 onMessage: ${message.messageId}');
      _showInAppNotification(message);
    });

    // 6) عند فتح التطبيق من الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 onMessageOpenedApp: ${message.messageId}');
      _handleNotificationClick(message);
    });

    // 7) معالجة الرسالة التي فتحت التطبيق وهو مطفي
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }
  }

  static Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _sendTokenToServer(int userId, String token) async {
    try {
      final api = ApiService(); // أو لو عندك instance جاهز
      final res = await api.postJson('save_fcm_token.php', {
        'user_id': userId,
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });

      debugPrint('✅ save_fcm_token response: $res');
    } catch (e, st) {
      debugPrint('❌ Error saving FCM token: $e\n$st');
    }
  }

  static void _showInAppNotification(RemoteMessage message) {
    final title = message.notification?.title ?? 'إشعار جديد';
    final body = message.notification?.body ?? '';

    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 4),
    );
  }

  static void _handleNotificationClick(RemoteMessage message) {
    // هنا تقدر تفرّق بين أنواع الإشعارات
    // مثلاً لو من نوع "order_assigned" تفتح شاشة تتبع الطلب
    final data = message.data;
    final type = data['type'] ?? '';

    if (type == 'order_assigned') {
      final orderId = int.tryParse('${data['order_id'] ?? ''}');
      if (orderId != null) {
        // مثال:
        // Get.toNamed(AppRoutes.orderTracking, arguments: orderId);
      }
    } else if (type == 'broadcast') {
      // إشعار عام - ممكن بس تفتح الهوم
      // Get.toNamed(AppRoutes.home);
    }
  }
}
