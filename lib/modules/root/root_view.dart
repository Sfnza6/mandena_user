import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/categories/categories_view.dart';
import 'package:mandena/modules/orders/my_orders_page.dart';

import '../../home/home_controller.dart';
import '../../home/home_view.dart';
import '../account/account_view.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_view.dart';
import '../favorites/favorites_view.dart';
import 'root_controller.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  static const Color kNavBg = Color(0xFFFFFBF8);
  static const Color kPrimary = Color(0xFFFF6A00);
  static const Color kBorder = Color(0xFFFFE1CC);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = theme.scaffoldBackgroundColor;
    final navBg = isDark ? theme.cardColor : kNavBg;
    final borderColor = isDark ? Colors.white10 : kBorder;
    final navTextColor =
        theme.textTheme.bodyMedium?.color ??
        (isDark ? Colors.white : Colors.black87);

    final rc = Get.put(RootController(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

    final cart = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);

    final tabs = [
      const HomeView(),
      const CategoriesView(),
      const MyOrdersPage(),
      const CartView(),
      const FavoritesScreen(),
      const AccountView(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(
        () => Scaffold(
          backgroundColor: pageBg,
          body: IndexedStack(index: rc.index.value, children: tabs),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: navBg,
              border: Border(top: BorderSide(color: borderColor, width: 1.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? .18 : .07),
                  blurRadius: 22,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'الرئيسية',
                      index: 0,
                      controller: rc,
                      textColor: navTextColor,
                      navBg: navBg,
                    ),
                    _NavItem(
                      icon: Icons.grid_view_rounded,
                      label: 'الأقسام',
                      index: 1,
                      controller: rc,
                      textColor: navTextColor,
                      navBg: navBg,
                    ),
                    _NavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'طلباتي',
                      index: 2,
                      controller: rc,
                      textColor: navTextColor,
                      navBg: navBg,
                    ),
                    Obx(
                      () => _NavItem(
                        icon: Icons.shopping_cart_outlined,
                        label: 'السلة',
                        index: 3,
                        controller: rc,
                        badgeCount: cart.itemsCount,
                        textColor: navTextColor,
                        navBg: navBg,
                      ),
                    ),
                    _NavItem(
                      icon: Icons.star_border_rounded,
                      label: 'المفضلة',
                      index: 4,
                      controller: rc,
                      textColor: navTextColor,
                      navBg: navBg,
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'حسابي',
                      index: 5,
                      controller: rc,
                      textColor: navTextColor,
                      navBg: navBg,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.controller,
    required this.textColor,
    required this.navBg,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final int index;
  final RootController controller;
  final Color textColor;
  final Color navBg;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final selected = controller.index.value == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => controller.changeTab(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: selected ? 34 : 22,
                  height: 3.0,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: selected ? RootView.kPrimary : Colors.transparent,
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 23,
                      color: selected
                          ? RootView.kPrimary
                          : textColor.withOpacity(.82),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -8,
                        left: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          decoration: BoxDecoration(
                            color: RootView.kPrimary,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: navBg, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    color: selected
                        ? RootView.kPrimary
                        : textColor.withOpacity(.90),
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
