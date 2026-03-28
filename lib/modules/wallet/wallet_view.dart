import 'package:flutter/material.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'المحفظة',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _card(
            title: 'الرصيد الحالي',
            big: '0.00 د.ل',
            sub: 'يمكنك شحن الرصيد قريباً',
          ),
          const SizedBox(height: 12),
          _card(
            title: 'آخر العمليات',
            big: '-',
            sub: 'لا توجد عمليات حتى الآن',
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required String big, String? sub}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            big,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub, style: const TextStyle(color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}
