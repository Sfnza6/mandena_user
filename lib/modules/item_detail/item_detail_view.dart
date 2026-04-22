import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/home/widgets/hero_tags.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? kText;
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ?? kMuted;
    final borderColor = isDark ? Colors.white10 : kBorder;
    final imageFallback = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFF2EEE8);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: Obx(() {
          final item = c.item;
          final args = Get.arguments;
          final heroTag =
              args is Map &&
                  (args['_heroTag']?.toString().trim().isNotEmpty == true)
              ? args['_heroTag'].toString()
              : itemHeroTagFromModel(item, scope: 'item-detail');
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
                          child: Hero(
                            tag: heroTag,
                            transitionOnUserGestures: true,
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: imageFallback,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.fastfood_rounded,
                                  color: kPrimary,
                                  size: 56,
                                ),
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
                            color: textColor,
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
                        decoration: BoxDecoration(
                          color: pageBg,
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
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.name,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.description.isNotEmpty
                                            ? item.description
                                            : 'وصف غير متوفر حالياً',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          height: 1.8,
                                        ),
                                      ),
                                    ],
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
                                  '(${c.ratingsCount.value})',
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
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
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'الإضافات',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: textColor,
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'المحذوفات',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Obx(() {
                              final list = c.removals;
                              if (list.isEmpty) {
                                return const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'لا توجد مكونات قابلة للحذف لهذا الصنف',
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
                                  return _RemovalChip(
                                    title: a.name,
                                    selected: a.selected,
                                    onTap: () => c.toggleRemoval(i),
                                  );
                                }),
                              );
                            }),
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'الكمية',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: textColor,
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
                                      style: TextStyle(
                                        color: textColor,
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'قيّم الصنف',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Obx(
                              () => Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: List.generate(5, (index) {
                                  final star = index + 1;
                                  final active = c.selectedStars.value >= star;
                                  return IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 34,
                                    ),
                                    onPressed: () =>
                                        c.selectedStars.value = star,
                                    icon: Icon(
                                      active
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: kStar,
                                      size: 28,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: Obx(
                                () => ElevatedButton(
                                  onPressed: c.ratingBusy.value
                                      ? null
                                      : c.submitRating,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    c.ratingBusy.value
                                        ? 'جارٍ حفظ التقييم...'
                                        : 'إرسال التقييم',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: cardColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'أضف تعليقك',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: c.commentTextCtrl,
                              maxLines: 3,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: 'اكتب تعليقك هنا...',
                                hintTextDirection: TextDirection.rtl,
                                filled: true,
                                fillColor: cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: kPrimary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: Obx(
                                () => OutlinedButton(
                                  onPressed: c.commentBusy.value
                                      ? null
                                      : c.submitComment,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: kPrimary,
                                    side: const BorderSide(color: kPrimary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    c.commentBusy.value
                                        ? 'جارٍ إرسال التعليق...'
                                        : 'إرسال التعليق',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: cardColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'التعليقات',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: textColor,
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
                                      color: cardColor,
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
                                          style: TextStyle(
                                            color: textColor,
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
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.vertical(
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
                            onPressed:
                                (c.isAdding.value ||
                                    c.item.outOfStock ||
                                    !c.item.isActive)
                                ? null
                                : () async => c.addToCart(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (c.item.outOfStock || !c.item.isActive)
                                  ? const Color(0xFFB8BDC7)
                                  : kPrimary,
                              disabledBackgroundColor: const Color(0xFFB8BDC7),
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              (c.item.outOfStock || !c.item.isActive)
                                  ? 'غير متاح'
                                  : (c.isAdding.value
                                        ? 'جارٍ الإضافة...'
                                        : 'أضف إلى السلة'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.white,
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
    final cardColor = Theme.of(context).cardColor;
    return Material(
      color: cardColor.withOpacity(.95),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? ItemDetailView.kText;
    final bg = selected
        ? (isDark ? const Color(0xFF2A1D14) : const Color(0xFFFFF3EC))
        : cardColor;
    final border = selected
        ? ItemDetailView.kPrimary
        : (isDark ? Colors.white10 : ItemDetailView.kBorder);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              textAlign: TextAlign.right,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
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

class _RemovalChip extends StatelessWidget {
  const _RemovalChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? ItemDetailView.kText;
    final bg = selected
        ? (isDark ? const Color(0xFF2A1D14) : const Color(0xFFFFF3EC))
        : cardColor;
    final border = selected
        ? ItemDetailView.kPrimary
        : (isDark ? Colors.white10 : ItemDetailView.kBorder);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: selected ? ItemDetailView.kPrimary : textColor,
            fontWeight: FontWeight.w800,
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? ItemDetailView.kText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: filled
              ? ItemDetailView.kPrimary
              : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: filled ? Colors.white : textColor),
      ),
    );
  }
}
