import 'package:flutter/material.dart';
import 'package:mandena/home/widgets/hero_tags.dart';
import '../../data/models/item.dart';
import 'home_ui.dart';

class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.item,
    required this.isSoldOut,
    required this.remaining,
    required this.isFavorite,
    this.onToggleFavorite,
    this.onAddToCart,
    this.heroTag,
  });

  final ItemModel item;
  final bool isSoldOut;
  final int? remaining;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAddToCart;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final unavailable = !item.isActive || isSoldOut;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textMain = theme.textTheme.bodyLarge?.color ?? HomeUi.kTextMain;
    final textSub =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ?? HomeUi.kTextSub;
    final borderColor = isDark ? Colors.white10 : HomeUi.kBorder;
    final imageFallback = isDark
        ? const Color(0xFF1F2937)
        : const Color(0xFFF2EEE8);

    return Opacity(
      opacity: unavailable ? .72 : 1,
      child: Container(
        width: 176,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: HomeUi.kSoftShadow,
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            SizedBox(
              height: 122,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag:
                          heroTag ??
                          itemHeroTagFromModel(item, scope: 'food-card'),
                      transitionOnUserGestures: true,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: imageFallback,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.fastfood_rounded,
                            color: HomeUi.kPrimary,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Material(
                      color: Colors.white.withOpacity(.94),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onToggleFavorite,
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: Icon(
                            isFavorite
                                ? Icons.star_rounded
                                : Icons.star_border_outlined,
                            color: HomeUi.kPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: HomeUi.kPrimaryDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'د.ل ${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: cardColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Text(
                        item.description.isEmpty
                            ? 'وصفة شهية بطابع خاص من مطبخنا.'
                            : item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.2,
                          color: textSub,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (onAddToCart != null && !unavailable)
                          InkWell(
                            onTap: onAddToCart,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: HomeUi.kPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add,
                                color: cardColor,
                                size: 18,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (isSoldOut)
                          const Text(
                            'غير متوفر',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        else if (remaining != null)
                          Text(
                            'المتبقي $remaining',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textSub,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          Text(
                            unavailable ? 'غير متوفر' : 'متوفر الآن',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textSub,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
