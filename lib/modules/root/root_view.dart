import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/categories/categories_view.dart';

import '../../home/home_view.dart';
import '../../home/home_controller.dart';
import '../cart/cart_view.dart';
import '../favorites/favorites_view.dart';
import '../account/account_view.dart';
import 'root_controller.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  static const Color kPrimary = Color(0xFF8A531C);
  static const Color kActive = Color(0xFFD1B06B);
  static const Color kBg = Color(0xFFF7F4EF);
  static const Color kNavBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    final rc = Get.put(RootController(), permanent: true);

    // مهم جدًا: تسجيل HomeController قبل بناء HomeView
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

    final tabs = [
      const HomeView(),
      const CategoriesView(),
      const CartView(),
      const FavoritesScreen(),
      const AccountView(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Obx(
        () => Scaffold(
          backgroundColor: kBg,
          body: IndexedStack(index: rc.index.value, children: tabs),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: kNavBg,
              border: Border(top: BorderSide(color: Color(0xFFF0E8DD))),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'الرئيسية',
                      index: 0,
                      controller: rc,
                    ),
                    _NavItem(
                      icon: Icons.grid_view_rounded,
                      label: 'الأقسام',
                      index: 1,
                      controller: rc,
                    ),
                    _NavItem(
                      icon: Icons.shopping_cart_outlined,
                      label: 'السلة',
                      index: 2,
                      controller: rc,
                    ),
                    _NavItem(
                      icon: Icons.favorite_border_rounded,
                      label: 'المفضلة',
                      index: 3,
                      controller: rc,
                    ),
                    _NavItem(
                      icon: Icons.person_outline_rounded,
                      label: 'حسابي',
                      index: 4,
                      controller: rc,
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
  });

  final IconData icon;
  final String label;
  final int index;
  final RootController controller;

  static const Color kPrimary = RootView.kPrimary;
  static const Color kActive = RootView.kActive;

  @override
  Widget build(BuildContext context) {
    final selected = controller.index.value == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => controller.changeTab(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: selected ? kActive : kPrimary),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? kActive : kPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
