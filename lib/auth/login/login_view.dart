import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/auth/forgot/forgot_phone_view.dart';
import 'login_controller.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginController c;

  @override
  void initState() {
    super.initState();
    c = Get.put(LoginController());
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
                      children: [const Spacer()],
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
                          'تسجيل الدخول',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'أهلاً بعودتك، سجّل دخولك للمتابعة',
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
                        key: c.formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                    Icons.login_rounded,
                                    color: kPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'بيانات الدخول',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: kTextMain,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'أدخل رقم الهاتف وكلمة المرور للوصول لحسابك.',
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
                              controller: c.phoneCtrl,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
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
                                  Icons.phone_outlined,
                                  color: kPrimary,
                                ),
                                filled: true,
                                fillColor: kFieldFill,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                              ),
                              validator: c.validatePhone,
                            ),
                            const SizedBox(height: 14),
                            Obx(
                              () => TextFormField(
                                controller: c.passCtrl,
                                obscureText: c.hidePass.value,
                                textInputAction: TextInputAction.done,
                                textAlign: TextAlign.right,
                                onFieldSubmitted: (_) => _tryLogin(),
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
                                    onPressed: c.togglePass,
                                    icon: Icon(
                                      c.hidePass.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: kFieldFill,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 16,
                                  ),
                                ),
                                validator: c.validatePass,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  Get.to(const ForgotPhoneView());
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  foregroundColor: kPrimary,
                                ),
                                child: const Text(
                                  'نسيت كلمة المرور؟',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 54,
                              child: Obx(
                                () => ElevatedButton(
                                  onPressed: c.loading.value ? null : _tryLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
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
                                          'تسجيل دخول',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 48,
                              child: Obx(
                                () => OutlinedButton(
                                  onPressed: c.loading.value
                                      ? null
                                      : c.loginAsGuest,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: kPrimary.withOpacity(.9),
                                      width: 1.2,
                                    ),
                                    backgroundColor: kSoftOrange,
                                    foregroundColor: kPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'الدخول بحساب تجريبي',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
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
                      onPressed: c.goToRegister,
                      style: TextButton.styleFrom(foregroundColor: kPrimary),
                      child: const Text(
                        'إنشاء حساب جديد',
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

  void _tryLogin() {
    FocusScope.of(context).unfocus();
    final ok = c.formKey.currentState?.validate() ?? false;
    if (ok) c.login();
  }
}
