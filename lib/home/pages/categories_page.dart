import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home_controller.dart';
import '../widgets/pressable_scale.dart';
import '../../app_routes.dart';
import '../widgets/home_ui.dart';

class CategoriesPage extends StatelessWidget {
  CategoriesPage({super.key});

  final HomeController c = Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: HomeUi.kPageBg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: HomeUi.kTextMain,
          centerTitle: true,
          title: const Text(
            'الأقسام',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Obx(() {
          if (c.loadingCats.value && c.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (c.categories.isEmpty) {
            return RefreshIndicator(
              onRefresh: c.fetchCategories,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('لا توجد أقسام حالياً')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: c.fetchCategories,
            child: GridView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: c.categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (_, i) {
                final cat = c.categories[i];

                return PressableScale(
                  onTap: () => Get.toNamed(
                    AppRoutes.categories,
                    arguments: {'categoryId': cat.id, 'categoryName': cat.name},
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3EC),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: HomeUi.kSoftShadow,
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.network(
                              cat.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.fastfood_rounded,
                                color: HomeUi.kPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
