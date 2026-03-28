// lib/modules/search/search_controller.dart (مثال مسار)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart'; // 👈 للكاش الدائم

import '../../core/env.dart';
import '../../core/session.dart';
import '../../data/models/item.dart';

class SearchControllerX extends GetxController {
  /// نصّ البحث الحالي (للمراقبة فقط)
  final q = ''.obs;

  /// حالة التحميل
  final loading = false.obs;

  /// نتائج البحث الحالية
  final results = <ItemModel>[].obs;

  /// هل النتائج المعروضة حالياً من الكاش؟
  final fromCache = false.obs;

  /// سجلّ الأصناف (آخر 5 أصناف تم البحث عنها)
  final history = <ItemModel>[].obs;

  /// TextField controller
  final TextEditingController input = TextEditingController();

  /// تايمر بسيط للـ debounce (بحث حي بدون سبام على السيرفر)
  Timer? _debounce;

  /// 🧠 كاش داخلي في الذاكرة: query → List<ItemModel>
  /// المفتاح يكون نص البحث بعد تحويله لحروف صغيرة
  final Map<String, List<ItemModel>> _resultsCache = {};

  /// 🧠 كاش دائم في التخزين (GetStorage)
  final GetStorage _box = GetStorage();
  static const String _searchCachePrefix = 'search_cache_v1_';

  String _cacheKeyFor(String normalizedQuery) =>
      '$_searchCachePrefix$normalizedQuery';

  void _saveResultsToDisk(String key, List<ItemModel> list) {
    try {
      final data = list.map((e) => e.toJson()).toList();
      final jsonStr = jsonEncode(data);
      _box.write(_cacheKeyFor(key), jsonStr);
    } catch (_) {
      // تجاهل أخطاء الكاش
    }
  }

  List<ItemModel>? _loadResultsFromDisk(String key) {
    try {
      final raw = _box.read(_cacheKeyFor(key));
      if (raw is! String || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;

      final list = decoded
          .map((e) => ItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (list.isEmpty) return null;
      return list;
    } catch (_) {
      return null;
    }
  }

  /// userId الحالي من الجلسة
  Future<int> _currentUserId() async {
    final id = await Session.userId();
    return id ?? 0;
  }

  @override
  void onInit() {
    super.onInit();
    // أول ما يشتغل الكنترولر نحاول نجلب سجل البحث للمستخدم الحالي
    refreshHistory();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    input.dispose();
    super.onClose();
  }

  /// إعادة الصفحة لوضع البداية (بدون نتائج وبدون نص)
  void reset() {
    input.clear();
    q.value = '';
    results.clear();
    fromCache.value = false;
    // history نتركه كما هو
  }

  /// يتم استدعاؤها عند تغيّر النص في TextField (بحث حي)
  void onTextChanged(String value) {
    q.value = value;

    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      run();
    });
  }

  /// 💾 حفظ صنف في سجل البحث على السيرفر
  Future<void> saveItemToHistory(ItemModel item) async {
    final uid = await _currentUserId();
    if (uid == 0) return;

    try {
      final url = Uri.parse('${Env.baseUrl}/save_search_history.php');
      await http.post(
        url,
        body: {
          'user_id': uid.toString(),
          'item_id': item.id.toString(),
        },
      );

      // بعد الحفظ نحدّث السجل
      await refreshHistory();
    } catch (_) {
      // السجل شيء ثانوي، ما نطلعش خطأ
    }
  }

