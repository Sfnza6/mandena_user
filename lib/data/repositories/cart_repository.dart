import 'dart:convert';
import '../../core/api_service.dart';

class CartRepository {
  final ApiService _api;
  CartRepository(this._api);

  Future<void> addToCart({
    required int userId,
    required int itemId,
    required int qty,
    required double unitPrice,
    required double total,
    required List<Map<String, dynamic>> extras, // [{id, qty}]
    required List<int> addOns, // [id, ...]
    required List<int> removes, // [id, ...]
  }) async {
    final payload = {
      'user_id': '$userId',
      'item_id': '$itemId',
      'qty': '$qty',
      'unit_price': unitPrice.toStringAsFixed(2),
      'total': total.toStringAsFixed(2),
      'extras': jsonEncode(extras),
      'add_ons': jsonEncode(addOns),
      'removes': jsonEncode(removes),
      // وسوم اختيارية قد تفيد الـ API في التتبع أو القيود
      'client': 'app_user',
      'v': '1',
    };

    final raw = await _api.postForm('add_to_cart.php', payload);
    final data = _normalize(raw);

    // نجاحات شائعة
    if (_isSuccess(data)) return;

    // أكواد أخطاء متفق عليها (إن أرجعها السيرفر)
    final code = _str(data['code']);
    final msg = _str(data['message'])?.trim();

    if (code == 'OUT_OF_STOCK') {
      throw Exception(
        msg?.isNotEmpty == true ? msg : 'نفدت الكمية لهذا الصنف.',
      );
    }
    if (code == 'ITEM_INACTIVE') {
      throw Exception(
        msg?.isNotEmpty == true ? msg : 'هذا الصنف غير متاح حالياً.',
      );
    }
    if (code == 'QUOTA_EXCEEDED') {
      throw Exception(
        msg?.isNotEmpty == true ? msg : 'الكمية المطلوبة تتجاوز المتبقي لليوم.',
      );
    }

    // في حال الرد غير واضح
    if (msg != null && msg.isNotEmpty) {
      throw Exception(msg);
    }
    throw Exception('ADD_TO_CART_FAILED');
  }

  /* ================== Helpers ================== */

  dynamic _normalize(dynamic x) {
    // لو السيرفر رجّع JSON كسلسلة
    if (x is String) {
      try {
        final j = jsonDecode(x);
        return j;
      } catch (_) {
        // نلفّه داخل خريطة موحّدة ليستفيد منه منادينا
        return {'raw': x};
      }
    }
    return x;
  }

  String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    if (s.toLowerCase() == 'null') return null;
    return s;
  }

  bool _isSuccess(dynamic data) {
    if (data == null) return false;
    if (data is Map) {
      // حالات نجاح شائعة
      final status = _str(data['status'])?.toLowerCase();
      final ok = _str(data['ok'])?.toLowerCase();
      final success = _str(data['success'])?.toLowerCase();

      if (status == 'success' ||
          status == 'ok' ||
          status == 'true' ||
          status == '1') {
        return true;
      }
      if (ok == 'true' || ok == '1' || ok == 'ok' || ok == 'success') {
        return true;
      }
      if (success == 'true' ||
          success == '1' ||
          success == 'ok' ||
          success == 'success') {
        return true;
      }

      // بعض السكربتات تعيد {error:false}
      final error = _str(data['error'])?.toLowerCase();
      if (error == 'false' || error == '0') return true;
    }
    return false;
  }
}
