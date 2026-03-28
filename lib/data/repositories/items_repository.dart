import '../../core/api_service.dart';
import '../../core/env.dart';
import '../models/item.dart';

class ItemsRepository {
  final ApiService _api;
  ItemsRepository(this._api);

  String _normalizeImg(dynamic raw) {
    var u = (raw ?? '').toString().trim();
    if (u.isEmpty) return '';
    u = u.replaceAll(
      RegExp(
        r'^https?://(localhost|127\.0\.0\.1)(:\d+)?',
        caseSensitive: false,
      ),
      Env.baseUrl,
    );
    if (u.startsWith('/')) return '${Env.baseUrl}$u'.replaceAll(' ', '%20');
    final isFilename = !u.startsWith('http://') && !u.startsWith('https://');
    if (isFilename) {
      if (!u.toLowerCase().contains('uploads/')) {
        return '${Env.baseUrl}/uploads/$u'.replaceAll(' ', '%20');
      }
      return '${Env.baseUrl}/$u'.replaceAll(' ', '%20');
    }
    return u.replaceAll(' ', '%20');
  }

  bool _ok(dynamic res) {
    if (res is Map) {
      final s = (res['ok'] ?? res['status'] ?? res['success'])
          ?.toString()
          .toLowerCase();
      return s == '1' || s == 'true' || s == 'ok' || s == 'success';
    }
    return false;
  }

  Future<List<ItemModel>> fetchItems({int? categoryId}) async {
    final data = await _api.get(
      'receiver_get_items.php',
      params: {
        if (categoryId != null) 'category_id': '$categoryId',
        'include_unavailable': '1', // <-- مهم
      },
    );

    final List itemsJson = (data is List)
        ? data
        : (data is Map && data['items'] is List
              ? data['items'] as List
              : const []);

    return itemsJson.map<ItemModel>((e) {
      final m = Map<String, dynamic>.from(e as Map);
      final rawImg = m['image_url'] ?? m['image'] ?? m['img'] ?? m['photo'];
      m['image_url'] = _normalizeImg(rawImg);
      return ItemModel.fromJson(m);
    }).toList();
  }

  Future<Map<String, dynamic>> getItemOptions(int itemId) async {
    final data = await _api.get(
      'get_item_options.php',
      params: {'item_id': '$itemId'},
    );
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'addons': data};
    return <String, dynamic>{};
  }

  Future<bool> isFavorite(int userId, int itemId) async {
    final res = await _api.get(
      'get_favorites.php',
      params: {'user_id': '$userId', 'item_id': '$itemId'},
    );
    if (res is Map) {
      final v =
          res['is_favorite'] ??
          res['favorite'] ??
          res['ok'] ??
          res['status'] ??
          res['success'];
      final s = v?.toString().toLowerCase() ?? '0';
      return s == '1' || s == 'true' || s == 'yes';
    }
    if (res is String) {
      final s = res.toLowerCase();
      return s == '1' || s == 'true' || s == 'yes';
    }
    return false;
  }

  Future<bool> addFavorite(int userId, int itemId) async {
    final res = await _api.post(
      'add_favorite.php',
      body: {'user_id': '$userId', 'item_id': '$itemId'},
    );
    return _ok(res);
  }

  Future<bool> removeFavorite(int userId, int itemId) async {
    final res = await _api.post(
      'remove_favorite.php',
      body: {'user_id': '$userId', 'item_id': '$itemId'},
    );
    return _ok(res);
  }

  Future<bool> toggleFavorite(int userId, int itemId) async {
    final res = await _api.post(
      'favorites/toggle.php',
      body: {'user_id': '$userId', 'item_id': '$itemId'},
    );
    if (res is Map && (res['is_favorite'] != null)) {
      final s = res['is_favorite'].toString().toLowerCase();
      return s == '1' || s == 'true';
    }
    return _ok(res);
  }

  Future<double?> submitRating({
    required int userId,
    required int itemId,
    required int stars,
    String? comment,
  }) async {
    final res = await _api.post(
      'rate_item.php',
      body: {
        'user_id': '$userId',
        'item_id': '$itemId',
        'stars': '$stars',
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    if (res is Map && (res['ok'] == true || '${res['ok']}' == '1')) {
      final a = double.tryParse('${res['avg_rating'] ?? ''}');
      return a;
    }
    throw Exception('RATING_FAILED');
  }

  Future<double> fetchAverageRating(int itemId) async {
    // لو تفضّل API منفصلة، بدّل للمسار المناسب، أو خذ من receiver_get_items
    final data = await _api.get(
      'receiver_get_items.php',
      params: {'item_id': '$itemId'},
    );
    if (data is List && data.isNotEmpty) {
      final m = Map<String, dynamic>.from(data.first);
      return double.tryParse('${m['rating'] ?? 0}') ?? 0.0;
    }
    if (data is Map &&
        data['items'] is List &&
        (data['items'] as List).isNotEmpty) {
      final m = Map<String, dynamic>.from((data['items'] as List).first);
      return double.tryParse('${m['rating'] ?? 0}') ?? 0.0;
    }
    return 0.0;
  }
}
