class Env {
  // لا تضع سلاش في النهاية
  static const baseUrl = "https://mandena.ly/mandena"; // عدّلها
  static const String branchesList = "get_branches.php";

  static const String ordersList = "$baseUrl/get_orders.php";
  static const String orderDetails = "$baseUrl/get_order_details.php"; // ✅ صح
  static const String userById = 'get_user.php';
}
