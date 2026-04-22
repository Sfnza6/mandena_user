import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';
import '../widgets/offer_card.dart';
import '../widgets/skeletons.dart';

class HomeOffersSection extends StatefulWidget {
  const HomeOffersSection({super.key});

  @override
  State<HomeOffersSection> createState() => _HomeOffersSectionState();
}

class _HomeOffersSectionState extends State<HomeOffersSection> {
  final HomeController c = Get.find<HomeController>();
  final PageController _pageController = PageController(viewportFraction: 1);
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final count = c.offers.length;
      if (!mounted || count <= 1 || !_pageController.hasClients) return;

      final next = (_currentPage + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: Obx(() {
        if (c.loadingOffers.value && c.offers.isEmpty) {
          return const OffersSkeleton();
        }

        if (c.offers.isEmpty) {
          return const SizedBox.shrink();
        }

        if (_currentPage >= c.offers.length) {
          _currentPage = 0;
        }

        return Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: c.offers.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (_, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: OfferCard(offer: c.offers[i]),
                  );
                },
              ),
            ),
            if (c.offers.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(c.offers.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFFF6A00)
                          : const Color(0xFFFF6A00).withOpacity(.25),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      }),
    );
  }
}
