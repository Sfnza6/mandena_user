import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class DevelopersViewPage extends StatelessWidget {
  const DevelopersViewPage({super.key});

  static const Color _brown = Color(0xFF6F3F17);

  static const Color _textMute = Color(0xFF7A7A7F);
  static const Radius _r = Radius.circular(18);

  void _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('تم النسخ', text, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final muted =
        theme.textTheme.bodySmall?.color?.withOpacity(0.75) ?? _textMute;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: theme.appBarTheme.backgroundColor ?? bgColor,
          centerTitle: true,
          title: Text(
            'مطوّرو البرنامج',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          iconTheme: IconThemeData(
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // نبذة الشركة
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.all(_r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _brown.withOpacity(.10),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: _brown,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Brainware',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'نحن Brainware — فريق هندسة برمجيات يبتكر حلولاً عملية وأنيقة للأعمال. '
                          'قمنا بتصميم وتطوير تطبيق EVORANTA من الصفر: واجهات سلسة، تجربة مستخدم مدروسة، وربط متكامل مع الخادم وقواعد البيانات. '
                          'نؤمن بالجودة، والسرعة، والدعم المستمر لضمان نجاح مشروعك على أرض الواقع.',
                          style: TextStyle(color: muted, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // من خدم التطبيق
            const _SectionHeader('من خدم التطبيق'),
            _DevCard(
              name: 'فتح الله خالد',
              role: 'مهندس برمجيات',
              phone: '0945198888',
              onCopy: _copy,
            ),
            const SizedBox(height: 10),
            _DevCard(
              name: 'عبدالرحيم خالد',
              role: 'مهندس برمجيات',
              phone: '0945098888',
              onCopy: _copy,
            ),
            const SizedBox(height: 10),
            _DevCard(
              name: 'عبدالله الصالحين',
              role: 'مهندس برمجيات',
              phone: '0942398149',
              onCopy: _copy,
            ),

            const SizedBox(height: 18),

            // رسالة قصيرة عن أسلوب العمل
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.all(_r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.04),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                'أسلوبنا: نهتم بالتفاصيل الصغيرة التي تصنع الفرق — من الأداء والاستقرار إلى سهولة الاستخدام ودقة الهوية البصرية. '
                'هدفنا تقديم منتج يعبّر عن علامتك ويكبر مع نموّ أعمالك.',
                style: TextStyle(color: muted, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  static const Color _textMute = Color(0xFF7A7A7F);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted =
        theme.textTheme.bodySmall?.color?.withOpacity(0.8) ?? _textMute;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(
        text,
        style: TextStyle(color: muted, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _DevCard extends StatelessWidget {
  const _DevCard({
    required this.name,
    required this.role,
    required this.phone,
    required this.onCopy,
  });

  final String name;
  final String role;
  final String phone;
  final void Function(String) onCopy;

  static const Color _textMute = Color(0xFF7A7A7F);
  static const Radius _r = Radius.circular(18);
  static const Color _brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return InkWell(
      onLongPress: () => onCopy(phone),
      borderRadius: const BorderRadius.all(_r),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.all(_r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _brown.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.engineering_rounded, color: _brown),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(role, style: const TextStyle(color: _textMute)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
