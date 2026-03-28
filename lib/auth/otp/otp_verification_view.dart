import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'otp_controller.dart';

class OtpVerificationView extends StatefulWidget {
  final String phone;
  final String otpId;

  // يُستدعى بعد نجاح التحقق (مثلاً: انتقال لواجهة تسجيل الدخول)
  final Future<void> Function() onVerified;

  const OtpVerificationView({
    super.key,
    required this.phone,
    required this.otpId,
    required this.onVerified,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  String _code = '';
  late final OtpController otpC;

  bool _navigating = false; // لمنع ضغطات متكررة أثناء الانتقال

  @override
  void initState() {
    super.initState();
    otpC = Get.isRegistered<OtpController>()
        ? Get.find<OtpController>()
        : Get.put(OtpController());
    otpC.startTimer(60);
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 نفس روح وألوان طلباتي / التسجيل + دعم الليل
    const kPrimary = Color(0xFF6F3F17); // بني EVORANTA

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final kPageBg = theme.scaffoldBackgroundColor;
    final kDark = isDark ? Colors.white : const Color(0xFF1F2933);
    final kFieldFill = theme.inputDecorationTheme.fillColor ??
        (isDark ? theme.cardColor.withOpacity(0.9) : const Color(0xFFF2F3F7));
    final cardColor = theme.cardColor;
    final subTextColor =
        isDark ? Colors.grey.shade400 : const Color(0xFF6B7280);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kPageBg,
        body: SafeArea(
          child: Stack(
            children: [
              // هيدر منحني مثل باقي الشاشات
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

                  // شريط علوي: رجوع + عنوان
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'التحقق من رقم الهاتف',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'أدخل رمز التحقق المرسل إلى هاتفك',
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
                        // شعار صغير
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

                  const SizedBox(height: 40),

                  // كرت الـ OTP
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'رمز التحقق (OTP)',
                            style: TextStyle(
                              color: kDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'أدخل الرمز المُرسل إلى: ${widget.phone}',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // حقل إدخال الرمز
                          TextField(
                            enabled: !_navigating,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            onChanged: (v) => _code = v,
                            onSubmitted: (_) => _onVerify(),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••••',
                              hintStyle: TextStyle(
                                letterSpacing: 6,
                                color: isDark
                                    ? Colors.grey.shade500
                                    : const Color(0xFF9CA3AF),
                              ),
                              filled: true,
                              fillColor: kFieldFill,
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 24,
                              letterSpacing: 6,
                              fontWeight: FontWeight.w800,
                              color: kDark,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // زر التحقق
                          Obx(
                            () => SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: (_navigating ||
                                        otpC.isVerifying.value)
                                    ? null
                                    : _onVerify,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: (otpC.isVerifying.value || _navigating)
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'تحقق',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // إعادة الإرسال
                          Center(
                            child: Obx(() {
                              if (otpC.resendLeft.value > 0) {
                                return Text(
                                  'إعادة الإرسال بعد ${otpC.resendLeft.value} ثانية',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
                                  ),
                                );
                              }
                              return TextButton(
                                onPressed: _navigating
                                    ? null
                                    : () async {
                                        FocusScope.of(context).unfocus();
                                        final r = await otpC.sendOtp(
                                            phone: widget.phone); // إرسال فعلي
                                        if ((r['status'] ?? '')
                                                .toString()
                                                .toLowerCase() ==
                                            'ok') {
                                          Get.snackbar(
                                            'تم',
                                            'أُعيد إرسال الرمز',
                                            snackPosition:
                                                SnackPosition.BOTTOM,
                                          );
                                          otpC.startTimer(60);
                                        } else {
                                          Get.snackbar(
                                            'خطأ',
                                            (r['message'] ??
                                                    'تعذّر إرسال الرمز')
                                                .toString(),
                                            snackPosition:
                                                SnackPosition.BOTTOM,
                                          );
                                        }
                                      },
                                child: const Text(
                                  'إعادة إرسال الرمز',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: kPrimary,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onVerify() async {
    final code = _code.trim();
    if (code.length < 4) {
      Get.snackbar(
        'تنبيه',
        'أدخل الرمز كاملاً',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    final r = await otpC.verifyOtp(
      phone: widget.phone,
      code: code,
      otpId: widget.otpId,
    );
    if (!mounted) return;

    final status = (r['status'] ?? '').toString().toLowerCase();
    if (status == 'ok' || status == 'success' || status == 'verified') {
      setState(() => _navigating = true); // قفل التفاعل قبل الانتقال
      Get.snackbar(
        'تم',
        (r['message'] ?? 'تم التحقق بنجاح. يمكنك المتابعة.').toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      await Future.microtask(() => widget.onVerified());
      return;
    }
    if (status == 'expired') {
      Get.snackbar(
        'انتهى',
        'انتهت صلاحية الرمز، أعد الإرسال',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.snackbar(
      'فشل',
      (r['message'] ?? 'رمز خاطئ').toString(),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

/// رسام الهيدر (نفس الروح مع تعديل بسيط)
class _HeaderPainter extends CustomPainter {
  final Color color;
  const _HeaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double h = 210;
    const double depth = 46;

    // ظل خفيف تحت القوس
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

    // خلفية منحنية
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
