class OrderSummary {
  final int id;
  final String address;
  final int paymentMethod; // 0 كاش / 1 بطاقة (حسبك)
  final double total;
  final String
  status; // pending, processing, assigned, on_the_way, delivering, handover
  final String createdAt;

  OrderSummary({
    required this.id,
    required this.address,
    required this.paymentMethod,
    required this.total,
    required this.status,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) {
    return OrderSummary(
      id: int.tryParse('${j['id']}') ?? 0,
      address: (j['address'] ?? '').toString(),
      paymentMethod: int.tryParse('${j['payment_method'] ?? 0}') ?? 0,
      total: double.tryParse('${j['total'] ?? 0}')?.toDouble() ?? 0.0,
      status: (j['status'] ?? '').toString(),
      createdAt: (j['created_at'] ?? '').toString(),
    );
  }
}
