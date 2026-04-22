import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/home/widgets/hero_tags.dart';
import 'favorites_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const Color kPrimary = Color(0xFFFF5A00);
  static const Color kPrimaryDark = Color(0xFFE14D00);
  static const Color kPageBg = Color(0xFFF7F4EF);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF241A12);
  static const Color kMuted = Color(0xFF8B8B95);
  static const Color kBorder = Color(0xFFE9E3DA);

  @override
  Widget build(BuildContext context) {
    final f = Get.find<FavoritesController>()..load();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? kText;
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ?? kMuted;
    final imageFallback = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFF2EEE8);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [kPrimary, kPrimaryDark]),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 18,
                20,
                18,
              ),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'المفضلة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (f.isBusy.value && f.favorites.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimary),
                  );
                }

                if (f.favorites.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد عناصر مضافة إلى المفضلة بعد',
                      style: TextStyle(
                        color: mutedColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  itemCount: f.favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final e = f.favorites[i];

                    final name = e['name']?.toString() ?? '';
                    final price = e['price']?.toString() ?? '-';
                    final desc = e['description']?.toString() ?? '';
                    final image = e['image_url']?.toString() ?? '';
                    final itemId =
                        int.tryParse('${e['item_id'] ?? e['id'] ?? 0}') ?? 0;

                    final heroTag = itemHeroTag(
                      id: e['id'] ?? e['item_id'] ?? itemId,
                      imageUrl: image,
                      name: name,
                      scope: 'favorites-list',
                      extra: i,
                    );

                    return InkWell(
                      onTap: () => f.openFavDetail(e, heroTag: heroTag),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.06),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Hero(
                                tag: heroTag,
                                transitionOnUserGestures: true,
                                child: image.isNotEmpty
                                    ? Image.network(
                                        image,
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 96,
                                          height: 96,
                                          color: imageFallback,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.fastfood_rounded,
                                            color: kPrimary,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        width: 96,
                                        height: 96,
                                        color: imageFallback,
                                        alignment: Alignment.center,
                                        child: const Icon(
                                          Icons.fastfood_rounded,
                                          color: kPrimary,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    name,
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    desc.isNotEmpty ? desc : 'وصف غير متوفر',
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: mutedColor,
                                      height: 1.4,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$price د.ل',
                                    style: const TextStyle(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _MiniAction(
                                        icon: Icons.shopping_cart_outlined,
                                        bg: kPrimary,
                                        fg: Colors.white,
                                        onTap: () => f.openFavDetail(
                                          e,
                                          heroTag: heroTag,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _MiniAction(
                                        icon: Icons.delete_outline_rounded,
                                        bg: const Color(0xFFFFF1F1),
                                        fg: Colors.red,
                                        onTap: () => f.toggle(itemId),
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}
