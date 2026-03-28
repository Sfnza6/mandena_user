import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'account_controller.dart';

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  static const Color kPrimary = Color(0xFFFF5A00);
  static const Color kPrimaryDark = Color(0xFFFF2E00);
  static const Color kPageBg = Color(0xFFF5F5F7);
  static const Color kCard = Colors.white;
  static const Color kText = Color(0xFF111827);
  static const Color kMuted = Color(0xFF8B95A7);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AccountController>()) {
      Get.put(AccountController(), permanent: true);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kPageBg,
        body: RefreshIndicator(
          onRefresh: controller.fetchProfile,
          color: kPrimary,
          child: Obx(() {
            final u = controller.user.value;
            final username = (u?.username ?? '').trim().isEmpty
                ? 'المستخدم'
                : u!.username;
            final phone = (u?.phone ?? '').trim();

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [kPrimary, kPrimaryDark],
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      18,
                      MediaQuery.of(context).padding.top + 18,
                      18,
                      30,
                    ),
                    child: Column(
                      children: [
                        if (Navigator.of(context).canPop())
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Get.back(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                        const SizedBox(height: 4),
                        const Center(
                          child: Text(
                            'حسابي',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.13),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      username,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 21,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      phone.isEmpty
                                          ? 'لا يوجد رقم محفوظ'
                                          : phone,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: Color(0xFFFFE7D6),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _MenuTile(
                            title: 'الطلبات السابقة',
                            icon: Icons.receipt_long_outlined,

                            onTap: controller.goToOrders,
                          ),
                          _MenuTile(
                            title: 'العناوين المحفوظة',
                            icon: Icons.location_on_outlined,
                            onTap: controller.goToAddress,
                          ),
                          _MenuTile(
                            title: 'طرق الدفع',
                            icon: Icons.credit_card_outlined,
                            onTap: () {},
                          ),
                          _MenuTile(
                            title: 'الإشعارات',
                            icon: Icons.notifications_none_rounded,
                            onTap: () {},
                          ),
                          _MenuTile(
                            title: 'الإعدادات',
                            icon: Icons.settings_outlined,
                            onTap: controller.toggleDarkMode,
                          ),
                          _MenuTile(
                            title: 'المساعدة والدعم',
                            icon: Icons.help_outline_rounded,
                            onTap: controller.openDevelopers,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: InkWell(
                      onTap: controller.logout,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: kCard,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text(
                              'تسجيل الخروج',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 28),
                    child: Center(
                      child: Text(
                        'الإصدار 1.0.0',
                        style: TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.icon,
    required this.onTap,
    // ignore: unused_element_parameter
    this.badge,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AccountView.kPrimary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AccountView.kText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                margin: const EdgeInsetsDirectional.only(start: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AccountView.kPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.chevron_left_rounded, color: AccountView.kMuted),
          ],
        ),
      ),
    );
  }
}
