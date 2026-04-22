import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/home/widgets/hero_tags.dart';
import 'items_controller.dart';
import '../../data/models/item.dart';

class ItemsView extends GetView<ItemsController> {
  const ItemsView({super.key});

  // 🎨 نفس ألوان طلباتي / Root
  static const Color kPrimary = Color(0xFF6F3F17); // البني الثقيل
  static const Color kBg = Color(0xFFF7F4EF); // خلفية كريمية ناعمة
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE0D6CC);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color brown = kPrimary;
    final Color bgColor = isDark ? theme.scaffoldBackgroundColor : kBg;
    final Color cardColor = isDark ? theme.cardColor : kCard;
    final Color borderColor = isDark ? Colors.white24 : kBorder;
    final Color primaryIconColor = isDark ? brown : brown;
    final Color titleColor = isDark ? Colors.white : Colors.black87;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: true,
          title: Obx(
            () => Text(
              controller.pageTitle.value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: primaryIconColor,
              ),
            ),
          ),
          iconTheme: IconThemeData(color: primaryIconColor),
        ),
        body: Column(
          children: [
            // 🔎 شريط بحث بنفس الروح
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller.searchCtrl,
                  onChanged: controller.onSearchChanged,
                  textDirection: TextDirection.rtl,
                  cursorColor: primaryIconColor,
                  style: TextStyle(color: titleColor),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن صنف',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black38,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: primaryIconColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Obx(() {
                if (controller.loading.value && controller.filtered.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryIconColor,
                    ),
                  );
                }
                if (controller.filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد أصناف',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                final items = controller.filtered;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .70,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    // ✅ نفس المنطق: فتح التفاصيل
                    final heroTag = itemHeroTagFromModel(
                      it,
                      scope: 'items-grid',
                      extra: i,
                    );
                    return GestureDetector(
                      onTap: () => controller.openDetail(it, heroTag: heroTag),
                      child: _ItemCard(it, heroTag: heroTag),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard(this.it, {required this.heroTag});
  final ItemModel it;
  final String heroTag;

  static const Color kPrimary = ItemsView.kPrimary;
  static const Color kCard = ItemsView.kCard;
  static const Color kBorder = ItemsView.kBorder;
  static const Color kBg = ItemsView.kBg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color brown = kPrimary;
    final Color cardColor = isDark ? theme.cardColor : kCard;
    final Color borderColor = isDark
        ? Colors.white24
        : kBorder.withOpacity(0.8);
    final Color textMain = isDark ? Colors.white : Colors.black87;
    final Color textSub = isDark ? Colors.white70 : Colors.black54;
    final Color priceColor = brown;
    final Color placeholderBg = isDark ? theme.scaffoldBackgroundColor : kBg;
    final Color iconColor = brown; // 🌓 في الوضع الليلي أيضاً بني

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .4 : .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // صورة الصنف
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Hero(
              tag: heroTag,
              transitionOnUserGestures: true,
              child: it.imageUrl.isNotEmpty
                  ? Image.network(
                      it.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _placeholder(placeholderBg, iconColor),
                    )
                  : _placeholder(placeholderBg, iconColor),
            ),
          ),

          // التفاصيل
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  it.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: textMain,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 4),
                Text(
                  it.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textSub, fontSize: 11.5),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${it.price.toStringAsFixed(0)} د.ل',
                    style: TextStyle(
                      color: priceColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _placeholder(Color bg, Color iconColor) => Container(
    color: bg,
    child: Center(
      child: Icon(Icons.image_not_supported_outlined, color: iconColor),
    ),
  );
}
