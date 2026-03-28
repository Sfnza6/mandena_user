import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:mandena/modules/cart/cart_controller.dart';
import 'package:mandena/modules/checkout/checkout_view.dart';

const _kPrimary = Color(0xFFFF5A00);
const _kPrimaryDark = Color(0xFFFF2E00);
const _kPageBg = Color(0xFFF5F5F7);
const _kCard = Colors.white;
const _kText = Color(0xFF111827);
const _kMuted = Color(0xFF8B95A7);
// ignore: unused_element
const _kBorder = Color(0xFFE9EDF3);

class CartView extends StatelessWidget {
  const CartView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CartController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kPageBg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kPrimary, _kPrimaryDark],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 16,
                16,
                18,
              ),
              child: Obx(
                () => Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const Text(
                      'سلة التسوق',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${c.cart.length} صنف',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // IconButton(
                    //   onPressed: () => Get.back(),
                    //   icon: const Icon(
                    //     Icons.arrow_back_ios_new_rounded,
                    //     color: Colors.white,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (c.isBusy.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  );
                }
                if (c.cart.isEmpty) {
                  return const _EmptyCartView();
                }
                return Column(
                  children: [
                    _AddressCard(c: c),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        itemCount: c.cart.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final e = c.cart[i];
                          final cartId =
                              ((e['cart_item_id'] ?? e['cart_id'] ?? 0) as num?)
                                  ?.toInt() ??
                              0;
                          final itemId =
                              ((e['item_id'] ?? 0) as num?)?.toInt() ?? 0;
                          final name = (e['name'] ?? '').toString();
                          final image = (e['image_url'] ?? '').toString();
                          final qty =
                              ((e['quantity'] ?? 1) as num?)?.toInt() ?? 1;
                          final price = (e['price'] is num)
                              ? (e['price'] as num).toDouble()
                              : double.tryParse('${e['price'] ?? 0}') ?? 0;
                          return _CartItemCard(
                            title: name,
                            imageUrl: image,
                            qty: qty,
                            price: price,
                            onRemove: () => cartId > 0
                                ? c.removeByCartId(cartId)
                                : c.remove(itemId),
                            onInc: () => cartId > 0
                                ? c.incByCartId(cartId)
                                : c.inc(itemId),
                            onDec: () => cartId > 0
                                ? c.decByCartId(cartId)
                                : c.dec(itemId),
                          );
                        },
                      ),
                    ),
                    _SummaryBlock(c: c),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.c});
  final CartController c;

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.fromLTRB(16, 14, 16, 4));
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.title,
    required this.imageUrl,
    required this.qty,
    required this.price,
    required this.onRemove,
    required this.onInc,
    required this.onDec,
  });

  final String title;
  final String imageUrl;
  final int qty;
  final double price;
  final VoidCallback onRemove;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${price.toStringAsFixed(0)} د.ل',
                  style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          _QtyBtn(icon: Icons.add, onTap: onInc),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '$qty',
                              style: const TextStyle(
                                color: _kText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          _QtyBtn(icon: Icons.remove, onTap: onDec),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(price * qty).toStringAsFixed(0)} د.ل',
                      style: const TextStyle(
                        color: _kText,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 92,
              height: 92,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF2EEE8),
                  alignment: Alignment.center,
                  child: const Icon(Icons.fastfood_rounded, color: _kPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 36,
        height: 34,
        child: Icon(icon, color: _kText, size: 18),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.c});
  final CartController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: _kPageBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'ملخص الطلب',
                  style: TextStyle(
                    color: _kText,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: 'المجموع الفرعي',
                  value: '${c.subtotal.value.toStringAsFixed(0)} د.ل',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'رسوم التوصيل',
                  value: '${c.delivery.value.toStringAsFixed(0)} د.ل',
                ),
                const Divider(height: 24),
                _SummaryRow(
                  label: 'الإجمالي',
                  value: '${c.total.toStringAsFixed(2)} د.ل',
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Get.to(() => const CheckoutView()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'إتمام الطلب',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: highlight ? _kPrimary : _kText,
      fontWeight: highlight ? FontWeight.w900 : FontWeight.w700,
      fontSize: highlight ? 18 : 14,
    );
    return Row(
      children: [
        Text(value, style: style),
        const Spacer(),
        Text(label, style: style.copyWith(color: _kText, fontSize: 15)),
      ],
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2EA),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'السلة فارغة حالياً',
              style: TextStyle(
                color: _kText,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ بإضافة أصنافك المفضلة من القائمة الرئيسية',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
