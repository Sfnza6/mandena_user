import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/modules/branch/branch_controller.dart';

import '../home_controller.dart';
import '../widgets/home_ui.dart';

class HomeHeaderSection extends StatelessWidget {
  const HomeHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    final branch = Get.find<BranchController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.cardColor;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF111827);
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ??
        const Color(0xFF6B7280);
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tileBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC);
    final selectedTileBg = isDark
        ? const Color(0xFF2A1D14)
        : const Color(0xFFFFF3EC);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [HomeUi.kHeader, HomeUi.kHeaderAccent],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 14,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => _TopSelector(
                    title: 'التوصيل إلى',
                    value: c.location.value.trim().isEmpty
                        ? 'المنزل'
                        : c.location.value.trim(),
                    icon: Icons.location_on_outlined,
                    onTap: c.openAddresses,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Obx(
                  () => _TopSelector(
                    title: 'الفرع',
                    value: branch.selectedBranchName,
                    icon: branch.changing.value
                        ? Icons.sync
                        : Icons.keyboard_arrow_down_rounded,
                    onTap: branch.changing.value
                        ? null
                        : () => _showBranchSheet(
                            context,
                            sheetBg: sheetBg,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            dividerColor: dividerColor,
                            tileBg: tileBg,
                            selectedTileBg: selectedTileBg,
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.waving_hand_rounded,
                        color: Color(0xFFFFE4D0),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'مرحباً بك في ماندينا 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'ماذا ترغب أن نطلبه اليوم؟',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFFFFE7D6),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: c.openSearch,
                  borderRadius: BorderRadius.circular(22),
                  child: IgnorePointer(
                    child: TextField(
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن صنف بالاسم...',
                        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9CA3AF),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: HomeUi.kPrimary,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBranchSheet(
    BuildContext context, {
    required Color sheetBg,
    required Color textColor,
    required Color mutedColor,
    required Color dividerColor,
    required Color tileBg,
    required Color selectedTileBg,
  }) {
    final branch = Get.find<BranchController>();
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Obx(() {
            final list = branch.branches;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  'اختيار الفرع',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'عند تغيير الفرع سيتم تحديث الصفحة الرئيسية، ولكل فرع سلة ومفضلة خاصة به.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: mutedColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                if (branch.loading.value)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (list.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'لا توجد فروع متاحة حالياً',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  )
                else
                  ...list.map((b) {
                    final selected = b.id == branch.selectedBranchId.value;
                    return InkWell(
                      onTap: branch.changing.value
                          ? null
                          : () => branch.changeBranch(b.id),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected ? selectedTileBg : tileBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selected ? HomeUi.kPrimary : dividerColor,
                            width: selected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (selected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: HomeUi.kPrimary,
                              ),
                            if (selected) const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    b.name,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15.5,
                                    ),
                                  ),
                                  if (b.addressText.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      b.addressText,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          }),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _TopSelector extends StatelessWidget {
  const _TopSelector({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(.20)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, color: Colors.white, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFFFFE7D6),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
