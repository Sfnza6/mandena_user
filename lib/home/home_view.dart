import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/app_routes.dart';

import 'home_controller.dart';
import 'sections/home_header_section.dart';
import 'sections/home_offers_section.dart';
import 'sections/home_categories_section.dart';
import 'sections/home_items_section.dart';
import 'widgets/home_ui.dart';
import 'widgets/food_card.dart';
import 'widgets/hero_tags.dart';
import 'widgets/pressable_scale.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  void _openItemDetail(dynamic item, String heroTag) {
    Get.toNamed(
      AppRoutes.itemDetail,
      arguments: withItemHeroArg(item.toJson(), heroTag),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageBg = theme.scaffoldBackgroundColor;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF1F2937);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: RefreshIndicator(
          onRefresh: controller.refreshAll,
          color: HomeUi.kPrimary,
          child: Obx(() {
            if (controller.isSearching) {
              return CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  const SliverToBoxAdapter(child: HomeHeaderSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              controller.loadingSearch.value &&
                                      controller.searchResults.isEmpty
                                  ? 'جاري البحث...'
                                  : controller.searchResults.isEmpty
                                  ? 'لا توجد أصناف مطابقة'
                                  : 'نتائج البحث (${controller.searchResults.length})',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  if (controller.loadingSearch.value &&
                      controller.searchResults.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: HomeUi.kPrimary,
                        ),
                      ),
                    )
                  else if (controller.searchResults.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'جرّب كتابة حرف أو كلمة من اسم الصنف',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = controller.searchResults[index];
                          final heroTag = itemHeroTagFromModel(
                            item,
                            scope: 'home-search',
                            extra: index,
                          );

                          final soldOut = item.outOfStock;
                          final remain = item.remaining;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PressableScale(
                              onTap: () => _openItemDetail(item, heroTag),
                              child: Obx(
                                () => FoodCard(
                                  item: item,
                                  isFavorite: controller.isItemFavorite(
                                    item.id,
                                  ),
                                  onToggleFavorite: () =>
                                      controller.toggleFavoriteFromHome(item),
                                  onAddToCart: (!soldOut && item.isActive)
                                      ? () => controller.addItemToCart(item)
                                      : null,
                                  heroTag: heroTag,
                                  isSoldOut: soldOut,
                                  remaining: remain,
                                ),
                              ),
                            ),
                          );
                        }, childCount: controller.searchResults.length),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            }

            return const CustomScrollView(
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
            );
          }),
        ),
      ),
    );
  }
}
