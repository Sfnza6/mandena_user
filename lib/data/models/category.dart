class CategoryModel {
  final int id;
  final String name;
  final String imageUrl;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: int.tryParse('${j['id']}') ?? 0,
        name: (j['name'] ?? '').toString(),
        imageUrl: (j['image_url'] ?? j['image'] ?? '').toString(),
      );

  // ============ NEW: toJson =============
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image_url': imageUrl,
      };
}
