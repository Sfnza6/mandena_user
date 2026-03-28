import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/app_routes.dart';
import '../../data/models/item.dart';
import 'home_ui.dart';

class TopRatedTile extends StatelessWidget {
  const TopRatedTile({
    super.key,
    required this.item,
    required this.isSoldOut,
    required this.remaining,
    this.onAddToCart,
  });

  final ItemModel item;
  final bool isSoldOut;
  final int? remaining;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    const double imgSize = 120;
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final isDark = theme.brightness == Brightness.dark;
    final textMain = isDark ? Colors.white : HomeUi.kTextMain;
    final textSub = isDark ? Colors.grey.shade400 : HomeUi.kTextSub;
    final borderColor = isDark ? Colors.white10 : HomeUi.kBorder;

    final hasDiscount = (item.discount ?? '').trim().isNotEmpty;
    final unavailable = !item.isActive || isSoldOut;
    final statusText = !item.isActive
        ? 'غير متوفر'
        : (isSoldOut ? 'نفدت الكمية' : null);

    final double r = item.rating.toDouble();
    final String ratingLabel = r > 0
        ? '${r.toStringAsFixed(1)} / 5'
        : '0.0 / 5';

    return Opacity(
      opacity: unavailable ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: imgSize),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: imgSize,
                      height: imgSize,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: theme.canvasColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: textSub),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    statusText ?? ratingLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: statusText != null
                                          ? Colors.red
                                          : textMain,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'د.ل ${item.price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: textMain,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Material(
                                  color: unavailable
                                      ? Colors.grey
                                      : HomeUi.kPrimary,
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: unavailable
                                        ? null
                                        : (onAddToCart ??
                                              () => Get.toNamed(
                                                AppRoutes.itemDetail,
                                                arguments: item.toJson(),
                                              )),
                                    borderRadius: BorderRadius.circular(8),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 7,
                                      ),
                                      child: Text(
                                        'أضف للسلة',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
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
                if (hasDiscount)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: HomeUi.kPrimary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        item.discount!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (statusText != null)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(.9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
