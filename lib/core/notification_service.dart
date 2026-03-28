import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mandena/firebase_options.dart';

// 🆕 لاستعمال Get في التنقل
import 'package:get/get.dart';
import 'package:mandena/modules/orders/my_orders_page.dart';
// 🆕 شاشة تتبّع الطلب

import 'api_service.dart';
// import 'env.dart';
import 'session.dart';

/// لازم تكون دالة توب-ليفل (برا أي كلاس) لمعالجة الرسائل في الخلفية
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.showFlutterNotification(message);
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// تهيئة Firebase + FCM + Local Notifications
  static Future<void> init() async {
    if (_initialized) return;

    // Firebase core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Local notifications (أيقونة داخل التطبيق)
    await _initLocalNotifications();

    // ربط الهاندلر في الخلفية
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // طلب سماح بالإشعارات
    await _requestPermission();

    // الاستماع للرسائل في foreground
    FirebaseMessaging.onMessage.listen(showFlutterNotification);

    // لما يضغط على الإشعار ويفتح التطبيق (من الخلفية)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('🔔 Notification opened (background): ${message.data}');
      _MyOrdersPageScreen();
    });

    // لو التطبيق كان مقفول بالكامل وفتحوه من الإشعار
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '🔔 App opened from terminated by notification: ${initialMessage.data}',
      );
      _MyOrdersPageScreen();
    }

    // الحصول على التوكن وحفظه في السيرفر
    final token = await _messaging.getToken();
    if (kDebugMode) {
      debugPrint('📲 FCM Token: $token');
    }
    if (token != null) {
      await _saveTokenToServer(token);
    }

    _initialized = true;
  }

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher', // تأكد أن عندك أيقونة
    );

    const initSettings = InitializationSettings(android: androidSettings);

    // 🆕 لما يضغط على الإشعار المحلي
    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Local notification tapped. payload=${response.payload}');
        _MyOrdersPageScreen();
      },
    );
  }

  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
    }
  }

  /// إظهار الإشعار محلياً (Foreground + Background)
  static Future<void> showFlutterNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;

    // لو الإشعار فاضي نتجاهلو
    if (notification == null || android == null) return;

    const androidDetails = AndroidNotificationDetails(
      'evoranta_general', // ID القناة
      'الاشعارات العامة', // اسم القناة
      channelDescription: 'إشعارات تطبيق إيفورانتا',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _fln.show(
      notification.hashCode,
      notification.title ?? 'إشعار جديد',
      notification.body ?? '',
      details,
      // نخلي الـ payload زي ما هو (data.toString) عشان ما نكسر ولا شي
      payload: message.data.toString(),
    );
  }

  /// حفظ FCM Token في السيرفر مربوط بالمستخدم
  static Future<void> _saveTokenToServer(String token) async {
    try {
      final userId = await Session.userId();
      if (userId == null || userId == 0) {
        if (kDebugMode) {
          debugPrint('⚠ لا يوجد مستخدم مسجل حالياً، لن نحفظ التوكن.');
        }
        return;
      }

      final api = ApiService();
      final res = await api.post(
        'notify/save_fcm_token.php', // ✅ المسار الصحيح
        body: {'user_id': userId, 'fcm_token': token, 'platform': 'android'},
      );

      if (kDebugMode) {
        debugPrint('✅ تم حفظ FCM token في السيرفر: $res');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ فشل حفظ FCM token: $e');
      }
    }
  }

  /// 🆕 فتح شاشة تتبّع الطلب عند الضغط على الإشعار
  static void _MyOrdersPageScreen() {
    // لو التطبيق فيه navigation جاهز (GetX) نستخدمه
    // هنا نفتح واجهة OrderTrackingView مباشرة
    try {
      Get.to(() => const MyOrdersPage());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ فشل فتح شاشة تتبّع الطلب: $e');
      }
    }
  }
}
