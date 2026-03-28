import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/connection/network_controller.dart';

class NoConnectionView extends StatelessWidget {
  const NoConnectionView({super.key});

  static const Color brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    // نتأكّد إن الكنترولر مسجّل
    final ConnectionController c = Get.find<ConnectionController>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final primaryTextColor =
        theme.textTheme.bodyLarge?.color ??
        (isDark ? Colors.white : Colors.black87);
    final secondaryTextColor =
        (theme.textTheme.bodyMedium?.color ?? primaryTextColor).withOpacity(
          isDark ? 0.8 : 0.6,
        );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),

                  // أيقونة الشبكة (تبقى بني في الوضعين)
                  const Icon(Icons.wifi_off_rounded, size: 90, color: brown),
                  const SizedBox(height: 24),

                  Text(
                    'لا يوجد اتصال بالإنترنت',
                    style: TextStyle(
                      color: brown,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'تحقّق من بيانات الهاتف أو شبكة الواي فاي، ثم اضغط إعادة المحاولة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // زر إعادة المحاولة
                  ElevatedButton(
                    onPressed: () async {
                      await c.retryConnection();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brown,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
