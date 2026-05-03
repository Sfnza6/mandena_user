import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/cart/cart_controller.dart';
import 'checkout_controller.dart';

class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key});

  static const _brand = Color(0xFFFF5A00);
  static const _brandDeep = Color(0xFFE14D00);
  static const _brandSoft = Color(0xFFFFEEE4);
  static const _brandStroke = Color(0xFFFFD2BC);
  static const _textDark = Color(0xFF1F2937);
  static const _textMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CheckoutController());
    final cart = Get.find<CartController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textDark = theme.textTheme.bodyLarge?.color ?? _textDark;
    final textMuted =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ?? _textMuted;
    final brandSoft = isDark ? const Color(0xFF1F2937) : _brandSoft;
    final brandStroke = isDark ? Colors.white10 : _brandStroke;

    final RxString paymentLabel = ''.obs;
    paymentLabel.value = _paymentName(c.payment.value);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: textDark,
          centerTitle: true,
          title: Text(
            'إتمام الطلب',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
        body: Form(
          key: c.formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
            children: [
              const _HeroBanner(),
              const SizedBox(height: 18),
              _StepStrip(
                cardColor: cardColor,
                brandStroke: brandStroke,
                textDark: textDark,
              ),
              const SizedBox(height: 18),

              _SectionTitle(
                'عنوان التوصيل',
                icon: Icons.place_outlined,
                textDark: textDark,
                brandSoft: brandSoft,
              ),
              Obx(() {
                String defaultName = '';
                try {
                  final dynamic maybeRx = (cart as dynamic).selectedAddressName;
                  if (maybeRx != null) {
                    defaultName = (maybeRx.value as String?)?.trim() ?? '';
                  }
                } catch (_) {
                  defaultName = '';
                }

                final hasSelected =
                    defaultName.isNotEmpty ||
                    cart.selectedAddress.value != null;

                final String label = defaultName.isNotEmpty
                    ? defaultName
                    : (cart.selectedAddress.value?.label ??
                          'اختر العنوان من عناويني');

                final String subtitle = hasSelected
                    ? 'العنوان الحالي المحدد للطلب، يمكنك تغييره في أي وقت.'
                    : 'اختر عنوان محفوظ أو أضف عنوانًا جديدًا للمتابعة.';

                return _ActionCard(
                  icon: Icons.location_on_rounded,
                  title: label,
                  subtitle: subtitle,
                  trailingText: hasSelected ? 'تغيير' : 'اختيار',
                  onTap: c.pickAddress,
                  cardColor: cardColor,
                  textDark: textDark,
                  textMuted: textMuted,
                  brandSoft: brandSoft,
                  brandStroke: brandStroke,
                );
              }),

              _NoteInput(
                label: 'تفاصيل إضافية',
                controller: c.addressCtrl,
                validator: (v) => c.statusOrder.value == 'delivery'
                    ? c.req(v, 'العنوان')
                    : null,
                hint: 'المدينة / الشارع / أقرب معلم...',
                maxLines: 2,
                cardColor: cardColor,
                textMuted: textMuted,
                brandStroke: brandStroke,
              ),

              const SizedBox(height: 10),
              _SectionTitle(
                'طريقة الاستلام',
                icon: Icons.delivery_dining,
                textDark: textDark,
                brandSoft: brandSoft,
              ),
              Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      SizedBox(
                        width: 128,
                        child: _ModeCard(
                          title: 'توصيل',
                          subtitle: 'يوصل لعند بابك',
                          icon: Icons.delivery_dining_rounded,
                          selected: c.statusOrder.value == 'delivery',
                          onTap: () => c.statusOrder.value = 'delivery',
                          cardColor: cardColor,
                          textDark: textDark,
                          textMuted: textMuted,
                          brandSoft: brandSoft,
                          brandStroke: brandStroke,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 128,
                        child: _ModeCard(
                          title: 'استلام خارجي',
                          subtitle: 'تستلمه من خارج الفرع',
                          icon: Icons.storefront_rounded,
                          selected: c.statusOrder.value == 'pickup',
                          onTap: () => c.statusOrder.value = 'pickup',
                          cardColor: cardColor,
                          textDark: textDark,
                          textMuted: textMuted,
                          brandSoft: brandSoft,
                          brandStroke: brandStroke,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 128,
                        child: _ModeCard(
                          title: 'استلام داخلي',
                          subtitle: 'داخل صالة الأكل',
                          icon: Icons.restaurant_rounded,
                          selected: c.statusOrder.value == 'internal_pickup',
                          onTap: () => c.statusOrder.value = 'internal_pickup',
                          cardColor: cardColor,
                          textDark: textDark,
                          textMuted: textMuted,
                          brandSoft: brandSoft,
                          brandStroke: brandStroke,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              _SectionTitle(
                'الدفع',
                icon: Icons.account_balance_wallet_outlined,
                textDark: textDark,
                brandSoft: brandSoft,
              ),
              Obx(() {
                final title = paymentLabel.value.isEmpty
                    ? _paymentName(c.payment.value)
                    : paymentLabel.value;
                return _ActionCard(
                  icon: Icons.wallet_rounded,
                  title: title,
                  subtitle: 'اضغط لتغيير طريقة الدفع المناسبة لك.',
                  trailingText: 'تعديل',
                  onTap: () => _showPaymentSheet(
                    context: context,
                    c: c,
                    setLabel: (txt) => paymentLabel.value = txt,
                    bg: bg,
                    cardColor: cardColor,
                    textDark: textDark,
                    textMuted: textMuted,
                    brandSoft: brandSoft,
                    brandStroke: brandStroke,
                  ),
                  cardColor: cardColor,
                  textDark: textDark,
                  textMuted: textMuted,
                  brandSoft: brandSoft,
                  brandStroke: brandStroke,
                );
              }),

              Visibility(
                visible: false,
                child: Obx(
                  () => Row(
                    children: [
                      Radio<int>(
                        value: 0,
                        groupValue: c.payment.value,
                        onChanged: (v) => c.payment.value = v ?? 0,
                        activeColor: _brand,
                      ),
                      Text(
                        'نقدًا عند التسليم',
                        style: TextStyle(color: textDark),
                      ),
                      const SizedBox(width: 18),
                      Radio<int>(
                        value: 1,
                        groupValue: c.payment.value,
                        onChanged: (v) => c.payment.value = v ?? 0,
                        activeColor: _brand,
                      ),
                      Text('بطاقة/أخرى', style: TextStyle(color: textDark)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              _SectionTitle(
                'ملخص المبلغ',
                icon: Icons.receipt_long_outlined,
                textDark: textDark,
                brandSoft: brandSoft,
              ),
              _BillSummary(
                cart: cart,
                cardColor: cardColor,
                textDark: textDark,
                textMuted: textMuted,
                brandSoft: brandSoft,
                brandStroke: brandStroke,
                isDark: isDark,
              ),

              const SizedBox(height: 18),
              Obx(
                () => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _brand.withOpacity(.18),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: c.isPlacing.value ? null : c.placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        textDirection: TextDirection.rtl,
                        children: [
                          if (c.isPlacing.value)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Text(
                            c.isPlacing.value
                                ? 'جارٍ إرسال الطلب...'
                                : 'تأكيد وإرسال الطلب',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _paymentName(int v) =>
      (v == 0) ? 'نقدًا عند التسليم' : 'بطاقة/أخرى';

  static Future<void> _showPaymentSheet({
    required BuildContext context,
    required CheckoutController c,
    required void Function(String label) setLabel,
    required Color bg,
    required Color cardColor,
    required Color textDark,
    required Color textMuted,
    required Color brandSoft,
    required Color brandStroke,
  }) async {
    final options = <_PayOpt>[
      _PayOpt(
        key: 'cash',
        label: 'نقدًا',
        groupValue: 0,
        asset: 'assets/pay/cash.png',
        fallback: Icons.attach_money_rounded,
      ),
      _PayOpt(
        key: 'masrafy',
        label: 'مصرفي باي (الجمهورية)',
        groupValue: 1,
        asset: 'assets/pay/masrafy_pay.png',
        fallback: Icons.account_balance_rounded,
      ),
      _PayOpt(
        key: 'yesser',
        label: 'يسر أونلاين (التجاري)',
        groupValue: 1,
        asset: 'assets/pay/yesser.png',
        fallback: Icons.cloud_done_rounded,
      ),
      _PayOpt(
        key: 'sahari',
        label: 'صحاري باي (الصحاري)',
        groupValue: 1,
        asset: 'assets/pay/installments.png',
        fallback: Icons.account_balance_rounded,
      ),
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_brand, _brandDeep],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0x33FFFFFF),
                        child: Icon(Icons.wallet_rounded, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'اختر طريقة الدفع',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'اختر الأنسب لك قبل تأكيد الطلب.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: Obx(() {
                    final selectedKey = c.gatewayKey.value;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (_, i) => _PaymentOptionTile(
                        opt: options[i],
                        selected: selectedKey == options[i].key,
                        onTap: () {
                          final opt = options[i];
                          c.setGateway(opt.key);
                          c.payment.value = opt.groupValue;
                          setLabel(opt.label);
                        },
                        cardColor: cardColor,
                        textDark: textDark,
                        textMuted: textMuted,
                        brandSoft: brandSoft,
                        brandStroke: brandStroke,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'تم',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CheckoutView._brand, CheckoutView._brandDeep],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: CheckoutView._brand.withOpacity(.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'خطوة أخيرة وطلبك في الطريق',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'راجع العنوان، اختر طريقة الاستلام والدفع، ثم أكد طلبك بسهولة.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepStrip extends StatelessWidget {
  const _StepStrip({
    required this.cardColor,
    required this.brandStroke,
    required this.textDark,
  });

  final Color cardColor;
  final Color brandStroke;
  final Color textDark;

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('العنوان', Icons.place_outlined),
      ('الاستلام', Icons.delivery_dining),
      ('الدفع', Icons.wallet_outlined),
    ];

    return Row(
      children: items
          .map(
            (e) => Expanded(
              child: Container(
                margin: EdgeInsets.only(left: e == items.last ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: brandStroke),
                ),
                child: Column(
                  children: [
                    Icon(e.$2, color: CheckoutView._brand, size: 20),
                    const SizedBox(height: 6),
                    Text(
                      e.$1,
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(
    this.text, {
    required this.icon,
    required this.textDark,
    required this.brandSoft,
  });

  final String text;
  final IconData icon;
  final Color textDark;
  final Color brandSoft;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: CheckoutView._brand, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.onTap,
    required this.cardColor,
    required this.textDark,
    required this.textMuted,
    required this.brandSoft,
    required this.brandStroke,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailingText;
  final VoidCallback onTap;
  final Color cardColor;
  final Color textDark;
  final Color textMuted;
  final Color brandSoft;
  final Color brandStroke;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: brandStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: brandSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: CheckoutView._brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: textMuted,
                          height: 1.35,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: brandSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: const [
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: CheckoutView._brand,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'تعديل',
                        style: TextStyle(
                          color: CheckoutView._brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
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

class _NoteInput extends StatelessWidget {
  const _NoteInput({
    required this.label,
    required this.cardColor,
    required this.textMuted,
    required this.brandStroke,
    this.controller,
    this.validator,
    this.hint,
    this.maxLines = 1,
    // ignore: unused_element_parameter
    this.keyboardType,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
  final Color cardColor;
  final Color textMuted;
  final Color brandStroke;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: cardColor,
          labelStyle: TextStyle(color: textMuted, fontWeight: FontWeight.w700),
          hintStyle: TextStyle(color: textMuted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: brandStroke),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(
              color: CheckoutView._brand,
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cardColor,
    required this.textDark,
    required this.textMuted,
    required this.brandSoft,
    required this.brandStroke,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color cardColor;
  final Color textDark;
  final Color textMuted;
  final Color brandSoft;
  final Color brandStroke;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? brandSoft : cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? CheckoutView._brand : brandStroke,
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(selected ? .05 : .025),
              blurRadius: 14,
              offset: const Offset(0, 6),
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? CheckoutView._brand : brandSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : CheckoutView._brand,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: CheckoutView._brand,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.right,
              style: TextStyle(color: textMuted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillSummary extends StatelessWidget {
  const _BillSummary({
    required this.cart,
    required this.cardColor,
    required this.textDark,
    required this.textMuted,
    required this.brandSoft,
    required this.brandStroke,
    required this.isDark,
  });

  final CartController cart;
  final Color cardColor;
  final Color textDark;
  final Color textMuted;
  final Color brandSoft;
  final Color brandStroke;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: brandStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? .18 : .03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(
        () => Column(
          children: [
            _priceRow('سعر الأصناف', cart.subtotal.value),
            const SizedBox(height: 10),
            _priceRow('التوصيل', cart.delivery.value),
            const SizedBox(height: 10),
            _priceRow('الخدمات', cart.services.value),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              height: 1,
              color: brandStroke,
            ),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: brandSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'الإجمالي',
                    style: TextStyle(
                      color: CheckoutView._brand,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'د.ل ${cart.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, num value) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          label,
          style: TextStyle(color: textMuted, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(
          'د.ل ${value.toStringAsFixed(0)}',
          style: TextStyle(color: textDark, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _PayOpt {
  final String key;
  final String label;
  final int groupValue;
  final String asset;
  final IconData fallback;

  _PayOpt({
    required this.key,
    required this.label,
    required this.groupValue,
    required this.asset,
    required this.fallback,
  });
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.opt,
    required this.selected,
    required this.onTap,
    required this.cardColor,
    required this.textDark,
    required this.textMuted,
    required this.brandSoft,
    required this.brandStroke,
  });

  final _PayOpt opt;
  final bool selected;
  final VoidCallback onTap;
  final Color cardColor;
  final Color textDark;
  final Color textMuted;
  final Color brandSoft;
  final Color brandStroke;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? CheckoutView._brand : brandStroke,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? CheckoutView._brand : Colors.transparent,
                  border: Border.all(
                    color: selected ? CheckoutView._brand : brandStroke,
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      opt.label,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt.groupValue == 0
                          ? 'دفع مباشر عند الاستلام'
                          : 'دفع إلكتروني آمن',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: selected ? brandSoft : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Image.asset(
                      opt.asset,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(opt.fallback, color: CheckoutView._brand),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
