class UserModel {
  final int id;
  final String username;
  final String phone;
  final String avatarUrl;
  final String? createdAt;

  /// 0 = غير مقيّد، 1 = مقيّد
  final int isBanned;

  /// سبب التقييد (اختياري)
  final String? bannedReason;

  UserModel({
    required this.id,
    required this.username,
    required this.phone,
    required this.avatarUrl,
    this.createdAt,
    this.isBanned = 0,
    this.bannedReason,
  });

  bool get isBlocked => isBanned == 1;

  factory UserModel.fromJson(Map<String, dynamic> j) {
    final rawBan = j['is_banned'] ?? j['banned'] ?? j['blocked'] ?? 0;
    final rawBanStr = rawBan.toString().toLowerCase().trim();

    int banInt;
    if (rawBan is bool) {
      banInt = rawBan ? 1 : 0;
    } else if (rawBanStr == '1' || rawBanStr == 'true') {
      banInt = 1;
    } else {
      banInt = 0;
    }

    return UserModel(
      id: int.tryParse('${j['id'] ?? 0}') ?? 0,
      // يدعم username أو name
      username: (j['username'] ?? j['name'] ?? '').toString(),
      phone: (j['phone'] ?? '').toString(),
      avatarUrl: (j['avatar_url'] ?? j['avatar'] ?? '').toString(),
      createdAt: j['created_at']?.toString(),
      isBanned: banInt,
      bannedReason: (j['banned_reason'] ?? j['ban_reason'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'phone': phone,
        'avatar_url': avatarUrl,
        'created_at': createdAt,
        'is_banned': isBanned,
        'banned_reason': bannedReason,
      };

  UserModel copyWith({
    int? id,
    String? username,
    String? phone,
    String? avatarUrl,
    String? createdAt,
    int? isBanned,
    String? bannedReason,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isBanned: isBanned ?? this.isBanned,
      bannedReason: bannedReason ?? this.bannedReason,
    );
  }
}
