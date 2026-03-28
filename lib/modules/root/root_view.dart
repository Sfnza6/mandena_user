import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/categories/categories_view.dart';

import '../../home/home_controller.dart';
import '../../home/home_view.dart';
import '../account/account_view.dart';
import '../cart/cart_view.dart';
import '../favorites/favorites_view.dart';
import 'root_controller.dart';

class RootView extends StatelessWidget {
  const RootView({super.key});

  static const Color kPageBg = Color(0xFFF4F4F6);
  static const Color kNavBg = Color(0xFFFFFBF8);
  static const Color kPrimary = Color(0xFFFF6A00);
  static const Color kPrimaryDeep = Color(0xFFFF4D00);
  static const Color kPrimarySoft = Color(0xFFFF8A3D);
  static const Color kInactive = Color(0xFFB56A2A);
  static const Color kBorder = Color(0xFFFFE1CC);

  @override
  Widget build(BuildContext context) {
    final rc = Get.put(RootController(), permanent: true);
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
          backgroundColor: kPageBg,
          body: IndexedStack(index: rc.index.value, children: tabs),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: kNavBg,
              border: Border(top: BorderSide(color: kBorder, width: 1.15)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 22,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 10),
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
                      icon: Icons.star_border_outlined,
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
                    gradient: selected
                        ? const LinearGradient(
                            colors: [RootView.kPrimary, RootView.kPrimarySoft],
                          )
                        : null,
                    color: selected ? null : Colors.transparent,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: selected
                          ? const [RootView.kPrimarySoft, RootView.kPrimaryDeep]
                          : const [RootView.kInactive, RootView.kInactive],
                    ).createShader(bounds);
                  },
                  child: Icon(icon, size: 23, color: Colors.white),
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
                    color: selected ? RootView.kPrimary : RootView.kInactive,
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
