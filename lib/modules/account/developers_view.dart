import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DevelopersViewPage extends StatelessWidget {
  const DevelopersViewPage({super.key});

  // ألوان متناسقة مع باقي التطبيق
  static const Color _primary = Color(0xFFFF5A1F);
  static const Color _primaryDark = Color(0xFFFF2D00);
  static const Color _pageBg = Color(0xFFF7F7F7);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF222222);
  static const Color _textMute = Color(0xFF777777);
  static const Radius _r = Radius.circular(18);

  /// عدّل هذا الرابط برابط صفحة الشركة الحقيقي
  static const String facebookUrl =
      'https://www.facebook.com/profile.php?id=61571073890168';

  /// عدّل المسار حسب مكان شعار الشركة عندك
  static const String logoPath = 'assets/images/brainware_logo.png';

  Future<void> _openFacebook() async {
    final uri = Uri.parse(facebookUrl);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar(
        'تنبيه',
        'تعذر فتح رابط الفيس بوك',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? theme.scaffoldBackgroundColor : _pageBg;
    final cardColor = isDark ? theme.cardColor : _cardBg;
    final mainTextColor = isDark ? Colors.white : _textDark;
    final muted =
        theme.textTheme.bodySmall?.color?.withOpacity(0.75) ?? _textMute;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: bgColor,
          centerTitle: true,
          title: Text(
            'عن الشركة',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: mainTextColor,
              fontSize: 20,
            ),
          ),
          iconTheme: IconThemeData(color: mainTextColor),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.all(_r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompanyLogo(size: 78, logoPath: logoPath),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'BRAINWARE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 21,
                                color: mainTextColor,
                                letterSpacing: .3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'حلول برمجية حديثة للأعمال',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'شركة BRAINWARE متخصصة في تصميم وتطوير الحلول البرمجية والتطبيقات الذكية، '
                    'ونعمل على تحويل الأفكار إلى منتجات رقمية عملية، مستقرة، وسهلة الاستخدام.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: muted,
                      height: 1.7,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'نقدّم خدمات تشمل تطوير تطبيقات الجوال، أنظمة الطلبات والتوصيل، لوحات التحكم، '
                    'المواقع الإلكترونية، وربط الأنظمة بقواعد البيانات وواجهات API بطريقة منظمة وآمنة.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: muted,
                      height: 1.7,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const _SectionHeader('رؤيتنا'),

            _InfoCard(
              icon: Icons.visibility_rounded,
              title: 'رؤية الشركة',
              text:
                  'نسعى لبناء حلول رقمية تساعد الشركات والمطاعم والمتاجر على إدارة أعمالها بكفاءة أعلى، '
                  'وتقديم تجربة استخدام احترافية لعملائها.',
              cardColor: cardColor,
              textColor: mainTextColor,
              mutedColor: muted,
            ),

            const SizedBox(height: 12),

            _InfoCard(
              icon: Icons.verified_rounded,
              title: 'أسلوب العمل',
              text:
                  'نهتم بالتفاصيل الصغيرة التي تصنع الفرق: الأداء، الاستقرار، سهولة الاستخدام، '
                  'وضوح الواجهات، وجودة تجربة المستخدم من أول شاشة إلى آخر عملية.',
              cardColor: cardColor,
              textColor: mainTextColor,
              mutedColor: muted,
            ),

            const SizedBox(height: 12),

            _InfoCard(
              icon: Icons.handshake_rounded,
              title: 'هدفنا',
              text:
                  'هدفنا أن يحصل العميل على منتج برمجي حقيقي يخدم مشروعه، قابل للتطوير، '
                  'ويعكس هوية علامته التجارية بشكل احترافي.',
              cardColor: cardColor,
              textColor: mainTextColor,
              mutedColor: muted,
            ),

            const SizedBox(height: 22),

            InkWell(
              onTap: _openFacebook,
              borderRadius: const BorderRadius.all(_r),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _primaryDark],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  borderRadius: const BorderRadius.all(_r),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.facebook_rounded, color: Colors.white, size: 27),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'زيارة صفحة الشركة على فيس بوك',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.open_in_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({required this.size, required this.logoPath});

  final double size;
  final String logoPath;

  static const Color _primary = Color(0xFFFF5A1F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_primary.withOpacity(.16), _primary.withOpacity(.06)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.18),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _primary.withOpacity(.18), width: 1),
        ),
        child: ClipOval(
          child: Image.asset(
            logoPath,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: _primary.withOpacity(.08),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.business_center_rounded,
                  color: _primary,
                  size: 30,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  static const Color _primary = Color(0xFFFF5A1F);
  static const Color _textMute = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted =
        theme.textTheme.bodySmall?.color?.withOpacity(0.8) ?? _textMute;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: muted,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.cardColor,
    required this.textColor,
    required this.mutedColor,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color cardColor;
  final Color textColor;
  final Color mutedColor;

  static const Radius _r = Radius.circular(18);
  static const Color _primary = Color(0xFFFF5A1F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(_r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _primary.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: _primary, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: mutedColor,
                    height: 1.65,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
