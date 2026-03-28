import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';
import '../widgets/offer_card.dart';
import '../widgets/skeletons.dart';

class HomeOffersSection extends StatelessWidget {
  const HomeOffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();

    return SizedBox(
      height: 170,
      child: Obx(() {
        if (c.loadingOffers.value && c.offers.isEmpty) {
          return const OffersSkeleton();
        }

        if (c.offers.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: Axis.horizontal,
          itemCount: c.offers.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            return SizedBox(
              width: MediaQuery.of(context).size.width - 36,
              child: OfferCard(offer: c.offers[i]),
            );
          },
        );
      }),
    );
  }
}
