import 'package:flutter/material.dart';

class OffersSkeleton extends StatelessWidget {
  const OffersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: MediaQuery.of(context).size.width * 0.85,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(.7),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
    );
  }
}

class CategoriesSkeleton extends StatelessWidget {
  const CategoriesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final accent = cardColor.withOpacity(.7);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, __) => Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: 6),
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: accent.withOpacity(.6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

class MostOrderedSkeleton extends StatelessWidget {
  const MostOrderedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final accent = cardColor.withOpacity(.7);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, __) => Container(
        width: 220,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 12,
                width: 120,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.8),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                height: 10,
                width: 160,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.6),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Container(
                    height: 10,
                    width: 60,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 12,
                    width: 40,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
