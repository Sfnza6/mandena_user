import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';
import '../widgets/offer_card.dart';

class OffersPage extends StatelessWidget {
  OffersPage({super.key});

  final HomeController c = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('العروض')),
        body: Obx(() {
          if (c.loadingOffers.value && c.offers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (c.offers.isEmpty) {
            return RefreshIndicator(
              onRefresh: c.fetchOffers,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('لا توجد عروض حالياً')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: c.fetchOffers,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: c.offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                return SizedBox(
                  height: 180,
                  child: OfferCard(offer: c.offers[i]),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
