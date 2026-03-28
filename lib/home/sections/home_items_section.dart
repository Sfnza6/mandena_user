import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/app_routes.dart';

import '../home_controller.dart';
import '../widgets/food_card.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/section_title.dart';
import '../widgets/skeletons.dart';
import '../../data/models/item.dart';

class HomeItemsSection extends StatelessWidget {
  const HomeItemsSection({super.key});

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
      Get.snackbar('غير متوفر', 'هذا الصنف غير متوفر حالياً');
      return;
    }
    if (_isSoldOut(item)) {
      Get.snackbar('نفدت الكمية', 'تم استهلاك الحدّ اليومي لهذا الصنف');
      return;
    }
    Get.toNamed(AppRoutes.itemDetail, arguments: item.toJson());
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();

    return Column(
      children: [
        SectionTitleRow(
          title: 'الأصناف الرائجة',
          showAction: true,
          onTap: () => Get.toNamed(AppRoutes.homeCategories),
        ),
        SizedBox(
          height: 250,
          child: Obx(() {
            if (c.loadingMost.value && c.mostOrdered.isEmpty) {
              return const MostOrderedSkeleton();
            }

            final preview = c.mostOrdered.toList();

            if (preview.isEmpty) {
              return const Center(child: Text('لا توجد أصناف حالياً'));
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = preview[i];
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
      ],
    );
  }
}
