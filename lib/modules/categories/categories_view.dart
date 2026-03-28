import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app_routes.dart';
import '../../home/home_controller.dart';
import '../../data/models/category.dart';
import '../../data/models/item.dart';

const _kPrimary = Color(0xFFFF5A00);
const _kPrimaryDark = Color(0xFFFF2E00);
const _kPageBg = Color(0xFFF5F5F7);
const _kCard = Colors.white;
const _kText = Color(0xFF111827);
const _kMuted = Color(0xFF8B95A7);

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  static bool _cacheInitDone = false;
  static const _catsCacheKey = 'evoranta_cats_cache_v1';

  late HomeController c;
  final _searchCtrl = TextEditingController();
  final _searchQuery = ''.obs;
  final _selectedCatId = RxnInt();

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(HomeController(), permanent: true);

    if (!_cacheInitDone) {
      _cacheInitDone = true;
      _initCache(c);
    }

    final args = Get.arguments;
    if (args is Map && args['categoryId'] != null) {
      final id = args['categoryId'];
      _selectedCatId.value = id is int ? id : int.tryParse('$id');
    }

    _searchCtrl.addListener(() {
      _searchQuery.value = _searchCtrl.text.trim();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static Future<void> _initCache(HomeController c) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString(_catsCacheKey);
      if (s != null && s.isNotEmpty && c.categories.isEmpty) {
        final data = jsonDecode(s);
        if (data is List) {
          final list = data
              .map(
                (e) =>
                    CategoryModel.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
          c.categories.assignAll(list);
        }
      }
    } catch (_) {}

    ever<List<CategoryModel>>(c.categories, (list) async {
      try {
        final sp = await SharedPreferences.getInstance();
        final data = list
            .map(
              (cat) => {
                'id': cat.id,
                'name': cat.name,
                'image_url': cat.imageUrl,
              },
            )
            .toList();
        await sp.setString(_catsCacheKey, jsonEncode(data));
      } catch (_) {}
    });
  }

  List<ItemModel> _filteredItems() {
    final all = [...c.mostOrdered, ...c.topRated];
    final seen = <int>{};
    final unique = all.where((it) {
      if (seen.contains(it.id)) return false;
      seen.add(it.id);
      return true;
    }).toList();

    var result = unique;
    if (_selectedCatId.value != null) {
      result = result
          .where((it) => it.categoryId == _selectedCatId.value)
          .toList();
    }

    final q = _searchQuery.value.toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((it) => it.name.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kPageBg,
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kPrimary, _kPrimaryDark],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 16,
                16,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Spacer(),
                      // IconButton(
                      //   onPressed: () => Get.back(),
                      //   icon: const Icon(
                      //     Icons.arrow_forward_ios_rounded,
                      //     color: Colors.white,
                      //   ),
                      // ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'الأقسام',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.search_rounded, color: _kMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              hintText: 'ابحث في القائمة...',
                              hintStyle: TextStyle(color: _kMuted),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.rtl,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'تصفية',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                final items = _filteredItems();
                return RefreshIndicator(
                  onRefresh: c.refreshAll,
                  color: _kPrimary,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'جميع الأقسام',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: _kText,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((_, i) {
                            final cat = c.categories[i];
                            final selected = _selectedCatId.value == cat.id;
                            return InkWell(
                              onTap: () {
                                if (_selectedCatId.value == cat.id) {
                                  _selectedCatId.value = null;
                                } else {
                                  _selectedCatId.value = cat.id;
                                }
                              },
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _kCard,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: selected
                                        ? _kPrimary
                                        : const Color(0xFFE9EDF3),
                                    width: selected ? 1.4 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3EC),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.network(
                                            cat.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.fastfood_rounded,
                                                  color: _kPrimary,
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        cat.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: _kText,
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }, childCount: c.categories.length),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 0.82,
                              ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              const Text(
                                'جميع الأصناف',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: _kText,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 26,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${items.length} صنف',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: _kMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (items.isEmpty)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text('لا توجد أصناف في هذا القسم'),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate((_, i) {
                              final item = items[i];
                              return InkWell(
                                onTap: () => Get.toNamed(
                                  AppRoutes.itemDetail,
                                  arguments: item.toJson(),
                                ),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _kCard,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.05),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Image.network(
                                                  item.imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        color: const Color(
                                                          0xFFF2EEE8,
                                                        ),
                                                        alignment:
                                                            Alignment.center,
                                                        child: const Icon(
                                                          Icons
                                                              .fastfood_rounded,
                                                          color: _kPrimary,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 10,
                                                left: 10,
                                                child: Container(
                                                  width: 34,
                                                  height: 34,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.white,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.star_border_outlined,
                                                    color: _kPrimary,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          10,
                                          10,
                                          10,
                                          12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              item.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                color: _kText,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                height: 1.25,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                '${item.price.toStringAsFixed(0)} د.ل',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  color: _kPrimary,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }, childCount: items.length),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  childAspectRatio: .72,
                                ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
