class Address {
  final int id;
  final int userId;
  final String label;
  final double lat;
  final double lng;
  final String addressText;
  final int isDefault; // 0/1
  final String createdAt;

  Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.lat,
    required this.lng,
    required this.addressText,
    required this.isDefault,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: int.tryParse('${j['id']}') ?? 0,
        userId: int.tryParse('${j['user_id']}') ?? 0,
        label: (j['label'] ?? '').toString(),
        lat: double.tryParse('${j['lat']}') ?? 0,
        lng: double.tryParse('${j['lng']}') ?? 0,
        addressText: (j['address_text'] ?? '').toString(),
        isDefault: int.tryParse('${j['is_default']}') ?? 0,
        createdAt: (j['created_at'] ?? '').toString(),
      );

  Map<String, dynamic> toForm() => {
        'id': id > 0 ? '$id' : '',
        'user_id': '$userId',
        'label': label,
        'lat': '$lat',
        'lng': '$lng',
        'address_text': addressText,
        'is_default': '$isDefault',
      };
}
