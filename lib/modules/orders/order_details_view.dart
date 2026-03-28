import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/orders/order_details_controller.dart';

class OrderDetailsView extends GetView<OrderDetailsController> {
  const OrderDetailsView({super.key});

  // 🎨 نفس جو "طلباتي"
  static const Color brown = Color(0xFF6F3F17); // البني الثقيل الأساسي
  static const Color kBg = Color(0xFFF7F4EF); // خلفية كريمية ناعمة
  static const Color kChipBg = Color(0xFFEADFD3); // خلفية الشارات
  static const Color kItemBg = Color(0xFFF7F2EC); // خلفية كرت الأصناف

  @override
  Widget build(BuildContext context) {
    // ✅ تأكيد تسجيل الكنترولر قبل استخدام GetView.controller
    if (!Get.isRegistered<OrderDetailsController>()) {
      Get.put(OrderDetailsController());
    }

    // 🌓 ثيم
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const Color brownConst = brown;
    final Color primaryIconColor = isDark ? brownConst : brownConst;
    final Color bgColor = isDark ? theme.scaffoldBackgroundColor : kBg;
    final Color cardColor = isDark ? theme.cardColor : Colors.white;
    final Color itemBgColor = isDark
        ? theme.cardColor.withOpacity(0.2)
        : kItemBg;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'تفاصيل الطلب',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: primaryIconColor,
            ),
          ),
          iconTheme: IconThemeData(color: primaryIconColor),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator(color: brown));
          }
          final h = controller.header.value;
          if (h == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: isDark ? primaryIconColor : const Color(0xFFCBB9A2),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'لا توجد بيانات لهذا الطلب',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.fetch,
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(color: brown),
                    ),
                  ),
                ],
              ),
            );
          }

          final d = controller.driver.value;

          return RefreshIndicator(
            color: brown,
            onRefresh: controller.fetch,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              children: [
                // 🔹 بطاقة رأسية للطلب (رقم + حالة + معلومات أساسية)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // رقم الطلب + شارة الحالة
                      Row(
                        children: [
                          Text(
                            '#${h.id}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: kChipBg.withOpacity(.8),
                              border: Border.all(color: brown.withOpacity(.25)),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Text(
                              // نفس h.status لكن اللون ثابت
                              // (لو تحب تغييره لاحقًا، خليه كما هو)
                              '',
                              style: TextStyle(
                                color: brown,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ✅ نرجع عرض الحالة بالنص الأصلي (حتى لا نحذف شيء)
                      const SizedBox(height: 4),
                      Text(
                        h.status,
                        style: const TextStyle(
                          color: brown,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'نوع التوصيل: ${controller.deliveryTypeArabic(h.statusOrder)}',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      if (h.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'العنوان: ${h.address}',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'التاريخ: ${h.createdAt}',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ✅ معلومات الدفع + رسالة الدفع أونلاين (إن وجدت)
                _buildPaymentInfo(h),

                const SizedBox(height: 16),

                const Text(
                  'الأصناف',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: brown,
                  ),
                ),
                const SizedBox(height: 8),

                ...controller.items.map(
                  (it) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: itemBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // السطر الرئيسي للصنف
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'الكمية: ${it.quantity} × ${it.price.toStringAsFixed(2)} د.ل',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              (it.lineTotalWithExtras > 0
                                      ? it.lineTotalWithExtras
                                      : it.lineTotal)
                                  .toStringAsFixed(2),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('د.ل'),
                          ],
                        ),

                        // الإضافات
                        if (it.extras.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'الإضافات',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...it.extras.map(
                            (ex) => Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${ex.name} (${ex.quantity} × ${ex.price.toStringAsFixed(2)} د.ل)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  ex.lineTotal.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('د.ل'),
                              ],
                            ),
                          ),
                        ],

                        // المكوّنات المُضافة (مع السعر)
                        if (it.componentsAdd.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'المكوّنات المُضافة',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...it.componentsAdd.map(
                            (c) => Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${c.name} (${c.quantity} × ${c.price.toStringAsFixed(2)} د.ل)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  (c.price * c.quantity).toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('د.ل'),
                              ],
                            ),
                          ),
                        ],

                        // المكوّنات المحذوفة (بدون سعر)
                        if (it.componentsRem.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'المكوّنات المحذوفة',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...it.componentsRem.map((c) {
                            final label = (c.name.trim().isNotEmpty)
                                ? c.name
                                : (c.id > 0 ? '#${c.id}' : '— محذوف —');
                            return const Row(children: []).copyWith(
                              children: [
                                Expanded(
                                  child: Text(
                                    '• $label',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                const Divider(height: 28),

                // رسوم التوصيل
                Row(
                  children: [
                    Text(
                      'رسوم التوصيل',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(),
                    const Spacer(),
                    Text(
                      h.deliveryFee.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('د.ل'),
                  ],
                ),
                const SizedBox(height: 8),

                // الإجمالي النهائي
                Row(
                  children: const [
                    Text(
                      'الإجمالي النهائي',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: brown,
                      ),
                    ),
                    Spacer(),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(),
                    const Spacer(),
                    Text(
                      controller.computedGrandTotal.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: brown,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('د.ل'),
                  ],
                ),

                // السائق
                if (d != null) ...[
                  const Divider(height: 28),
                  const Text(
                    'السائق',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: brown,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin, color: brown),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (d['name'] ?? '-').toString(),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (d['phone'] ?? '').toString(),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  /// كارت معلومات الدفع + رسالة الدفع أونلاين
  Widget _buildPaymentInfo(OrderHeaderModel h) {
    // ✅ أي قيمة غير 0 في paymentMethod → أونلاين
    final isOnline =
        (h.paymentMethod != 0) ||
        (h.gateway.trim().isNotEmpty &&
            h.gateway.toLowerCase().trim() != 'cash');

    String methodLabel = isOnline ? 'دفع أونلاين' : 'دفع عند الاستلام';

    String bankLabel = 'غير محدد';
    switch (h.gateway.toLowerCase()) {
      case 'yesser':
        bankLabel = 'مصرف الجمهورية – يسر أونلاين';
        break;
      case 'masrafy':
        bankLabel = 'المصرف التجاري الوطني – مصرفي';
        break;
      case 'sahari':
        bankLabel = 'مصرف الصحاري';
        break;
      case 'aman':
        bankLabel = 'مصرف الأمان';
        break;
      case 'cash':
      case '':
        bankLabel = isOnline ? 'غير محدد' : '—';
        break;
      default:
        bankLabel = h.gateway;
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الدفع',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: brown,
              ),
            ),
            const SizedBox(height: 8),

            // طريقة الدفع
            Row(
              children: [
                const Text(
                  'طريقة الدفع: ',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  methodLabel,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // المصرف (لو أونلاين)
            if (isOnline) ...[
              Row(
                children: [
                  const Text(
                    'المصرف: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Flexible(
                    child: Text(
                      bankLabel,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // رسالة توضيح الدفع أونلاين
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'تم الدفع أونلاين بنجاح، وتم خصم قيمة الطلب من حسابكم. الطلب الآن قيد المراجعة من المطعم.',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// امتداد صغير لتعديل الـ Row بدون حذف البنية الأصلية
extension _RowCopy on Row {
  Row copyWith({List<Widget>? children}) {
    return Row(
      key: key,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: textDirection,
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      children: children ?? this.children,
    );
  }
}
