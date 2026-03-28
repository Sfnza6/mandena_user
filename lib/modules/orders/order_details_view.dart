import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/orders/order_details_controller.dart';

class OrderDetailsView extends GetView<OrderDetailsController> {
  const OrderDetailsView({super.key});

  static const Color kPrimary = Color(0xFFFF5A00);
  static const Color kPrimaryDark = Color(0xFFFF2E00);
  static const Color kBg = Color(0xFFF5F5F7);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF111827);
  static const Color kMuted = Color(0xFF8B95A7);
  static const Color kSoftOrange = Color(0xFFFFF1E9);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OrderDetailsController>()) {
      Get.put(OrderDetailsController());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          title: const Text(
            'تفاصيل الطلب',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: kPrimary,
            ),
          ),
          iconTheme: const IconThemeData(color: kPrimary),
        ),
        body: Obx(() {
          if (controller.loading.value) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimary),
            );
          }

          final h = controller.header.value;
          if (h == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: kSoftOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 42,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'لا توجد بيانات لهذا الطلب',
                    style: TextStyle(color: kMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: controller.fetch,
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(color: kPrimary),
                    ),
                  ),
                ],
              ),
            );
          }

          final d = controller.driver.value;

          return RefreshIndicator(
            color: kPrimary,
            onRefresh: controller.fetch,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _HeaderCard(
                  orderId: h.id,
                  status: h.status,
                  deliveryType: controller.deliveryTypeArabic(h.statusOrder),
                  address: h.address,
                  createdAt: h.createdAt,
                ),
                const SizedBox(height: 14),
                _PaymentCard(h: h),
                const SizedBox(height: 18),
                const Text(
                  'الأصناف',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 10),
                ...controller.items.map((it) => _OrderItemCard(item: it)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _PriceRow(
                        title: 'رسوم التوصيل',
                        value: h.deliveryFee.toStringAsFixed(2),
                        muted: true,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      _PriceRow(
                        title: 'الإجمالي النهائي',
                        value: controller.computedGrandTotal.toStringAsFixed(2),
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
                if (d != null) ...[
                  const SizedBox(height: 16),
                  _DriverCard(driver: d),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.orderId,
    required this.status,
    required this.deliveryType,
    required this.address,
    required this.createdAt,
  });

  final int orderId;
  final String status;
  final String deliveryType;
  final String address;
  final String createdAt;

  Color _statusColor(String s) {
    final v = s.toLowerCase().trim();
    if (v.contains('pending')) return const Color(0xFFFF9800);
    if (v.contains('processing')) return const Color(0xFF2196F3);
    if (v.contains('delivered')) return const Color(0xFF2E7D32);
    if (v.contains('rejected') || v.contains('cancel'))
      return const Color(0xFFD32F2F);
    return OrderDetailsView.kPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [OrderDetailsView.kPrimary, OrderDetailsView.kPrimaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: OrderDetailsView.kPrimary.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '#$orderId',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 10),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoLine(
            icon: Icons.delivery_dining_rounded,
            text: 'نوع التوصيل: $deliveryType',
            white: true,
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.location_on_outlined,
              text: 'العنوان: $address',
              white: true,
            ),
          ],
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.schedule_rounded,
            text: 'التاريخ: $createdAt',
            white: true,
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.h});

  final OrderHeaderModel h;

  @override
  Widget build(BuildContext context) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrderDetailsView.kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'معلومات الدفع',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: OrderDetailsView.kText,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(title: 'طريقة الدفع', value: methodLabel),
          if (isOnline) ...[
            const SizedBox(height: 8),
            _InfoRow(title: 'المصرف', value: bankLabel),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'تم الدفع أونلاين بنجاح، وتم خصم قيمة الطلب من حسابكم. الطلب الآن قيد المراجعة من المطعم.',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 13.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item});

  final OrderItemModel item;

  @override
  Widget build(BuildContext context) {
    final total =
        (item.lineTotalWithExtras > 0
                ? item.lineTotalWithExtras
                : item.lineTotal)
            .toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OrderDetailsView.kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE6D7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: OrderDetailsView.kText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الكمية: ${item.quantity} × ${item.price.toStringAsFixed(2)} د.ل',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: OrderDetailsView.kMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: OrderDetailsView.kSoftOrange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$total د.ل',
                  style: const TextStyle(
                    color: OrderDetailsView.kPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          if (item.extras.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _MiniSectionTitle('الإضافات'),
            const SizedBox(height: 6),
            ...item.extras.map(
              (ex) => _BulletLine(
                text:
                    '${ex.name} (${ex.quantity} × ${ex.price.toStringAsFixed(2)} د.ل)',
                trailing: '${ex.lineTotal.toStringAsFixed(2)} د.ل',
              ),
            ),
          ],
          if (item.componentsAdd.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _MiniSectionTitle('المكوّنات المُضافة'),
            const SizedBox(height: 6),
            ...item.componentsAdd.map(
              (c) => _BulletLine(
                text:
                    '${c.name} (${c.quantity} × ${c.price.toStringAsFixed(2)} د.ل)',
                trailing: '${(c.price * c.quantity).toStringAsFixed(2)} د.ل',
              ),
            ),
          ],
          if (item.componentsRem.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _MiniSectionTitle('المكوّنات المحذوفة'),
            const SizedBox(height: 6),
            ...item.componentsRem.map((c) {
              final label = (c.name.trim().isNotEmpty)
                  ? c.name
                  : (c.id > 0 ? '#${c.id}' : '— محذوف —');
              return _BulletLine(text: label);
            }),
          ],
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final Map driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OrderDetailsView.kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: OrderDetailsView.kSoftOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: OrderDetailsView.kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'السائق',
                  style: TextStyle(
                    color: OrderDetailsView.kMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (driver['name'] ?? '-').toString(),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: OrderDetailsView.kText,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            (driver['phone'] ?? '').toString(),
            style: const TextStyle(
              color: OrderDetailsView.kPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text, this.white = false});

  final IconData icon;
  final String text;
  final bool white;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: white ? Colors.white : OrderDetailsView.kPrimary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: white ? Colors.white : OrderDetailsView.kText,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: OrderDetailsView.kText,
            fontSize: 13.5,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: OrderDetailsView.kMuted,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniSectionTitle extends StatelessWidget {
  const _MiniSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: OrderDetailsView.kPrimary,
        fontWeight: FontWeight.w800,
        fontSize: 13.5,
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '• $text',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: OrderDetailsView.kText,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            Text(
              trailing!,
              style: const TextStyle(
                color: OrderDetailsView.kMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.title,
    required this.value,
    this.muted = false,
    this.isTotal = false,
  });

  final String title;
  final String value;
  final bool muted;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isTotal
                ? OrderDetailsView.kText
                : (muted ? OrderDetailsView.kMuted : OrderDetailsView.kText),
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        const Spacer(),
        Text(
          '$value د.ل',
          style: TextStyle(
            color: isTotal ? OrderDetailsView.kPrimary : OrderDetailsView.kText,
            fontWeight: FontWeight.w900,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
