import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/cart/cart_controller.dart';
import '../../data/models/address.dart';
import 'addresses_controller.dart';
import '../../app_routes.dart';

// ✅ لتحديث السلة مباشرة لما نغيّر الافتراضي

class AddressesView extends StatelessWidget {
  const AddressesView({super.key});

  static const _brown = Color(0xFF6F3F17);

  static const _muted = Color(0xFF808089);
  static const _r = Radius.circular(16);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AddressesController());
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor ?? bgColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            c.pickMode ? 'اختر عنواناً' : 'عناويني',
            style: TextStyle(
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
          iconTheme: IconThemeData(
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),

        // يعتمد على Rx: loading/items
        body: Obx(() {
          if (c.loading.value) {
            return const Center(
              child: CircularProgressIndicator(color: _brown),
            );
          }
          if (c.items.isEmpty) return const _EmptyState();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
            itemCount: c.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final a = c.items[i];
              return _AddressCard(
                address: a,
                pickMode: c.pickMode, // قراءة عادية
                onTap: () => c.pick(a),
                onEdit: () => _openInlineEditor(context, c, a),
                onDelete: () => c.delete(a),
                onMakeDefault: () => _makeDefaultAndNotify(c, a),
              );
            },
          );
        }),

        // ✅ زر إضافة عنوان:
        // يختفي إذا كانت الشاشة في وضع pickMode أو الحساب تجريبي
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Obx(() {
          // ✅✅ التعديل المهم:
          // نجبر Obx يقرأ Rx دائمًا حتى لو pickMode=true (لأن OR تعمل short-circuit)
          final guest = c.isGuest.value;

          if (c.pickMode || guest) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            width: MediaQuery.of(context).size.width - 32,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(_r),
                ),
              ),
              onPressed: () async {
                debugPrint('[Addresses] زر "عنوان جديد" تم النقر');
                await _addNewAddressFlow(context, c);
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'عنوان جديد',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          );
        }),
      ),
    );
  }

  /* -------------------- دالة جديدة: تجعل الافتراضي + تحدّث السلة/الاختيار -------------------- */

  Future<void> _makeDefaultAndNotify(AddressesController c, Address a) async {
    try {
      await c.setDefault(a);
      await c.load();
    } catch (e) {
      debugPrint('[Addresses] setDefault error: $e');
    }

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

  /* -------------------- التدفقات -------------------- */

  Future<void> _addNewAddressFlow(
    BuildContext context,
    AddressesController c,
  ) async {
    try {
      debugPrint('[Addresses] الذهاب إلى الخريطة: route=${AppRoutes.mapPick}');
      final res = await Get.toNamed(AppRoutes.mapPick);
      debugPrint('[Addresses] نتيجة الرجوع من الخريطة: $res');

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
    } catch (e, st) {
      debugPrint('[Addresses] خطأ أثناء فتح الخريطة: $e');
      debugPrint(st.toString());
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

    final theme = Theme.of(context);

    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: _r),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
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
                      debugPrint('[Addresses] تعديل موقع على الخريطة رجع: $r');
                      if (r is Map) {
                        if (r['lat'] != null) lat.text = r['lat'].toString();
                        if (r['lng'] != null) lng.text = r['lng'].toString();
                        final at = (r['address_text'] ?? '').toString();
                        if (at.isNotEmpty) desc.text = at;
                      }
                    },
                    icon: const Icon(
                      Icons.edit_location_alt_outlined,
                      color: _brown,
                    ),
                    label: const Text(
                      'تعديل الموقع على الخريطة',
                      style: TextStyle(color: _brown),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _brown),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(_r),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _LabeledField(
                    label: 'اسم العنوان',
                    controller: label,
                    hint: ' ضع اسم عنوان صحيح مثل :المنطقة او الحي السكني ',
                  ),
                  _LabeledField(
                    label: 'وصف العنوان (اختياري)',
                    controller: desc,
                    maxLines: 2,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _LabeledField(
                          label: 'Latitude',
                          controller: lat,
                          readOnly: readOnlyCoords,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LabeledField(
                          label: 'Longitude',
                          controller: lng,
                          readOnly: readOnlyCoords,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('تعيين كعنوان افتراضي'),
                    value: isDefault,
                    onChanged: (v) => isDefault = v,
                    activeThumbColor: _brown,
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
                        backgroundColor: _brown,
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

/* ===================== Widgets داخلية ===================== */

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
    final cardColor = theme.cardColor;

    return InkWell(
      onTap: pickMode ? onTap : null,
      borderRadius: const BorderRadius.all(AddressesView._r),
      child: Ink(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.all(AddressesView._r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  address.isDefault == 1
                      ? const Icon(
                          Icons.radio_button_checked,
                          color: AddressesView._brown,
                        )
                      : InkWell(
                          onTap: onMakeDefault,
                          child: const Icon(
                            Icons.radio_button_unchecked,
                            color: Colors.black26,
                          ),
                        ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (address.addressText.trim().isNotEmpty)
                      Text(
                        address.addressText,
                        style: const TextStyle(
                          color: AddressesView._muted,
                          fontSize: 13,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(text: 'Lat: ${address.lat}'),
                        const SizedBox(width: 6),
                        _Chip(text: 'Lng: ${address.lng}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: 'تعديل',
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AddressesView._brown.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AddressesView._brown, fontSize: 12),
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
    final fill =
        theme.inputDecorationTheme.fillColor ??
        theme.colorScheme.surface.withOpacity(
          theme.brightness == Brightness.dark ? 0.25 : 0.9,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        readOnly: readOnly,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: fill,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(AddressesView._r),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(AddressesView._r),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(AddressesView._r),
            borderSide: BorderSide(color: AddressesView._brown, width: 1.2),
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
    final muted =
        theme.textTheme.bodySmall?.color?.withOpacity(0.75) ??
        AddressesView._muted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 54,
              color: theme.iconTheme.color ?? AddressesView._muted,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد عناوين بعد',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'أضف عنوانك الأول من خلال الزر بالأسفل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }
}
