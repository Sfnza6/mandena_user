import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mandena/modules/branch/branch_controller.dart';

import '../../core/env.dart';
import '../models/offer.dart';
import '../models/category.dart';
import '../models/item.dart';

class HomeRepository {
  final http.Client _client = http.Client();

  // يمنع الكاش على مستوى العميل/البروكسي
  int _branchId() {
    try {
      if (Get.isRegistered<BranchController>()) {
        return Get.find<BranchController>().selectedBranchId.value;
      }
    } catch (_) {}
    return 0;
  }

  Map<String, String> get _requestHeaders {
    final branchId = _branchId();
    return {
      'Accept': 'application/json',
      'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
      'Pragma': 'no-cache',
      if (branchId > 0) 'X-Branch-Id': '$branchId',
    };
  }

  // يضمن عدم وجود // مزدوجة
  String _u(String path) {
    final base = Env.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final p = path.replaceFirst(RegExp(r'^/+'), '');
    return '$base/$p';
  }

  // كاسر كاش لكل GET
  Uri _url(String pathWithQuery) {
    final base = _u(pathWithQuery);
    final uri = Uri.parse(base);

    final qp = <String, String>{
      ...uri.queryParameters,
      '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    final branchId = _branchId();
    if (branchId > 0) {
      qp['branch_id'] = '$branchId';
    }

    return uri.replace(queryParameters: qp);
  }

  /* -------------------- Helpers -------------------- */

  String _normalizeImg(dynamic raw) {
    var u = (raw ?? '').toString().trim();
    if (u.isEmpty) return '';

    // بدّل localhost/127.0.0.1 بقاعدة السيرفر
    u = u.replaceAll(
      RegExp(
        r'^https?://(localhost|127\.0\.0\.1)(:\d+)?',
        caseSensitive: false,
      ),
      Env.baseUrl,
    );

    // مسار يبدأ بـ /
    if (u.startsWith('/')) return '${Env.baseUrl}$u'.replaceAll(' ', '%20');

    // اسم ملف بدون http
    final isFilename = !u.startsWith('http://') && !u.startsWith('https://');
    if (isFilename) {
      if (!u.toLowerCase().contains('uploads/')) {
        return '${Env.baseUrl}/uploads/$u'.replaceAll(' ', '%20');
      }
      return '${Env.baseUrl}/$u'.replaceAll(' ', '%20');
    }

    return u.replaceAll(' ', '%20');
  }

  List<ItemModel> _mapItems(List<Map<String, dynamic>> list) {
    return list.map<ItemModel>((e) {
      final m = Map<String, dynamic>.from(e);
      // توحيد اسم الصورة
      final rawImg = m['image_url'] ?? m['image'] ?? m['img'] ?? m['photo'];
      m['image_url'] = _normalizeImg(rawImg);
      return ItemModel.fromJson(m);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path,
    List<String> keys,
  ) async {
    final url = _url(path);
    final res = await _client.get(url, headers: _requestHeaders);
    if (kDebugMode) {
      debugPrint('GET ${url.toString()} -> ${res.statusCode}');
      if (res.statusCode == 200) debugPrint(res.body);
    }
    if (res.statusCode != 200) return [];

    dynamic root;
    try {
      root = json.decode(res.body);
    } catch (_) {
      return [];
    }

    // الحالة 1: الرد مصفوفة مباشرة
    if (root is List) {
      try {
        return root.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } catch (_) {
        return [];
      }
    }

    // الحالة 2: الرد كائن وفيه قائمة تحت مفاتيح معروفة
    if (root is Map) {
      for (final k in keys) {
        final v = root[k];
        if (v is List) {
          return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        if (v is Map && v['data'] is List) {
          return (v['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        if (v is Map && v['rows'] is List) {
          return (v['rows'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
      // محاولات عامة
      for (final k in ['data', 'rows', 'records', 'result']) {
        final v = root[k];
        if (v is List) {
          return v.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        if (v is Map && v['data'] is List) {
          return (v['data'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
      }
    }

    return [];
  }

  /* -------------------- عروض -------------------- */
  Future<List<OfferModel>> fetchOffers() async {
    final list = await _getList('get_offers.php', const [
      'offers',
      'offer',
      'items',
    ]);
    // توحيد صور العروض إن وُجدت
    return list.map((e) {
      final m = Map<String, dynamic>.from(e);
      m['image_url'] = _normalizeImg(m['image_url'] ?? m['image']);
      return OfferModel.fromJson(m);
    }).toList();
  }

  /* -------------------- أقسام -------------------- */
  Future<List<CategoryModel>> fetchCategories() async {
    final url = _url('get_categories.php');
    final res = await _client.get(url, headers: _requestHeaders);
    if (kDebugMode) {
      debugPrint('GET ${url.toString()} -> ${res.statusCode}');
      debugPrint(res.body);
    }
    if (res.statusCode != 200) return [];

    try {
      final root = json.decode(res.body);

      if (root is List) {
        return root
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map((e) {
              e['image_url'] = _normalizeImg(e['image_url'] ?? e['image']);
              return CategoryModel.fromJson(e);
            })
            .toList();
      }

      if (root is Map) {
        final data = (root['categories'] ?? root['data'] ?? root['rows']);
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .map((e) {
                e['image_url'] = _normalizeImg(e['image_url'] ?? e['image']);
                return CategoryModel.fromJson(e);
              })
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('fetchCategories parse error: $e');
    }
    return [];
  }

  /* -------------------- الأكثر طلباً -------------------- */
  Future<List<ItemModel>> fetchMostOrdered() async {
    var list = await _getList('most_ordered.php?include_unavailable=1', const [
      'items',
      'products',
      'data',
    ]);
    if (list.isEmpty) {
      list = await _getList('receiver_get_items.php?limit=10', const [
        'items',
        'products',
        'data',
      ]);
      list.sort(
        (a, b) =>
            ((int.tryParse('${b['order_count']}') ?? 0) -
            (int.tryParse('${a['order_count']}') ?? 0)),
      );
    }
    return _mapItems(list);
  }

  /* -------------------- الأعلى تقييماً -------------------- */
  Future<List<ItemModel>> fetchTopRated() async {
    var list = await _getList('top_rated.php?include_unavailable=1', const [
      'items',
      'products',
      'data',
    ]);

    if (list.isEmpty) {
      list = await _getList('receiver_get_items.php?limit=10', const [
        'items',
        'products',
        'data',
      ]);
      list.sort(
        (a, b) => (double.tryParse('${b['rating']}') ?? 0).compareTo(
          double.tryParse('${a['rating']}') ?? 0,
        ),
      );
    }
    return _mapItems(list);
  }

  /* -------------------- البحث -------------------- */
  Future<List<ItemModel>> searchItems(String q) async {
    final url = _url('receiver_get_items.php?q=$q&limit=50');
    final res = await _client.get(url, headers: _requestHeaders);
    if (res.statusCode != 200) return [];
    dynamic d;
    try {
      d = json.decode(res.body);
    } catch (_) {
      return [];
    }
    final list = (d is List)
        ? d
        : (d is Map && d['items'] is List ? d['items'] as List : const []);
    final mapped = list
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return _mapItems(mapped);
  }
}
