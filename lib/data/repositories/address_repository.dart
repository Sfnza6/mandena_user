import '../../core/api_service.dart';
import '../models/address.dart';

class AddressRepository {
  final ApiService api;
  AddressRepository(this.api);

  Future<List<Address>> fetch(int userId) async {
    final res = await api.get('get_user_addresses.php', params: {'user_id': '$userId'});
    if (res['ok'] != true) throw Exception(res['message'] ?? 'خطأ غير متوقع');
    final list = (res['addresses'] as List)
        .map((e) => Address.fromJson(e))
        .toList();
    return list;
  }

  Future<int> addOrUpdate(Address a) async {
    final res = await api.post('add_update_address.php', body: a.toForm());
    if (res['ok'] != true) throw Exception(res['message'] ?? 'تعذّر الحفظ');
    return int.tryParse('${res['id']}') ?? a.id;
  }

  Future<void> delete(int id, int userId) async {
    final res = await api.post('delete_address.php', body: {
      'id': '$id',
      'user_id': '$userId',
    });
    if (res['ok'] != true) throw Exception(res['message'] ?? 'تعذّر الحذف');
  }

  Future<void> setDefault(int id, int userId) async {
    final res = await api.post('set_default_address.php', body: {
      'id': '$id',
      'user_id': '$userId',
    });
    if (res['ok'] != true) throw Exception(res['message'] ?? 'تعذّر التعيين كافتراضي');
  }
}
