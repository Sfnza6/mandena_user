import 'package:get/get.dart';
import 'package:mandena/core/api_service.dart';
import 'package:mandena/modules/cart/cart_controller.dart';
import 'package:mandena/modules/favorites/favorites_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // ✅ تسجيل ApiService مرة واحدة للتطبيق بالكامل
    if (!Get.isRegistered<ApiService>()) {
      Get.put<ApiService>(ApiService(), permanent: true);
    }

    // الكنترولرات الأساسية للتطبيق
    Get.put<FavoritesController>(FavoritesController(), permanent: true);
    Get.put<CartController>(CartController(), permanent: true);
  }
}
