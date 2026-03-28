// import 'package:get/get.dart';
// import 'package:iforenta_app_2/core/api_service.dart';
// import 'package:iforenta_app_2/core/session.dart';
// import 'package:iforenta_app_2/data/models/order.dart';

// class CurrentOrdersController extends GetxController {
//   final _api = ApiService();
//   final loading = false.obs;
//   final orders = <OrderSummary>[].obs;

//   @override
//   void onReady() {
//     super.onReady();
//     fetch();
//   }

//   Future<void> fetch() async {
//     loading.value = true;
//     try {
//       final uid = await Session.userId();
//       if (uid == null) {
//         orders.clear();
//         return;
//       }

//       final res = await _api.get(
//         'get_user_current_orders.php',
//         params: {'user_id': uid.toString()},
//       );

//       if (res is Map && res['ok'] == true) {
//         final list = (res['orders'] as List? ?? const [])
//             .map(
//               (e) => OrderSummary.fromJson(Map<String, dynamic>.from(e as Map)),
//             )
//             .toList();
//         orders.assignAll(list);
//       } else {
//         orders.clear();
//       }
//     } catch (_) {
//       orders.clear();
//     } finally {
//       loading.value = false;
//     }
//   }
// }
