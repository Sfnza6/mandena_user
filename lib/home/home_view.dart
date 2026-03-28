import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'home_controller.dart';
import 'sections/home_header_section.dart';
import 'sections/home_offers_section.dart';
import 'sections/home_categories_section.dart';
import 'sections/home_items_section.dart';
import 'widgets/home_ui.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: HomeUi.kPageBg,
        body: RefreshIndicator(
          onRefresh: controller.refreshAll,
          color: HomeUi.kPrimary,
          child: const CustomScrollView(
            physics: BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: HomeHeaderSection()),
              SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: HomeOffersSection()),
              SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(child: HomeCategoriesSection()),
              SliverToBoxAdapter(child: SizedBox(height: 6)),
              SliverToBoxAdapter(child: HomeItemsSection()),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
