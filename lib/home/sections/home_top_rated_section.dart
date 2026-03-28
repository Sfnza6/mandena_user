import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/top_rated_tile.dart';
import '../../../data/models/item.dart';
import '../../app_routes.dart';

class HomeTopRatedSection extends StatelessWidget {
  const HomeTopRatedSection({super.key});

  bool _isSoldOut(ItemModel it) {
    final q = it.dailyQuota;
    final used = it.quotaUsed;
    if (q == null) return false;
    final rem = q - used;
    return rem <= 0;
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
    final c = Get.find<HomeController>();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
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
              padding: EdgeInsets.only(top: 24, bottom: 8),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (c.topRated.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 10),
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
    );
  }
}
