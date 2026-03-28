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
    // 🎨 نفس روح تصميم Register / OTP / طلباتي + دعم الليل
    const kPrimary = Color(0xFF6F3F17); // بني EVORANTA
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final kPageBg = theme.scaffoldBackgroundColor;
    final kDark = isDark ? Colors.white : const Color(0xFF1F2933);

    // ✅ تعديل بسيط: ألوان تعبئة الحقول بدون بنفسجي
    final kFieldFill = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF2F3F7);

    // ✅ تعديل لون بطاقة تسجيل الدخول فقط (إزالة البنفسجي)
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;

    final subTextColor = isDark
        ? Colors.grey.shade400
        : const Color(0xFF6B7280);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kPageBg,
        body: SafeArea(
          child: Stack(
            children: [
              // الهيدر المنحني
              SizedBox.expand(
                child: CustomPaint(
                  painter: const _HeaderPainter(color: kPrimary),
                ),
              ),

              // المحتوى
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 14),
                  // لوجو + نص EVORANTA وسط الأعلى
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 70,
                              height: 70,
                              color: Colors.white,
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'EVORANTA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'أهلاً بعودتك 👋',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 140),

                  // بطاقة تسجيل الدخول
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: c.formKey, // formKey من الكنترولر
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                color: kDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'أدخل بيانات حسابك للمتابعة',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // رقم الهاتف
                            TextFormField(
                              controller: c.phoneCtrl,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'رقم الهاتف',
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                                filled: true,
                                fillColor: kFieldFill,
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              validator: c.validatePhone,
                            ),

                            const SizedBox(height: 12),

                            // كلمة المرور مع إظهار/إخفاء
                            Obx(
                              () => TextFormField(
                                controller: c.passCtrl,
                                obscureText: c.hidePass.value,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _tryLogin(),
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  labelStyle: TextStyle(
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  filled: true,
                                  fillColor: kFieldFill,
                                  border: const OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: c.togglePass,
                                    icon: Icon(
                                      c.hidePass.value
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                                validator: c.validatePass,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // نسيت كلمة المرور
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

                            const SizedBox(height: 4),

                            // زر الدخول
                            SizedBox(
                              height: 46,
                              child: Obx(
                                () => ElevatedButton(
                                  onPressed: c.loading.value ? null : _tryLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                                          'تسجيل دخول',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 🔹 زر الدخول كـ حساب تجريبي
                            SizedBox(
                              height: 42,
                              child: Obx(
                                () => OutlinedButton(
                                  onPressed: c.loading.value
                                      ? null
                                      : c.loginAsGuest,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: kPrimary.withOpacity(
                                        isDark ? 0.9 : 1,
                                      ),
                                      width: 1.1,
                                    ),
                                    foregroundColor: isDark
                                        ? Colors.white
                                        : kPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'الدخول بحساب تجريبي',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
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

                  // إنشاء حساب
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
    FocusScope.of(context).unfocus(); // اغلق الكيبورد
    final ok = c.formKey.currentState?.validate() ?? false;
    if (ok) c.login();
  }
}

// رسّام الهيدر بالقوس + ظل (نفس النمط في الشاشات الأخرى)
class _HeaderPainter extends CustomPainter {
  final Color color;

  const _HeaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double h = 235;
    const double depth = 52;

    final shadowPaint = Paint()
      ..color = const Color(0x1A000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final shadowPath = Path()
      ..moveTo(0, h - depth + 12)
      ..quadraticBezierTo(
        size.width / 2,
        h + depth + 12,
        size.width,
        h - depth + 12,
      )
      ..lineTo(size.width, h + 48)
      ..lineTo(0, h + 48)
      ..close();

    canvas.drawPath(shadowPath, shadowPaint);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h - depth)
      ..quadraticBezierTo(size.width / 2, h + depth, size.width, h - depth)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeaderPainter oldDelegate) =>
      oldDelegate.color != color;
}
