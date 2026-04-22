import 'package:flutter/material.dart';
import '../../data/models/offer.dart';
import 'home_ui.dart';

class OfferCard extends StatelessWidget {
  const OfferCard({super.key, required this.offer});

  final OfferModel offer;

  @override
  Widget build(BuildContext context) {
    final hasImage = offer.imageUrl.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: HomeUi.kPrimaryDark,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: HomeUi.kSoftShadow,
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(
                offer.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackBackground(),
              )
            else
              _fallbackBackground(),

            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.10),
                    Colors.black.withOpacity(.28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [HomeUi.kPrimary, HomeUi.kPrimaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Center(
        child: Icon(Icons.local_offer_rounded, color: Colors.white, size: 42),
      ),
    );
  }
}
