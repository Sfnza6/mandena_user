import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/user.dart';

class ProfileViewPage extends StatelessWidget {
  const ProfileViewPage({super.key});

  static const Color _brown = Color(0xFF6F3F17);

  static const Color _textMute = Color(0xFF7A7A85);
  static const Radius _r = Radius.circular(18);

  @override
  Widget build(BuildContext context) {
    final UserModel u = Get.arguments as UserModel;
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor:
              theme.appBarTheme.backgroundColor ?? bgColor,
          centerTitle: true,
          title: Text(
            'عرض البيانات',
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            // هيدر
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
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _brown.withOpacity(.08),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.person_outline,
                      size: 40,
                      color: _brown,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.username,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          u.phone,
                          style: TextStyle(
                            color: _textMute.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // تفاصيل
            _FieldCard(
              title: 'الاسم',
              value: u.username,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 10),
            _FieldCard(
              title: 'رقم الهاتف',
              value: u.phone,
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 10),
            _FieldCard(
              title: 'تاريخ الإنشاء',
              value: (u.createdAt != null) ? u.createdAt!.toString() : 'غير محدد',
              icon: Icons.calendar_month_outlined,
            ),

            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.check_circle_outline, color: _brown),
              label: const Text(
                'تم',
                style: TextStyle(color: _brown, fontWeight: FontWeight.w800),
              ),
              style: TextButton.styleFrom(
                backgroundColor: cardColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  static const Color _textMute = Color(0xFF7A7A85);
  static const Radius _r = Radius.circular(18);
  static const Color _brown = Color(0xFF6F3F17);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    return Container(
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
          const SizedBox(width: 2),
          const SizedBox.shrink(),
          Icon(icon, color: _brown),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  ' ',
                  style: TextStyle(fontSize: 0),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: _textMute,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '— —' : value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
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
