import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'item_detail_controller.dart';

class ItemDetailView extends StatelessWidget {
  const ItemDetailView({super.key});

  static const Color kPrimary = Color(0xFFFF5A00);
  static const Color kPageBg = Color(0xFFF5F5F7);
  static const Color kText = Color(0xFF111827);
  static const Color kMuted = Color(0xFF8B95A7);
  static const Color kBorder = Color(0xFFE9EDF3);
  static const Color kStar = Color(0xFFFFC83D);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ItemDetailController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kPageBg,
        body: Obx(() {
          final item = c.item;
          final fav = c.isFavorite.value;
          final avg = c.avgRating.value <= 0 ? item.rating : c.avgRating.value;

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 330,
                          width: double.infinity,
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF2EEE8),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.fastfood_rounded,
                                color: kPrimary,
                                size: 56,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 18,
                          child: _CircleBtn(
                            icon: fav
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: fav ? kStar : kText,
                            onTap: c.toggleFavorite,
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          right: 18,
                          child: _CircleBtn(
                            icon: Icons.arrow_back_rounded,
                            color: kText,
                            onTap: Get.back,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -8),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: kPageBg,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(18, 24, 18, 110),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          textDirection: TextDirection.rtl,
                          children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.name,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: kText,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'تفاصيل الصنف',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: kMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Text(
                                    '${item.price.toStringAsFixed(0)} د.ل',
                                    style: const TextStyle(
                                      color: kPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              textDirection: TextDirection.rtl,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '(${c.comments.length} تقييم)',
                                  style: const TextStyle(
                                    color: kMuted,
                                    fontSize: 12.5,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3D8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        avg.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: kText,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Color(0xFFF4B400),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              item.description.isNotEmpty
                                  ? item.description
                                  : 'وصف غير متوفر حالياً',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: kMuted,
                                fontSize: 14,
                                height: 1.8,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'الإضافات',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: kText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Obx(() {
                              final list = c.additions;
                              if (list.isEmpty) {
                                return const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'لا توجد إضافات لهذا الصنف',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(color: kMuted),
                                  ),
                                );
                              }
                              return Wrap(
                                textDirection: TextDirection.rtl,
                                spacing: 10,
                                runSpacing: 10,
                                alignment: WrapAlignment.end,
                                children: List.generate(list.length, (i) {
                                  final a = list[i];
                                  return _AddonChip(
                                    title: a.name,
                                    price: a.price,
                                    selected: a.selected,
                                    onTap: () => c.toggleAddition(i),
                                  );
                                }),
                              );
                            }),
                            const SizedBox(height: 18),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'الكمية',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: kText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Obx(
                              () => Row(
                                textDirection: TextDirection.rtl,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _QtyCircle(
                                    icon: Icons.remove,
                                    onTap: c.decQty,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 22,
                                    ),
                                    child: Text(
                                      '${c.qty.value}',
                                      style: const TextStyle(
                                        color: kText,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  _QtyCircle(
                                    icon: Icons.add,
                                    onTap: c.incQty,
                                    filled: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'التعليقات',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: kText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Obx(() {
                              if (c.loadingComments.value) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: kPrimary,
                                  ),
                                );
                              }
                              if (c.comments.isEmpty) {
                                return const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'لا توجد تعليقات بعد',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(color: kMuted),
                                  ),
                                );
                              }
                              return Column(
                                children: c.comments.take(3).map((cm) {
                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: kBorder),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          cm.userName,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: kText,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          cm.comment,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            color: kMuted,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    12,
                    18,
                    MediaQuery.of(context).padding.bottom + 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Obx(
                        () => Text(
                          '${c.total.toStringAsFixed(0)} د.ل',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: c.isAdding.value
                                ? null
                                : () async => c.addToCart(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              c.isAdding.value
                                  ? 'جارٍ الإضافة...'
                                  : 'أضف إلى السلة',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.95),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: color)),
      ),
    );
  }
}

class _AddonChip extends StatelessWidget {
  const _AddonChip({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3EC) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? ItemDetailView.kPrimary : ItemDetailView.kBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: ItemDetailView.kText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '+${price.toStringAsFixed(0)} د.ل',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: ItemDetailView.kPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyCircle extends StatelessWidget {
  const _QtyCircle({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: filled ? ItemDetailView.kPrimary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: filled ? Colors.white : ItemDetailView.kText),
      ),
    );
  }
}
