import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccountBannedView extends StatelessWidget {
  const AccountBannedView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments is Map ? Get.arguments as Map : {};
    final reason = (args['reason'] ?? '').toString();
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.block, size: 80, color: Colors.red),
                  const SizedBox(height: 20),
                  Text(
                    'تم تقييد حسابك',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    reason.isEmpty
                        ? 'لقد تم تقييد حسابك من قبل الإدارة.\nللمزيد من التفاصيل، تواصل مع الدعم.'
                        : 'لقد تم تقييد حسابك للأسباب التالية:\n$reason',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.8) ??
                          Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Get.offAllNamed('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تسجيل خروج',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
