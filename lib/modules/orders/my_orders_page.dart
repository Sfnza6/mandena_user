import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/orders/my_orders_controller.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  static const Color kPrimary = Color(0xFFFF5A00);
  static const Color kPrimaryDark = Color(0xFFFF2E00);
  static const Color kBg = Color(0xFFF5F5F7);
  static const Color kCard = Colors.white;
  static const Color kTextMain = Color(0xFF111827);
  static const Color kTextSub = Color(0xFF8B95A7);
  static const Color kSoftOrange = Color(0xFFFFF1E9);

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<MyOrdersController>()
        ? Get.find<MyOrdersController>()
        : Get.put(MyOrdersController());

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final textMain = theme.textTheme.bodyLarge?.color ?? kTextMain;
    final textSub =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ?? kTextSub;
    final softOrange = isDark ? const Color(0xFF1F2937) : kSoftOrange;
    final countBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6);

    Widget tabItem(String label, bool active, int count, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: active ? softOrange : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? kPrimary : textSub,
                    fontSize: 13,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: active ? softOrange.withOpacity(.75) : countBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: active ? kPrimary : textSub,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    Widget emptyState(String text) {
      return ListView(
        children: [
          const SizedBox(height: 110),
          Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: softOrange,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 42,
                color: kPrimary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(text, style: TextStyle(color: textSub, fontSize: 14)),
          ),
        ],
      );
    }

    Widget orderTile(UserOrder o, {required bool isHistory}) {
      final (title, _) = c.statusLabel(o);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    '#${o.id}',
                    style: TextStyle(
                      color: textSub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: softOrange,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFFFD6BF)),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    'د.ل ${o.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: kPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${o.itemsCount.toString().padLeft(2, '0')} أصناف',
                    style: TextStyle(color: textSub, fontSize: 12.5),
                  ),
                  const SizedBox(width: 6),
                  Text('•', style: TextStyle(color: textSub)),
                  const SizedBox(width: 6),
                  Text(
                    c.formatDate(o.createdAt),
                    style: TextStyle(color: textSub, fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                textDirection: TextDirection.rtl,
                children: isHistory
                    ? [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => Get.toNamed(
                              '/order-details',
                              arguments: {'orderId': o.id},
                            ),
                            child: const Text(
                              'تفاصيل الطلب',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ]
                    : [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => Get.toNamed(
                              '/order-tracking',
                              arguments: {'orderId': o.id},
                            ),
                            child: const Text(
                              'تتبع الطلب',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimary,
                              side: const BorderSide(color: kPrimary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            onPressed: () => Get.toNamed(
                              '/order-details',
                              arguments: {'orderId': o.id},
                            ),
                            child: const Text(
                              'تفاصيل',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'طلباتي',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: kPrimary,
              fontSize: 28,
            ),
          ),
          iconTheme: const IconThemeData(color: kPrimary),
        ),
        body: Obx(() {
          final tab = c.tabIndex.value;
          final curCount = c.current.length;
          final hisCount = c.history.length;

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    tabItem(
                      'حاليًا',
                      tab == 0,
                      curCount,
                      () => c.tabIndex.value = 0,
                    ),
                    tabItem(
                      'السجل',
                      tab == 1,
                      hisCount,
                      () => c.tabIndex.value = 1,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => c.fetch(),
                  color: kPrimary,
                  child: c.loading.value
                      ? const Center(
                          child: CircularProgressIndicator(color: kPrimary),
                        )
                      : (tab == 0 && curCount == 0)
                      ? emptyState('لا توجد طلبات جارية')
                      : (tab == 1 && hisCount == 0)
                      ? emptyState('لا يوجد سجل طلبات بعد')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                          itemCount: tab == 0 ? curCount : hisCount,
                          itemBuilder: (_, i) {
                            final o = tab == 0 ? c.current[i] : c.history[i];
                            return orderTile(o, isHistory: tab == 1);
                          },
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
