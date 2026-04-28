import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'account_controller.dart';

class AccountView extends GetView<AccountController> {
  const AccountView({super.key});

  static const Color kPrimary = Color(0xFFFF5A00);
  static const Color kPrimaryDark = Color(0xFFFF2E00);
  static const Color kMuted = Color(0xFF8B95A7);

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AccountController>()) {
      Get.put(AccountController(), permanent: true);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF111827);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
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
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? .18 : .05),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _MenuTile(
                            title: 'العناوين المحفوظة',
                            icon: Icons.location_on_outlined,
                            onTap: controller.goToAddress,
                          ),
                          _MenuTile(
                            title: 'الإعدادات',
                            icon: Icons.settings_outlined,
                            onTap: () {
                              Get.to(
                                () => _AccountSettingsPage(
                                  username: username,
                                  phone: phone,
                                ),
                              );
                            },
                          ),
                          Obx(
                            () => _DarkModeTile(
                              value: controller.isDarkMode.value,
                              onChanged: (_) => controller.toggleDarkMode(),
                            ),
                          ),
                          _MenuTile(
                            title: 'المساعدة والدعم',
                            icon: Icons.help_outline_rounded,
                            onTap: controller.openDevelopers,
                            hideDivider: true,
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
                          color: card,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? .18 : .05,
                              ),
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

class _AccountSettingsPage extends StatelessWidget {
  const _AccountSettingsPage({required this.username, required this.phone});

  final String username;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF111827);
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withOpacity(.8) ??
        const Color(0xFF8B95A7);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: bg,
          centerTitle: true,
          title: Text(
            'الإعدادات',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? .18 : .05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'بيانات الزبون',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(label: 'الاسم', value: username),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'رقم الهاتف',
                    value: phone.isEmpty ? 'غير متوفر' : phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? .18 : .05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Get.to(() => const _ChangePasswordPage());
                },
                leading: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AccountView.kMuted,
                ),
                trailing: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AccountView.kPrimary,
                  ),
                ),
                title: Text(
                  'تغيير كلمة السر',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  'تحديث كلمة المرور الخاصة بحسابك',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: mutedColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordPage extends StatefulWidget {
  const _ChangePasswordPage();

  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  late final AccountController controller;

  final oldPass = TextEditingController();
  final newPass = TextEditingController();
  final confirmPass = TextEditingController();

  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AccountController>();
  }

  @override
  void dispose() {
    oldPass.dispose();
    newPass.dispose();
    confirmPass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await controller.changePassword(
      oldPassword: oldPass.text.trim(),
      newPassword: newPass.text.trim(),
      confirmPassword: confirmPass.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;
    final card = theme.cardColor;
    final textColor =
        theme.textTheme.bodyLarge?.color ?? const Color(0xFF111827);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: bg,
          centerTitle: true,
          title: Text(
            'تغيير كلمة السر',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Obx(
          () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        theme.brightness == Brightness.dark ? .18 : .05,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _PasswordField(
                      controller: oldPass,
                      label: 'كلمة السر الحالية',
                      obscure: obscureOld,
                      onToggle: () => setState(() => obscureOld = !obscureOld),
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      controller: newPass,
                      label: 'كلمة السر الجديدة',
                      obscure: obscureNew,
                      onToggle: () => setState(() => obscureNew = !obscureNew),
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      controller: confirmPass,
                      label: 'تأكيد كلمة السر الجديدة',
                      obscure: obscureConfirm,
                      onToggle: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: controller.loading.value ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AccountView.kPrimary,
                          disabledBackgroundColor: AccountView.kPrimary
                              .withOpacity(.55),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: controller.loading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'حفظ التغييرات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      obscureText: obscure,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        filled: true,
        fillColor: theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(.06)
            : const Color(0xFFF8F8FA),
        prefixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF111827);

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AccountView.kMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.hideDivider = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool hideDivider;

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF111827);

    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          trailing: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: AccountView.kMuted,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AccountView.kPrimary),
          ),
          title: Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
          ),
        ),
        if (!hideDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _DarkModeTile extends StatelessWidget {
  const _DarkModeTile({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF111827);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          trailing: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AccountView.kPrimary,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dark_mode_outlined,
              color: AccountView.kPrimary,
            ),
          ),
          title: Text(
            'الوضع المظلم',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
          ),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
