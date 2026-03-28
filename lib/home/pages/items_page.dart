import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';
import '../widgets/food_card.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/top_rated_tile.dart';
import '../../../data/models/item.dart';
import '../../app_routes.dart';

class ItemsPage extends StatelessWidget {
  ItemsPage({super.key});

  final HomeController c = Get.find<HomeController>();

  bool _isSoldOut(ItemModel it) {
    final q = it.dailyQuota;
    final used = it.quotaUsed;
    if (q == null) return false;
    return (q - used) <= 0;
  }

  int? _remaining(ItemModel it) {
    final q = it.dailyQuota;
    if (q == null) return null;
    final rem = q - it.quotaUsed;
    return rem < 0 ? 0 : rem;
  }

  void _openItemDetail(ItemModel item) {
    if (!item.isActive) {
      Get.snackbar(
        'غير متوفر',
        'هذا الصنف غير متوفر حالياً',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (_isSoldOut(item)) {
      Get.snackbar(
        'نفدت الكمية',
        'تم استهلاك الحدّ اليومي لهذا الصنف',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    Get.toNamed(AppRoutes.itemDetail, arguments: item.toJson());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الأصناف')),
        body: RefreshIndicator(
          onRefresh: () async {
            await c.fetchMostOrdered();
            await c.fetchTopRated();
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الأكثر طلباً',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              SizedBox(
                height: 240,
                child: Obx(() {
                  if (c.loadingMost.value && c.mostOrdered.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (c.mostOrdered.isEmpty) {
                    return const Center(child: Text('لا توجد أصناف حالياً'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: c.mostOrdered.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final item = c.mostOrdered[i];
                      final soldOut = _isSoldOut(item);
                      final remain = _remaining(item);

                      return PressableScale(
                        onTap: () => _openItemDetail(item),
                        child: FoodCard(
                          item: item,
                          isSoldOut: soldOut,
                          remaining: remain,
                          onAddToCart: (!soldOut && item.isActive)
                              ? () => c.addItemToCart(item)
                              : null,
                        ),
                      );
                    },
                  );
                }),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'الأعلى تقييماً',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Obx(() {
                if (c.loadingTop.value && c.topRated.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (c.topRated.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: Text('لا توجد أصناف مقيّمة حالياً')),
                  );
                }

                return Column(
                  children: c.topRated.map((item) {
                    final soldOut = _isSoldOut(item);
                    final remain = _remaining(item);

                    return PressableScale(
                      onTap: () => _openItemDetail(item),
                      child: TopRatedTile(
                        item: item,
                        isSoldOut: soldOut,
                        remaining: remain,
                        onAddToCart: (!soldOut && item.isActive)
                            ? () => c.addItemToCart(item)
                            : null,
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
