class OfferModel {
  final int id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String discountLabel;
  final String cta;

  OfferModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.discountLabel = '',
    this.cta = 'اطلب الآن',
  });

  factory OfferModel.fromJson(Map<String, dynamic> j) => OfferModel(
        id: int.tryParse('${j['id']}') ?? 0,
        title: (j['title'] ?? '').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        imageUrl: (j['image_url'] ?? j['image'] ?? '').toString(),
        discountLabel:
            (j['discount_label'] ?? j['discount'] ?? '').toString(),
        cta: (j['cta'] ?? 'اطلب الآن').toString(),
      );

  // ============ NEW: toJson =============
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'image_url': imageUrl,
        'discount_label': discountLabel,
        'cta': cta,
      };
}
