import 'package:flutter/material.dart';
import '../../data/models/item.dart';
import 'home_ui.dart';

class FoodCard extends StatelessWidget {
  const FoodCard({
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
    final unavailable = !item.isActive || isSoldOut;

    return Opacity(
      opacity: unavailable ? .72 : 1,
      child: Container(
        width: 176,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HomeUi.kBorder),
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
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF2EEE8),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.fastfood_rounded,
                          color: HomeUi.kPrimary,
                          size: 32,
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
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.94),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        color: HomeUi.kPrimary,
                        size: 20,
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
                        style: const TextStyle(
                          color: Colors.white,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: HomeUi.kTextMain,
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
                        style: const TextStyle(
                          fontSize: 12.2,
                          color: HomeUi.kTextSub,
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
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (isSoldOut)
                          const Text(
                            'نفدت الكمية',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        else if (remaining != null)
                          Text(
                            'المتبقي $remaining',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: HomeUi.kTextSub,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          const Text(
                            'متوفر الآن',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: HomeUi.kTextSub,
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
