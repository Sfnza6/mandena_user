import '../../core/api_service.dart';

class FavoritesRepository {
  final ApiService _api;
  FavoritesRepository(this._api);

  Future<bool> toggleFavorite({
    required int userId,
    required int itemId,
    required bool add,
  }) async {
    final res = await _api.postForm('toggle_favorite.php', {
      'user_id': '$userId',
      'item_id': '$itemId',
      'action': add ? 'add' : 'remove',
    });
    // ignore: unnecessary_type_check
    if (res is Map) {
      final ok = res['status']?.toString().toLowerCase();
      if (ok == 'success' || ok == 'ok') {
        final fav = res['favorite'];
        if (fav is bool) return fav;
        if (fav is num) return fav != 0;
        if (fav is String) return fav == '1' || fav.toLowerCase() == 'true';
      }
      if (res['message'] != null) throw Exception(res['message'].toString());
    }
    throw Exception('FAVORITE_TOGGLE_FAILED');
  }
}
