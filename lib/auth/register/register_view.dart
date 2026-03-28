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
    // 🎨 نفس روح وألوان "طلباتي" + دعم الوضع الليلي
    const kPrimary = Color(0xFF6F3F17); // بني EVORANTA

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final kPageBg = theme.scaffoldBackgroundColor;
    final kDark = isDark ? Colors.white : const Color(0xFF1F2933);

    // ✅ إلغاء البنفسجي: تعبئة الحقول بلون ثابت
    final kFieldFill =
        isDark ? const Color(0xFF111827) : const Color(0xFFF2F3F7);

    // ✅ إلغاء البنفسجي: الكارد بلون ثابت
    final cardColor = isDark ? const Color(0xFF111827) : Colors.white;

    final subTextColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF9CA3AF);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kPageBg,
        body: SafeArea(
          child: Stack(
            children: [
              // ترويسة منحنية بنفس روح "طلباتي"
              SizedBox.expand(
                child: CustomPaint(
                  painter: const _HeaderPainter(color: kPrimary),
                ),
              ),

              // محتوى الصفحة
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 14),

                  // شريط علوي مثل طلباتي: رجوع + عنوان
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'إنشاء حساب جديد',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'أنشئ حسابك وابدأ بطلب وجباتك من EVORANTA',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // شعار صغير مثل "طلباتي"
                        Image.asset(
                          'assets/images/logo.png',
                          width: 34,
                          height: 34,
                          color: Colors.white,
                          colorBlendMode: BlendMode.srcIn,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // كارت فيه الفورم (نفس روح كروت طلباتي)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'بيانات الحساب',
                              style: TextStyle(
                                color: kDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'أدخل بياناتك بدقة لتسهيل عملية التوصيل والتواصل.',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // الاسم
                            TextFormField(
                              controller: c.nameCtrl,
                              decoration: InputDecoration(
                                labelText: 'الاسم الكامل',
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                                prefixIconColor:
                                    isDark ? Colors.white70 : Colors.black45,
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
                                    Radius.circular(12),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'أدخل الاسم'
                                      : null,
                            ),
                            const SizedBox(height: 12),

                            // رقم الهاتف
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: c.phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      labelText: 'رقم الهاتف',
                                      prefixIcon: const Icon(
                                        Icons.phone_iphone_rounded,
                                      ),
                                      prefixIconColor: isDark
                                          ? Colors.white70
                                          : Colors.black45,
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
                                          Radius.circular(12),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                    ),
                                    validator: (v) {
                                      v = v?.trim() ?? '';
                                      if (v.isEmpty) return 'أدخل رقم الهاتف';
                                      if (v.length < 7) return 'رقم غير صالح';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // كلمة المرور مع إظهار/إخفاء
                            Obx(
                              () => TextFormField(
                                controller: c.passCtrl,
                                obscureText: c.hidePass.value,
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  prefixIconColor: isDark
                                      ? Colors.white70
                                      : Colors.black45,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      c.hidePass.value
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black45,
                                    ),
                                    onPressed: c.togglePass,
                                  ),
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
                                      Radius.circular(12),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().length < 6)
                                        ? 'ستة أحرف على الأقل'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // تأكيد كلمة المرور مع إظهار/إخفاء
                            Obx(
                              () => TextFormField(
                                controller: c.pass2Ctrl,
                                obscureText: c.hidePass2.value,
                                decoration: InputDecoration(
                                  labelText: 'تأكيد كلمة المرور',
                                  prefixIcon: const Icon(
                                    Icons.lock_reset_rounded,
                                  ),
                                  prefixIconColor: isDark
                                      ? Colors.white70
                                      : Colors.black45,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      c.hidePass2.value
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black45,
                                    ),
                                    onPressed: c.togglePass2,
                                  ),
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
                                      Radius.circular(12),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'أعد التأكيد';
                                  }
                                  if (v.trim() !=
                                      c.passCtrl.text.trim()) {
                                    return 'تأكيد كلمة المرور غير متطابق';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // زر إنشاء حساب
                            SizedBox(
                              height: 48,
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: c.loading.value
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'إنشاء حساب',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
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

                  const SizedBox(height: 14),

                  // سطر الانتقال لتسجيل الدخول (بنفس أسلوب الروابط في طلباتي)
                  Center(
                    child: TextButton(
                      onPressed: () => Get.offNamed(AppRoutes.login),
                      style: TextButton.styleFrom(
                        foregroundColor: kPrimary,
                      ),
                      child: const Text(
                        'لديك حساب؟ تسجيل دخول',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
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

// رسّام الهيدر بالقوس (نفس روح طلباتي)
class _HeaderPainter extends CustomPainter {
  final Color color;
  const _HeaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double h = 210;
    const double depth = 46;

    // ظل خفيف تحت القوس مثل الكروت في طلباتي
    final shadowPaint = Paint()
      ..color = const Color(0x1A000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    final shadowPath = Path()
      ..moveTo(0, h - depth + 12)
      ..quadraticBezierTo(
        size.width / 2,
        h + depth + 10,
        size.width,
        h - depth + 12,
      )
      ..lineTo(size.width, h + 52)
      ..lineTo(0, h + 52)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // شكل الخلفية المنحنية
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h - depth)
      ..quadraticBezierTo(
        size.width / 2,
        h + depth,
        size.width,
        h - depth,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeaderPainter oldDelegate) =>
      oldDelegate.color != color;
}
