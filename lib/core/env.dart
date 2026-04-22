class Env {
  // لا تضع سلاش في النهاية
  static const String baseUrl = "https://evoranta.ly/mandena/";
  static const String branchesList = "get_branches.php";

  static const String ordersList = "$baseUrl/get_orders.php";
  static const String orderDetails = "$baseUrl/get_order_details.php"; // ✅ صح
  static const String userById = 'get_user.php';
}
