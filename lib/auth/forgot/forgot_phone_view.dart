import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mandena/auth/forgot/new_password_view.dart';
import '../otp/otp_verification_view.dart';
import 'forgot_controller.dart';

class ForgotPhoneView extends StatefulWidget {
  const ForgotPhoneView({super.key});

  @override
  State<ForgotPhoneView> createState() => _ForgotPhoneViewState();
}

class _ForgotPhoneViewState extends State<ForgotPhoneView> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  late final ForgotController c;

  @override
  void initState() {
    super.initState();
    c = Get.isRegistered<ForgotController>()
        ? Get.find<ForgotController>()
        : Get.put(ForgotController());
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 نفس ألوان شاشات الـ Auth + الليل
    const kPrimary = Color(0xFF6F3F17); // بني EVORANTA

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final kPageBg = theme.scaffoldBackgroundColor;
    final kDark = isDark ? Colors.white : const Color(0xFF1F2933);
    final kFieldFill =
        theme.inputDecorationTheme.fillColor ??
        (isDark ? theme.cardColor.withOpacity(0.9) : const Color(0xFFF2F3F7));
    final cardColor = theme.cardColor;
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
              // هيدر منحني
              SizedBox.expand(
                child: CustomPaint(
                  painter: const _HeaderPainter(color: kPrimary),
                ),
              ),

              // المحتوى
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 20),

                  // شريط علوي بسيط: رجوع + عنوان
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'استعادة كلمة المرور',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),

                  // الكارد
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
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'أدخل رقم هاتفك لإرسال رمز التحقق',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: kDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'سنرسل لك رمز تحقق عبر رسالة قصيرة لتأكيد هويتك',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // حقل رقم الهاتف
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
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
                              validator: (v) {
                                v = v?.trim() ?? '';
                                final d = v.replaceAll(RegExp(r'\D'), '');
                                if (d.isEmpty) return 'أدخل رقم الهاتف';
                                if (d.length < 7) return 'رقم غير صالح';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // زر إرسال الرمز
                            Obx(
                              () => SizedBox(
                                height: 46,
                                child: ElevatedButton(
                                  onPressed: c.sending.value ? null : _send,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: c.sending.value
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'إرسال الرمز',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
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

                  const SizedBox(height: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final phone = _phone.text.trim();

    final r = await c.sendOtp(phone);
    if ((r['status'] ?? '').toString().toLowerCase() != 'ok') {
      Get.snackbar(
        'خطأ',
        (r['message'] ?? 'تعذّر إرسال رمز التحقق').toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final otpId = (r['otp_id'] ?? '').toString();

    // إلى شاشة الـ OTP — عند النجاح نذهب لشاشة كلمة مرور جديدة
    Get.to(
      () => OtpVerificationView(
        phone: phone,
        otpId: otpId,
        onVerified: () async {
          Get.to(() => NewPasswordView(phone: phone));
        },
      ),
    );
  }
}

/// رسام الهيدر المنحني (نفس روح شاشات Auth)
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
