import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'register_controller.dart';
import '../../../app_routes.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  late final RegisterController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(RegisterController(), permanent: true);
  }

  @override
  Widget build(BuildContext context) {
    const kPrimary = Color(0xFFFF5A00);
    const kPrimaryDark = Color(0xFFFF2E00);
    const kSoftOrange = Color(0xFFFFF1E9);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final kPageBg = isDark
        ? theme.scaffoldBackgroundColor
        : const Color(0xFFF5F5F7);
    final kTextMain = isDark ? Colors.white : const Color(0xFF111827);
    final kTextSub = isDark ? Colors.white70 : const Color(0xFF8B95A7);
    final kFieldFill = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFFFFAF6);
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kPageBg,
        body: SafeArea(
          child: Stack(
            children: [
              // هيدر مربع مختلف عن السابق
              Container(
                height: 270,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [kPrimary, kPrimaryDark],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      left: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.07),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      right: -25,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Container(
                        //   width: 42,
                        //   height: 42,
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withOpacity(.14),
                        //     shape: BoxShape.circle,
                        //   ),
                        //   alignment: Alignment.center,
                        //   child: Image.asset(
                        //     'assets/images/logo.png',
                        //     width: 24,
                        //     height: 24,
                        //     color: Colors.white,
                        //     colorBlendMode: BlendMode.srcIn,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.14),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/Logo.png',
                            width: 50,
                            height: 50,
                            color: Colors.white,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'إنشاء حساب جديد',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'أنشئ حسابك وابدأ بطلب وجباتك من ماندينا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFFFE3D3),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 72),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: kSoftOrange,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.person_add_alt_1_rounded,
                                    color: kPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'بيانات الحساب',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: kTextMain,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'أدخل بياناتك بدقة لتسهيل التوصيل والتواصل.',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: kTextSub,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            TextFormField(
                              controller: c.nameCtrl,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'الاسم الكامل',
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w700,
                                ),
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                  color: kPrimary,
                                ),
                                filled: true,
                                fillColor: kFieldFill,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'أدخل الاسم'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            TextFormField(
                              controller: c.phoneCtrl,
                              keyboardType: TextInputType.phone,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                labelText: 'رقم الهاتف',
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w700,
                                ),
                                prefixIcon: const Icon(
                                  Icons.phone_iphone_rounded,
                                  color: kPrimary,
                                ),
                                filled: true,
                                fillColor: kFieldFill,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                              ),
                              validator: (v) {
                                v = v?.trim() ?? '';
                                if (v.isEmpty) return 'أدخل رقم الهاتف';
                                if (v.length < 7) return 'رقم غير صالح';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            Obx(
                              () => TextFormField(
                                controller: c.passCtrl,
                                obscureText: c.hidePass.value,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: kPrimary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      c.hidePass.value
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                    onPressed: c.togglePass,
                                  ),
                                  filled: true,
                                  fillColor: kFieldFill,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().length < 6)
                                    ? 'ستة أحرف على الأقل'
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 14),

                            Obx(
                              () => TextFormField(
                                controller: c.pass2Ctrl,
                                obscureText: c.hidePass2.value,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  labelText: 'تأكيد كلمة المرور',
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_reset_rounded,
                                    color: kPrimary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      c.hidePass2.value
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                    onPressed: c.togglePass2,
                                  ),
                                  filled: true,
                                  fillColor: kFieldFill,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'أعد التأكيد';
                                  }
                                  if (v.trim() != c.passCtrl.text.trim()) {
                                    return 'تأكيد كلمة المرور غير متطابق';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 18),

                            SizedBox(
                              height: 54,
                              child: Obx(
                                () => ElevatedButton(
                                  onPressed: c.loading.value
                                      ? null
                                      : () {
                                          if (!(_formKey.currentState
                                                  ?.validate() ??
                                              false)) {
                                            return;
                                          }
                                          c.registerWithOtp();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: c.loading.value
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'إنشاء حساب',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Get.offNamed(AppRoutes.login),
                      style: TextButton.styleFrom(foregroundColor: kPrimary),
                      child: const Text(
                        'لديك حساب؟ تسجيل دخول',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
