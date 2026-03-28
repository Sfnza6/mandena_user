// lib/modules/checkout/checkout_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/cart/cart_controller.dart';
import 'checkout_controller.dart';

class CheckoutView extends StatelessWidget {
  const CheckoutView({super.key});

  // لون البراند
  static const _brown = Color(0xFF6F3F17);

  // ignore: unused_field
  static const _light = Color(0xFFF6F5F3);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CheckoutController());
    final cart = Get.find<CartController>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg =
        theme.scaffoldBackgroundColor; // الخلفية الأساسية من الثيم
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor.withOpacity(
      isDark ? 0.4 : 0.7,
    ); // حدود ديناميكية
    final subtitleColor = (theme.textTheme.bodySmall?.color ?? Colors.black54)
        .withOpacity(isDark ? 0.7 : 0.6);

    // تسمية واجهة لطريقة الدفع المختارة (عرض فقط)
    final RxString paymentLabel = ''.obs;
    paymentLabel.value = _paymentName(c.payment.value);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: const Text(
            'إتمام الطلب',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, color: _brown),
          ),
          centerTitle: true,
          backgroundColor:
              theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
          elevation: 0.4,
          foregroundColor: _brown,
          iconTheme: const IconThemeData(color: _brown),
        ),
        body: Form(
          key: c.formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              const _Section('معلومات التوصيل'),

              // 🔥 هنا نعرض العنوان الافتراضي المختار (نفس اللي في السلة)
              Obx(() {
                String defaultName = '';
                try {
                  // نحاول قراءة selectedAddressName لو موجودة
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
                    ? 'هذا هو عنوان التوصيل الحالي، يمكنك تغييره بالضغط هنا'
                    : 'اختر العنوان من عناوينك المحفوظة أو أدخل عنوان جديد';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(.35)
                            : Colors.black.withOpacity(.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: _brown,
                    ),
                    title: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                    trailing: const Icon(Icons.chevron_left, color: _brown),
                    onTap: c.pickAddress,
                  ),
                );
              }),

              _Input(
                label: 'العنوان',
                controller: c.addressCtrl,
                validator: (v) => c.statusOrder.value == 'delivery'
                    ? c.req(v, 'العنوان')
                    : null,
                hint: 'المدينة / الشارع / أقرب معلم...',
                maxLines: 2,
              ),
              const SizedBox(height: 10),

              const _Section('طريقة الاستلام'),
              Obx(
                () => Row(
                  children: [
                    ChoiceChip(
                      label: const Text('توصيل'),
                      selected: c.statusOrder.value == 'delivery',
                      onSelected: (_) => c.statusOrder.value = 'delivery',
                      selectedColor: _brown.withOpacity(.12),
                      labelStyle: TextStyle(
                        color: c.statusOrder.value == 'delivery'
                            ? _brown
                            : (theme.textTheme.bodyMedium?.color ??
                                  Colors.black87),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('استلام'),
                      selected: c.statusOrder.value == 'pickup',
                      onSelected: (_) => c.statusOrder.value = 'pickup',
                      selectedColor: _brown.withOpacity(.12),
                      labelStyle: TextStyle(
                        color: c.statusOrder.value == 'pickup'
                            ? _brown
                            : (theme.textTheme.bodyMedium?.color ??
                                  Colors.black87),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ======================= طريقة الدفع =======================
              const _Section('طريقة الدفع'),
              Obx(() {
                final title = paymentLabel.value.isEmpty
                    ? _paymentName(c.payment.value)
                    : paymentLabel.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(.35)
                            : Colors.black.withOpacity(.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: _brown,
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'حدد طريقة الدفع',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                    trailing: const Icon(
                      Icons.keyboard_arrow_down,
                      color: _brown,
                    ),
                    onTap: () => _showPaymentSheet(
                      context: context,
                      c: c,
                      setLabel: (txt) => paymentLabel.value = txt,
                    ),
                    onLongPress: () => _showPaymentSheet(
                      context: context,
                      c: c,
                      setLabel: (txt) => paymentLabel.value = txt,
                    ),
                  ),
                );
              }),

              // الراديو القديم (مخفي – منطق فقط)
              Visibility(
                visible: false,
                child: Obx(
                  () => Row(
                    children: [
                      Radio<int>(
                        value: 0,
                        groupValue: c.payment.value,
                        onChanged: (v) => c.payment.value = v ?? 0,
                        activeColor: _brown,
                      ),
                      const Text('نقدًا عند التسليم'),
                      const SizedBox(width: 18),
                      Radio<int>(
                        value: 1,
                        groupValue: c.payment.value,
                        onChanged: (v) => c.payment.value = v ?? 0,
                        activeColor: _brown,
                      ),
                      const Text('بطاقة/أخرى'),
                    ],
                  ),
                ),
              ),

              // ==================== نهاية واجهة الدفع ====================
              const SizedBox(height: 20),
              const _Section('مراجعة المبلغ'),
              _Card(
                child: Obx(
                  () => Column(
                    children: [
                      _row('سعر الأصناف', cart.subtotal.value, theme),
                      _row('التوصيل', cart.delivery.value, theme),
                      _row('الخدمات', cart.services.value, theme),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'الإجمالي',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            'د.ل ${cart.total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: _brown,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Obx(
                () => SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: c.isPlacing.value ? null : c.placeOrder,
                    icon: c.isPlacing.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                    label: Text(
                      c.isPlacing.value ? 'جارٍ الإرسال...' : 'تأكيد الطلب',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

  static Widget _row(String label, num v, ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
        Text(
          'د.ل ${v.toStringAsFixed(0)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _brown),
        ),
      ],
    ),
  );

  static String _paymentName(int v) =>
      (v == 0) ? 'نقدًا عند التسليم' : 'بطاقة/أخرى';

  // =============== BottomSheet ===============
  static Future<void> _showPaymentSheet({
    required BuildContext context,
    required CheckoutController c,
    required void Function(String label) setLabel,
  }) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.4 : 0.7);
    final surfaceVariant = theme.colorScheme.surfaceContainerHighest;

    // تعريف الخيارات
    final options = <_PayOpt>[
      _PayOpt(
        key: 'cash',
        label: 'نقدًا',
        groupValue: 0,
        asset: 'assets/pay/cash.png',
        fallback: Icons.attach_money_rounded,
      ),

      //**
      //
      //
      //
      //
      //
      //
      //
      // */

      //_PayOpt(
      //key: 'sdad',
      //label: 'سداد',
      //groupValue: 1,
      //asset: 'assets/pay/sdad.png',
      //fallback: Icons.bolt_rounded,
      //),
      //
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
      //_PayOpt(
      //key: 'bank',
      //label: 'البطاقة المصرفية (أخرى)',
      //groupValue: 1,
      //asset: 'assets/pay/bank_card.png',
      //fallback: Icons.credit_card_rounded,
      //),
      //_PayOpt(
      //key: 'edf3ali',
      //label: 'ادفعلي',
      //groupValue: 1,
      //asset: 'assets/pay/edf3ali.png',
      //fallback: Icons.payments_rounded,
      //),
      //_PayOpt(
      //key: 'mobicash',
      //label: 'موبي كاش',
      //groupValue: 1,
      //asset: 'assets/pay/mobicash.png',
      //fallback: Icons.qr_code_scanner_rounded,
      //),
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          theme.bottomSheetTheme.backgroundColor ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'حدد طريقة الدفع',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Obx(() {
                  final selectedKey = c.gatewayKey.value;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemBuilder: (_, i) => _PaymentTile(
                      opt: options[i],
                      selectedKey: selectedKey,
                      onPick: (opt) {
                        // ضبط البوابة المختارة
                        c.setGateway(opt.key);
                        // ضبط طريقة الدفع 0/1 للحفاظ على منطقك الأصلي
                        c.payment.value = opt.groupValue;
                        // تحديث التسمية الظاهرة
                        setLabel(opt.label);
                      },
                      cardColor: cardColor,
                      borderColor: borderColor,
                      selectedBg: surfaceVariant,
                    ),
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'تأكيد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ---------------- Widgets صغيرة ---------------- */

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: CheckoutView._brown,
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    this.controller,
    this.validator,
    this.hint,
    // ignore: unused_element_parameter
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor =
        theme.inputDecorationTheme.fillColor ??
        (isDark ? theme.colorScheme.surface : Colors.white);
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.6 : 0.8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: fillColor,
          labelStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: CheckoutView._brown),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.4 : 0.7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(.35)
                : Colors.black.withOpacity(.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/* ---------------- مكوّنات الدفع ---------------- */

class _PayOpt {
  final String key;
  final String label;
  final int groupValue; // 0: نقد | 1: غير ذلك (يحافظ على منطقك)
  final String asset;
  final IconData fallback;
  final Widget? trailing;
  _PayOpt({
    required this.key,
    required this.label,
    required this.groupValue,
    required this.asset,
    required this.fallback,
    // ignore: unused_element_parameter
    this.trailing,
  });
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.opt,
    required this.selectedKey,
    required this.onPick,
    required this.cardColor,
    required this.borderColor,
    required this.selectedBg,
  });

  final _PayOpt opt;
  final String selectedKey;
  final void Function(_PayOpt) onPick;
  final Color cardColor;
  final Color borderColor;
  final Color selectedBg;

  @override
  Widget build(BuildContext context) {
    final selected = selectedKey == opt.key;
    return InkWell(
      onTap: () => onPick(opt),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? selectedBg : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            _Logo(asset: opt.asset, fallback: opt.fallback),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                opt.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (opt.trailing != null) opt.trailing!,
            Radio<String>(
              value: opt.key,
              groupValue: selectedKey,
              onChanged: (_) => onPick(opt),
              activeColor: CheckoutView._brown,
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.asset, required this.fallback});
  final String asset;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(fallback, color: CheckoutView._brown),
      ),
    );
  }
}

// ignore: unused_element
class _WalletTrailing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.dividerColor.withOpacity(isDark ? 0.6 : 0.8);
    final bg = theme.cardColor;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'شحن  +',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.red),
          ),
        ),
        const SizedBox(width: 10),
        const Text('0', maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(width: 6),
      ],
    );
  }
}
