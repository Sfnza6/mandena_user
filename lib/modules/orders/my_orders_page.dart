import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/orders/my_orders_controller.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  // 🎨 ألوان البني الأصلية
  static const Color kPrimary = Color(0xFF6F3F17); // بني ثقيل
  static const Color kBg = Color(0xFFF7F8FC); // خلفية ناعمة
  static const Color kCard = Colors.white;
  static const Color kTextMain = Color(0xFF2D2D2D);
  static const Color kTextSub = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final c = Get.isRegistered<MyOrdersController>()
        ? Get.find<MyOrdersController>()
        : Get.put(MyOrdersController());

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color brown = kPrimary;
    final Color bgColor = isDark ? theme.scaffoldBackgroundColor : kBg;
    final Color cardColor = isDark ? theme.cardColor : kCard;
    final Color primaryIconColor = isDark ? brown : brown;
    final Color textMainColor = isDark ? Colors.white : kTextMain;
    final Color textSubColor = isDark ? Colors.white70 : kTextSub;

    // ===== التبويبات (رجعنا البني) =====
    Widget tabItem(String label, bool active, int count, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? kPrimary.withOpacity(isDark ? 0.18 : 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? brown : textMainColor.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (active ? brown : textSubColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: active ? brown : textSubColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // ===== حالة فارغة =====
    Widget emptyState(String text) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: primaryIconColor.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              text,
              style: TextStyle(color: textSubColor, fontSize: 13),
            ),
          ),
        ],
      );
    }

    // ===== بطاقة الطلب (مع البني) =====
    Widget orderTile(UserOrder o, {required bool isHistory}) {
      final (title, color) = c.statusLabel(o);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // السطر الأول
              Row(
                children: [
                  Text(
                    '#${o.id}',
                    style: TextStyle(
                      color: textSubColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: brown.withOpacity(.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: brown.withOpacity(.25)),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: brown,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // السطر الثاني
              Row(
                children: [
                  Text(
                    c.formatDate(o.createdAt),
                    style: TextStyle(color: textSubColor, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Text('•', style: TextStyle(color: textSubColor)),
                  const SizedBox(width: 6),
                  Text(
                    '${o.itemsCount.toString().padLeft(2, '0')} أصناف',
                    style: TextStyle(color: textSubColor, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    'د.ل ${o.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: brown,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 🔻 الأزرار:
              // - في "حاليًا": تتبع الطلب + تفاصيل (مثل ما هي)
              // - في "السجل": زر تفاصيل واحد بعرض كامل وبنفس ستايل زر التقييم القديم
              Row(
                children: isHistory
                    ? [
                        // 🟤 السجل: زر تفاصيل فقط بعرض كامل
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              elevation: 0,
                            ),
                            onPressed: () => Get.toNamed(
                              '/order-details',
                              arguments: {'orderId': o.id},
                            ),
                            child: const Text(
                              'تفاصيل',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ]
                    : [
                        // 🟢 تبويب "حاليًا": نفس المنطق القديم
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              elevation: 0,
                            ),
                            onPressed: () => Get.toNamed(
                              '/order-tracking',
                              arguments: {'orderId': o.id},
                            ),
                            child: const Text(
                              'تتبع الطلب',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: brown),
                              foregroundColor: brown,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                            onPressed: () => Get.toNamed(
                              '/order-details',
                              arguments: {'orderId': o.id},
                            ),
                            child: const Text('تفاصيل'),
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
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'طلباتي',
            style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
          ),
          iconTheme: IconThemeData(color: primaryIconColor),
        ),
        body: Obx(() {
          final tab = c.tabIndex.value;
          final curCount = c.current.length;
          final hisCount = c.history.length;

          return Column(
            children: [
              // فريم التبويبات
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
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

              // القائمة
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => c.fetch(),
                  child: c.loading.value
                      ? Center(
                          child: CircularProgressIndicator(
                            color: primaryIconColor,
                          ),
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
