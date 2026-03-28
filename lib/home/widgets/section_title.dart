import 'package:flutter/material.dart';
import 'home_ui.dart';

class SectionTitleRow extends StatelessWidget {
  const SectionTitleRow({
    super.key,
    required this.title,
    this.buttonText = 'عرض الكل',
    this.onTap,
    this.showAction = true,
  });

  final String title;
  final String buttonText;
  final VoidCallback? onTap;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: HomeUi.kTextMain,
                letterSpacing: -.3,
              ),
            ),
          ),
          if (showAction && onTap != null)
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    color: HomeUi.kPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