  /// 📥 جلب سجل الأصناف من السيرفر (آخر 5 أصناف)
  Future<void> refreshHistory() async {
    try {
      final uid = await _currentUserId();
      if (uid == 0) {
        history.clear();
        return;
      }

      final url = Uri.parse(
        '${Env.baseUrl}/get_search_history.php?user_id=$uid&limit=5',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200 || res.body.trim().isEmpty) {
        history.clear();
        return;
      }

      final data = json.decode(res.body);

      List list;
      if (data is Map && data['history'] is List) {
        list = data['history'] as List;
      } else if (data is List) {
        list = data;
      } else {
        list = const [];
      }

      final items = list
          .whereType<Map>()
          .map<ItemModel>((e) => ItemModel.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();

      history.assignAll(
        items.length > 5 ? items.take(5).toList() : items,
      );
    } catch (_) {
      // نتجاهل الخطأ – السجل شيء ثانوي
    }
  }

  /// 🔍 تنفيذ البحث على الأصناف (مع كاش في الذاكرة + كاش دائم)
  Future<void> run() async {
    final query = input.text.trim();
    q.value = query;

    // لما يتم المسح → نظف النتائج واظهر السجل
    if (query.isEmpty) {
      results.clear();
      fromCache.value = false;
      await refreshHistory();
      return;
    }

    final key = query.toLowerCase();

    // ✅ 1) كاش الذاكرة أولاً (أسرع شيء)
    if (_resultsCache.containsKey(key)) {
      final cachedList = _resultsCache[key]!;
      results.assignAll(cachedList);
      fromCache.value = true;
      return;
    }

    // ✅ 2) نحاول نجيب من كاش التخزين (GetStorage) لنعرض بسرعة
    final diskList = _loadResultsFromDisk(key);
    if (diskList != null) {
      results.assignAll(diskList);
      fromCache.value = true;
      // نحطها أيضاً في كاش الذاكرة عشان المرات الجاية تكون أسرع
      _resultsCache[key] = List<ItemModel>.from(diskList);
      // 👈 ما نرجعش هنا: نكمّل للـ API عشان نحدّث النتائج في الخلفية
    }

    // ✅ 3) استعلام جديد من السيرفر (يحدّث النتائج حتى لو كانت من الكاش)
    loading.value = true;
    fromCache.value = diskList != null; // لو عرضنا من الكاش نخلي الفلاغ true
    try {
      final encodedQ = Uri.encodeQueryComponent(query);
      final url = Uri.parse(
        '${Env.baseUrl}/get_items.php?q=$encodedQ&limit=50',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        // لو فشل الاتصال وفي كاش قديم (ذاكرة أو تخزين) إحنا أصلاً عرضناه فوق
        if (results.isNotEmpty) {
          // عندنا شيء نعرضه (من الكاش) → نكتفي به
          return;
        }

        Get.snackbar(
          'تعذّر الاتصال',
          'فشل الاتصال بالخادم. الرجاء المحاولة لاحقًا.',
          snackPosition: SnackPosition.BOTTOM,
        );
        results.clear();
        fromCache.value = false;
        return;
      }

      final d = json.decode(res.body);
      final list = (d is List)
          ? d
          : (d is Map && d['items'] is List ? d['items'] : const []);

      final parsed = list
          .whereType<Map>()
          .map<ItemModel>(
            (e) => ItemModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();

      results.assignAll(parsed);
      fromCache.value = false;

      // 🧠 خزّن في كاش الذاكرة + كاش التخزين
      _resultsCache[key] = List<ItemModel>.from(parsed);
      _saveResultsToDisk(key, parsed);
    } on SocketException {
      if (results.isNotEmpty) {
        // غالباً عندنا كاش معروض بالفعل
        fromCache.value = true;
        return;
      }
      Get.snackbar(
        'لا يوجد اتصال بالإنترنت',
        'تحقق من الشبكة ثم أعد المحاولة.',
        snackPosition: SnackPosition.BOTTOM,
      );
      results.clear();
      fromCache.value = false;
    } on TimeoutException {
      if (results.isNotEmpty) {
        fromCache.value = true;
        return;
      }
      Get.snackbar(
        'انتهت مهلة الاتصال',
        'الخادم لم يستجب في الوقت المحدد، حاول مرة أخرى لاحقًا.',
        snackPosition: SnackPosition.BOTTOM,
      );
      results.clear();
      fromCache.value = false;
    } on FormatException {
      Get.snackbar(
        'خطأ في البيانات',
        'حدث خطأ أثناء قراءة النتائج، حاول مجددًا بعد قليل.',
        snackPosition: SnackPosition.BOTTOM,
      );
      results.clear();
      fromCache.value = false;
    } catch (_) {
      Get.snackbar(
        'حدث خطأ غير متوقع',
        'تعذّر تنفيذ البحث الآن. حاول لاحقًا.',
        snackPosition: SnackPosition.BOTTOM,
      );
      results.clear();
      fromCache.value = false;
    } finally {
      loading.value = false;
    }
  }

  /// الضغط على عنصر من السجل
  Future<void> searchFromHistory(ItemModel item) async {
    // تعبئة الاسم في حقل البحث
    input.text = item.name;
    q.value = item.name;
    // تقدر لو حاب تستدعي run() هنا:
    // await run();
  }

  /// 🧹 حذف كل سجل الأصناف من قاعدة البيانات + من الواجهة
  Future<void> clearHistory() async {
    try {
      final uid = await _currentUserId();
      if (uid == 0) {
        history.clear();
        return;
      }

      final url = Uri.parse('${Env.baseUrl}/clear_search_history.php');

      await http.post(
        url,
        body: {'user_id': uid.toString()},
      );
    } catch (_) {
      // نتجاهل الخطأ
    } finally {
      history.clear();
    }
  }

  /// 🗑 حذف صنف واحد من السجل
  Future<void> deleteHistoryItem(ItemModel item) async {
    try {
      final uid = await _currentUserId();
      if (uid == 0) return;

      final url =
          Uri.parse('${Env.baseUrl}/delete_search_history_item.php');

      await http.post(
        url,
        body: {
          'user_id': uid.toString(),
          'item_id': item.id.toString(),
        },
      ).timeout(const Duration(seconds: 10));

      history.removeWhere((h) => h.id == item.id);
    } catch (_) {
      // نتجاهل – شيء ثانوي
    }
  }
}
