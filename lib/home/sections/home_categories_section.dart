import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app_routes.dart';
import '../../modules/root/root_controller.dart';
import '../home_controller.dart';
import '../widgets/category_card.dart';
import '../widgets/section_title.dart';
import '../widgets/skeletons.dart';

class HomeCategoriesSection extends StatelessWidget {
  const HomeCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();

    return Column(
      children: [
        SectionTitleRow(
          title: 'الأقسام',
          onTap: () {
            if (Get.isRegistered<RootController>()) {
              Get.find<RootController>().changeTab(1);
            } else {
              Get.toNamed(AppRoutes.homeCategories);
            }
          },
          showAction: true,
        ),
        SizedBox(
          height: 112,
          child: Obx(() {
            if (c.loadingCats.value && c.categories.isEmpty) {
              return const CategoriesSkeleton();
            }

            final preview = c.categories.take(8).toList();

            if (preview.isEmpty) {
              return const Center(child: Text('لا توجد أقسام حالياً'));
            }

            return ListView.separated(
              primary: false,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: preview.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final cat = preview[i];
                return CategoryCircleCard(
                  category: cat,
                  onTap: () {
                    if (Get.isRegistered<RootController>()) {
                      Get.find<RootController>().changeTab(1);
                    } else {
                      Get.toNamed(
                        AppRoutes.homeCategories,
                        arguments: {
                          'categoryId': cat.id,
                          'categoryName': cat.name,
                        },
                      );
                    }
                  },
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
