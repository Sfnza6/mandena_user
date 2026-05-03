import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app_routes.dart';
import 'forgot_controller.dart';

class NewPasswordView extends StatefulWidget {
  final String phone;
  const NewPasswordView({super.key, required this.phone});

  @override
  State<NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<NewPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
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
    _p1.dispose();
    _p2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 ألوان بنفس روح شاشة اللوجين / التسجيل + الليل
    const kPrimary = Color(0xFFFF5A00); // برتقالي EVORANTA

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final kPageBg = theme.scaffoldBackgroundColor;
    final kDark = isDark ? Colors.white : const Color(0xFF1F2933);
    final kFieldFill =
        theme.inputDecorationTheme.fillColor ??
        (isDark ? theme.cardColor.withOpacity(0.9) : const Color(0xFFFFFAF6));
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
              // الهيدر المنحني في الأعلى
              SizedBox.expand(
                child: CustomPaint(
                  painter: const _HeaderPainter(color: kPrimary),
                ),
              ),

              // محتوى الشاشة
              ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 20),

                  // عنوان أعلى الهيدر مع زر رجوع
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
                          'إعادة تعيين كلمة المرور',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 110),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
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
                              'الهاتف: ${widget.phone}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أدخل كلمة مرور قوية واحفظها جيداً',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // كلمة المرور الجديدة
                            TextFormField(
                              controller: _p1,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'كلمة المرور الجديدة',
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
                                    Radius.circular(16),
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
                            const SizedBox(height: 10),

                            // تأكيد كلمة المرور
                            TextFormField(
                              controller: _p2,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'تأكيد كلمة المرور',
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
                                    Radius.circular(16),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              validator: (v) => (v?.trim() != _p1.text.trim())
                                  ? 'تأكيد كلمة المرور غير متطابق'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // زر الحفظ
                            Obx(
                              () => SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: c.resetting.value ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: c.resetting.value
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'حفظ',
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

                  const SizedBox(height: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final pass = _p1.text.trim();
    final r = await c.resetPassword(phone: widget.phone, newPassword: pass);
    if ((r['status'] ?? '').toString().toLowerCase() == 'ok') {
      Get.snackbar(
        'تم',
        'تم تحديث كلمة المرور. يمكنك تسجيل الدخول الآن',
        snackPosition: SnackPosition.TOP,
      );
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.snackbar(
        'خطأ',
        (r['message'] ?? 'تعذّر التحديث').toString(),
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}

// نفس رسام الهيدر المستعمل في شاشات auth
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
