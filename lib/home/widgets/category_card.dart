import 'package:flutter/material.dart';
import '../../data/models/category.dart';
import 'home_ui.dart';
import 'pressable_scale.dart';

class CategoryCircleCard extends StatelessWidget {
  const CategoryCircleCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  final CategoryModel category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EC),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: HomeUi.kSoftShadow,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  category.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.fastfood_rounded,
                    color: HomeUi.kPrimary,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: HomeUi.kTextMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
