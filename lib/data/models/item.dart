// lib/data/models/item.dart
class ItemModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String? discount;
  final String imageUrl;
  final int categoryId;
  final double rating;
  final int orderCount;

  // ===== NEW =====
  final bool isActive; // 1/0 من الـ API
  final int? dailyQuota; // الحد اليومي (قد يكون null => بدون حد)
  final int quotaUsed; // المستهلك اليوم
  final String? quotaDate; // تاريخ آخر احتساب (YYYY-MM-DD)

  ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    this.discount,
    this.rating = 0,
    this.orderCount = 0,
    // NEW
    this.isActive = true,
    this.dailyQuota,
    this.quotaUsed = 0,
    this.quotaDate,
  });

  /// المتبقي اليوم (إن كان فيه حد)، غير ذلك يرجّع null
  int? get remaining {
    if (dailyQuota == null) return null;
    final r = dailyQuota! - quotaUsed;
    return r < 0 ? 0 : r;
  }

  /// نفدت الكمية/غير متاح
  bool get outOfStock {
    if (!isActive) return true;
    if (dailyQuota == null) return false;
    return (dailyQuota! - quotaUsed) <= 0;
  }

  factory ItemModel.fromJson(Map<String, dynamic> j) {
    final img = (j['image_url'] ?? j['imageUrl'] ?? j['image'] ?? '')
        .toString();

    int? toIntOrNull(dynamic x) {
      if (x == null) return null;
      final s = '$x'.trim();
      if (s.isEmpty || s.toLowerCase() == 'null') return null;
      return int.tryParse(s);
    }

    return ItemModel(
      id: int.tryParse('${j['id']}') ?? 0,
      name: (j['name'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      price: double.tryParse('${j['price']}') ?? 0.0,
      discount: (j['discount'] == null || '${j['discount']}'.isEmpty)
          ? null
          : '${j['discount']}',
      imageUrl: img,
      categoryId: int.tryParse('${j['category_id'] ?? j['categoryId']}') ?? 0,
      rating: double.tryParse('${j['rating'] ?? 0}') ?? 0,
      orderCount: int.tryParse('${j['order_count'] ?? 0}') ?? 0,
      // NEW
      isActive: (() {
        final v = j['is_active'];
        if (v is bool) return v;
        final n = int.tryParse('${v ?? 1}');
        return (n ?? 1) == 1;
      })(),
      dailyQuota: toIntOrNull(j['daily_quota']),
      quotaUsed: int.tryParse('${j['quota_used'] ?? 0}') ?? 0,
      quotaDate: (j['quota_date']?.toString().trim().toLowerCase() == 'null')
          ? null
          : (j['quota_date']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'discount': discount,
    'image_url': imageUrl,
    'category_id': categoryId,
    'rating': rating,
    'order_count': orderCount,
    // NEW
    'is_active': isActive ? 1 : 0,
    'daily_quota': dailyQuota,
    'quota_used': quotaUsed,
    'quota_date': quotaDate,
  };

  ItemModel copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? discount,
    String? imageUrl,
    int? categoryId,
    double? rating,
    int? orderCount,
    bool? isActive,
    int? dailyQuota,
    int? quotaUsed,
    String? quotaDate,
  }) {
    return ItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      rating: rating ?? this.rating,
      orderCount: orderCount ?? this.orderCount,
      isActive: isActive ?? this.isActive,
      dailyQuota: dailyQuota ?? this.dailyQuota,
      quotaUsed: quotaUsed ?? this.quotaUsed,
      quotaDate: quotaDate ?? this.quotaDate,
    );
  }
}
