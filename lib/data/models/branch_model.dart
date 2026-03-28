class BranchModel {
  final int id;
  final String code;
  final String name;
  final String addressText;
  final String phone;
  final bool isActive;
  final bool isDefault;

  const BranchModel({
    required this.id,
    required this.code,
    required this.name,
    required this.addressText,
    required this.phone,
    required this.isActive,
    required this.isDefault,
  });

  static bool _toBool(dynamic v) {
    final s = '${v ?? 0}'.toLowerCase().trim();
    return s == '1' || s == 'true';
  }

  factory BranchModel.fromJson(Map<String, dynamic> j) {
    return BranchModel(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      code: (j['code'] ?? '').toString(),
      name: (j['name'] ?? '').toString(),
      addressText: (j['address_text'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      isActive: _toBool(j['is_active']),
      isDefault: _toBool(j['is_default']),
    );
  }
}
