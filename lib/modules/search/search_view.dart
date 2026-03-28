import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'search_controller.dart';
import '../../app_routes.dart';
import '../../data/models/item.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late final SearchControllerX c;

  // 🎨 ألوان ثابتة (للوضع الفاتح أساساً)
  static const Color kPrimary = Color(0xFF6F3F17); // البني المعتمد
  static const Color kPrimarySoft = Color(0xFFF4ECE5); // بني فاتح ناعم
  static const Color kBg = Colors.white; // تستخدم لبعض البوكسات فقط

  static const Color kBorder = Color(0xFFE5E7F0);
  static const Color kTextMain = Color(0xFF22252F);
  static const Color kTextSub = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    c = Get.put<SearchControllerX>(
      SearchControllerX(),
      permanent: true,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.refreshHistory();
    });

    c.input.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Widget _buildAnimatedTile({
    required Widget child,
    required int index,
    required String keyPrefix,
  }) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$keyPrefix-$index'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = c.input.text.trim().isNotEmpty;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // ✨ ألوان ديناميكية حسب الثيم
    final Color textMainColor = isDark ? Colors.white : kTextMain;
    final Color textSubColor = isDark ? Colors.white70 : kTextSub;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: WillPopScope(
        onWillPop: () async {
          if (c.results.isNotEmpty || c.input.text.trim().isNotEmpty) {
            c.reset();
            return false;
          }
          return true;
        },
        child: Scaffold(
          // 👇 الخلفية من الثيم (فاتح/ليلي)
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // شريط علوي بسيط
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      // 🧨 تم إلغاء زر الرجوع واستبداله بمساحة فارغة للحفاظ على التصميم
                      const SizedBox(width: 40),
                      Expanded(
                        child: Text(
                          'البحث عن أصناف',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: textMainColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'ابدأ بكتابة اسم الصنف أو جزء منه لعرض النتائج فوراً ✨',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSubColor,
                      ),
                    ),
                  ),
                ),

                // حقل البحث
                AnimatedContainer(
                  duration: const Duration(milliseconds: 230),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: hasText ? kPrimary.withOpacity(0.7) : kBorder,
                      width: 1.2,
                    ),
                    boxShadow: hasText
                        ? [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.10),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: TextField(
                    controller: c.input,
                    textDirection: TextDirection.rtl,
                    cursorColor: kPrimary,
                    style: TextStyle(
                      color: textMainColor,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن صنف، وجبة أو عرض...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white70 : textSubColor,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: kPrimary, // بني ثابت
                      ),
                      suffixIcon: hasText
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: kPrimary, // بني
                              ),
                              onPressed: () {
                                c.reset();
                              },
                            )
                          : Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              decoration: BoxDecoration(
                                color: kPrimarySoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_dining_outlined,
                                color: kPrimary,
                              ),
                            ),
                      border: InputBorder.none,
                    ),
                    onChanged: c.onTextChanged,
                    onSubmitted: (_) => c.run(),
                  ),
                ),

                const SizedBox(height: 4),

                Expanded(
                  child: Obx(() {
                    if (c.loading.value) {
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimary,
                        ),
                      );
                    }

                    final bool showHistory = c.results.isEmpty;

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            axisAlignment: -1,
                            child: child,
                          ),
                        );
                      },
                      child: showHistory
                          ? _buildHistorySection()
                          : _buildResultsSection(),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color textMainColor = isDark ? Colors.white : kTextMain;
    final Color textSubColor = isDark ? Colors.white70 : kTextSub;

    return Padding(
      key: const ValueKey('history-view'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.history.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: kPrimary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'الأصناف التي بحثت عنها مؤخراً',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: textMainColor,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: c.clearHistory,
                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 18,
                  color: Colors.redAccent,
                ),
                label: const Text(
                  'مسح السجل',
                  style: TextStyle(color: kPrimary),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: c.history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final ItemModel it = c.history[i];

                  final tile = Dismissible(
                    key: ValueKey('history_${it.id}_$i'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                    onDismissed: (_) {
                      c.deleteHistoryItem(it);
                    },
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await c.searchFromHistory(it);
                        await Get.toNamed(
                          AppRoutes.itemDetail,
                          arguments: it.toJson(),
                        );
                        c.reset();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: kBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              it.imageUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 52,
                                height: 52,
                                color: kBg,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: textSubColor,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            it.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textMainColor,
                            ),
                          ),
                          subtitle: Text(
                            it.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSubColor,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: kPrimary, // بني ثابت
                          ),
                        ),
                      ),
                    ),
                  );

                  return _buildAnimatedTile(
                    child: tile,
                    index: i,
                    keyPrefix: 'history-tile',
                  );
                },
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.9, end: 1),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          size: 36,
                          color: kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ابدأ بالكتابة للبحث عن الأصناف.',
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color textMainColor = isDark ? Colors.white : kTextMain;
    final Color textSubColor = isDark ? Colors.white70 : kTextSub;

    return Padding(
      key: const ValueKey('results-view'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Obx(
            () => c.fromCache.value
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 6, right: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.offline_bolt_outlined,
                          size: 16,
                          color: kPrimary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'هذه النتائج معروضة من الكاش (بدون طلب جديد).',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: textSubColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: c.results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final ItemModel it = c.results[i];

                final tile = InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await c.saveItemToHistory(it);
                    await Get.toNamed(
                      AppRoutes.itemDetail,
                      arguments: it.toJson(),
                    );
                    c.reset();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          it.imageUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 52,
                            height: 52,
                            color: kBg,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: textSubColor,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        it.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textMainColor,
                        ),
                      ),
                      subtitle: Text(
                        it.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSubColor,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          SizedBox(height: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: kPrimary, // بني ثابت
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                return _buildAnimatedTile(
                  child: tile,
                  index: i,
                  keyPrefix: 'result-tile',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
