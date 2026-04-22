import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/cart/cart_controller.dart';
import '../../data/models/address.dart';
import 'addresses_controller.dart';
import '../../app_routes.dart';

class AddressesView extends StatelessWidget {
  const AddressesView({super.key});

  static const _primary = Color(0xFFFF5A00);
  static const _primaryDark = Color(0xFFFF2E00);
  static const _primarySoft = Color(0xFFFFF1E9);
  // ignore: unused_field
  static const _pageBg = Color(0xFFF5F5F7);
  static const _card = Colors.white;
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF8B95A7);
  static const _r = Radius.circular(18);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AddressesController());
    final theme = Theme.of(context);
    final pageBg = theme.scaffoldBackgroundColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_primary, _primaryDark],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                18,
                MediaQuery.of(context).padding.top + 14,
                18,
                22,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      c.pickMode ? 'اختر عنواناً' : 'عناويني',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'اختر العنوان المناسب أو أضف عنواناً جديداً بسهولة',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFE3D3),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (c.loading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }
                if (c.items.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                  itemCount: c.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    final a = c.items[i];
                    return _AddressCard(
                      address: a,
                      pickMode: c.pickMode,
                      onTap: () => c.pick(a),
                      onEdit: () => _openInlineEditor(context, c, a),
                      onDelete: () => c.delete(a),
                      onMakeDefault: () => _makeDefaultAndNotify(c, a),
                    );
                  },
                );
              }),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Obx(() {
          final guest = c.isGuest.value;
          if (c.pickMode || guest) return const SizedBox.shrink();

          return SizedBox(
            width: MediaQuery.of(context).size.width - 32,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(_r),
                ),
              ),
              onPressed: () async {
                await _addNewAddressFlow(context, c);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'عنوان جديد',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _makeDefaultAndNotify(AddressesController c, Address a) async {
    try {
      await c.setDefault(a);
      await c.load();
    } catch (_) {}

    if (c.pickMode) {
      try {
        final cart = Get.find<CartController>();
        cart.setSelectedAddress(a);
      } catch (_) {}
      Get.back(result: a);
      return;
    }

    try {
      final cart = Get.find<CartController>();
      cart.setSelectedAddress(a);
    } catch (_) {}
  }

  Future<void> _addNewAddressFlow(
    BuildContext context,
    AddressesController c,
  ) async {
    try {
      final res = await Get.toNamed(AppRoutes.mapPick);
      if (res is! Map) return;

      final double? latV = (res['lat'] is num)
          ? (res['lat'] as num).toDouble()
          : null;
      final double? lngV = (res['lng'] is num)
          ? (res['lng'] as num).toDouble()
          : null;
      final String addrText = (res['address_text'] ?? '').toString();

      if (latV == null || lngV == null) {
        Get.snackbar('تنبيه', 'الرجاء اختيار موقع على الخريطة أولاً');
        return;
      }

      _openInlineEditor(
        context,
        c,
        Address(
          id: 0,
          userId: c.userId,
          label: '',
          lat: latV,
          lng: lngV,
          addressText: addrText,
          isDefault: 0,
          createdAt: '',
        ),
        readOnlyCoords: true,
        isNew: true,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذّر فتح الخريطة: $e');
    }
  }

  void _openInlineEditor(
    BuildContext context,
    AddressesController c,
    Address? existing, {
    bool readOnlyCoords = false,
    bool isNew = false,
  }) {
    final label = TextEditingController(text: existing?.label ?? '');
    final desc = TextEditingController(text: existing?.addressText ?? '');
    final lat = TextEditingController(text: existing?.lat.toString() ?? '');
    final lng = TextEditingController(text: existing?.lng.toString() ?? '');
    bool isDefault = (existing?.isDefault ?? 0) == 1;

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.vertical(top: _r),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(
                    isNew ? 'إضافة عنوان' : 'تعديل العنوان',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final currLat = double.tryParse(lat.text.trim());
                      final currLng = double.tryParse(lng.text.trim());
                      final r = await Get.toNamed(
                        AppRoutes.mapPick,
                        arguments: {
                          if (currLat != null) 'lat': currLat,
                          if (currLng != null) 'lng': currLng,
                        },
                      );
                      if (r is Map) {
                        if (r['lat'] != null) lat.text = r['lat'].toString();
                        if (r['lng'] != null) lng.text = r['lng'].toString();
                        final at = (r['address_text'] ?? '').toString();
                        if (at.isNotEmpty) desc.text = at;
                      }
                    },
                    icon: const Icon(
                      Icons.edit_location_alt_outlined,
                      color: _primary,
                    ),
                    label: const Text(
                      'تعديل الموقع على الخريطة',
                      style: TextStyle(color: _primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primary),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(_r),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LabeledField(
                    label: 'اسم العنوان',
                    controller: label,
                    hint: 'مثال: العمل أو المنزل أو الحي السكني',
                  ),
                  _LabeledField(
                    label: 'وصف العنوان (اختياري)',
                    controller: desc,
                    maxLines: 2,
                  ),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'خط العرض',
                          controller: lat,
                          readOnly: readOnlyCoords,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LabeledField(
                          label: 'خط الطول',
                          controller: lng,
                          readOnly: readOnlyCoords,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  StatefulBuilder(
                    builder: (context, setModalState) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'تعيين كعنوان افتراضي',
                          textAlign: TextAlign.right,
                        ),
                        value: isDefault,
                        onChanged: (v) => setModalState(() => isDefault = v),
                        activeThumbColor: _primary,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => ElevatedButton(
                      onPressed: c.saving.value
                          ? null
                          : () async {
                              if (label.text.trim().isEmpty) {
                                Get.snackbar('تنبيه', 'اسم العنوان مطلوب');
                                return;
                              }
                              c.saving.value = true;
                              try {
                                final a = Address(
                                  id: existing?.id ?? 0,
                                  userId: c.userId,
                                  label: label.text.trim(),
                                  lat: double.tryParse(lat.text.trim()) ?? 0,
                                  lng: double.tryParse(lng.text.trim()) ?? 0,
                                  addressText: desc.text.trim(),
                                  isDefault: isDefault ? 1 : 0,
                                  createdAt: existing?.createdAt ?? '',
                                );
                                await c.repo.addOrUpdate(a);
                                await c.load();
                                Get.back();
                                Get.snackbar(
                                  'تم',
                                  (existing == null || existing.id == 0)
                                      ? 'تمت إضافة العنوان'
                                      : 'تم تحديث العنوان',
                                );

                                if (isDefault) {
                                  try {
                                    final cart = Get.find<CartController>();
                                    cart.setSelectedAddress(a);
                                  } catch (_) {}

                                  if (c.pickMode) {
                                    Get.back(result: a);
                                  }
                                }
                              } catch (e) {
                                Get.snackbar('خطأ', '$e');
                              } finally {
                                c.saving.value = false;
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(_r),
                        ),
                      ),
                      child: c.saving.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'تأكيد',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMakeDefault;
  final bool pickMode;

  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onMakeDefault,
    required this.pickMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? AddressesView._text;
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ??
        AddressesView._muted;
    final softFill = isDark
        ? const Color(0xFF1F2937)
        : AddressesView._primarySoft;
    final neutralFill = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF5F5F7);

    return InkWell(
      onTap: pickMode ? onTap : null,
      borderRadius: const BorderRadius.all(AddressesView._r),
      child: Ink(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.all(AddressesView._r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? .18 : .05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            address.label,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (address.isDefault == 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: softFill,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'افتراضي',
                              style: TextStyle(
                                color: AddressesView._primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          )
                        else
                          InkWell(
                            onTap: onMakeDefault,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: neutralFill,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'تعيين افتراضي',
                                style: TextStyle(
                                  color: mutedColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (address.addressText.trim().isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          address.addressText,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 13.2,
                            height: 1.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        textDirection: TextDirection.rtl,
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(text: 'Lat: ${address.lat}'),
                          _Chip(text: 'Lng: ${address.lng}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: softFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: AddressesView._primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A1616)
                            : const Color(0xFFFFF0EE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softFill = isDark
        ? const Color(0xFF1F2937)
        : AddressesView._primarySoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: softFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: AddressesView._primary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.readOnly = false,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final bool readOnly;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inputFill = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF9FAFB);
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
          filled: true,
          fillColor: inputFill,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(AddressesView._r),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(AddressesView._r),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(AddressesView._r),
            borderSide: BorderSide(color: AddressesView._primary, width: 1.2),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? AddressesView._text;
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ??
        AddressesView._muted;
    final softFill = isDark
        ? const Color(0xFF1F2937)
        : AddressesView._primarySoft;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: softFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 42,
                color: AddressesView._primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'لا توجد عناوين بعد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: textColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف عنوانك الأول ليصبح الوصول والطلب أسهل وأسرع.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
