import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home_controller.dart';

class HomeNetworkBanner extends StatelessWidget {
  const HomeNetworkBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    final theme = Theme.of(context);

    return Obx(() {
      if (!c.netError.value) {
        return const SizedBox(height: 0);
      }

      final cardColor = theme.cardColor;

      return Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFE2B5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFB46B00)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                c.netMsg.value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF8A5200)),
              ),
            ),
            TextButton(onPressed: c.retry, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    });
  }
}
