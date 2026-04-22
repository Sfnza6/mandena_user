// lib/modules/splash/splash_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'splash_controller.dart'; // ✅ تأكد من المسار الصحيح

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // الشعار
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // اسم التطبيق
  late final AnimationController _nameCtrl;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nameFade;

  // 🆕 ربط الكنترولر (هو المسؤول عن التوجيه وفحص التقييد)
  // ignore: unused_field
  late final SplashController _c;

  @override
  void initState() {
    super.initState();
    // تهيئة الكنترولر مرة واحدة
    _c = Get.put(SplashController(), permanent: false);

    _initAnimations();
    // لم نعد بحاجة إلى _decideDestination هنا
  }

  void _initAnimations() {
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(
      begin: .85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);
    _logoCtrl.forward();

    _nameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    );
    _nameSlide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOutBack));
    _nameFade = CurvedAnimation(parent: _nameCtrl, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _nameCtrl.forward();
    });

    // 🛑 حذف الاستماع الذي كان ينفّذ _routeNow
    // _nameCtrl.addStatusListener((status) {
    //   if (status == AnimationStatus.completed) _routeNow();
    // });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFFFFA000);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      'assets/images/Logo.png',
                      width: 120,
                      height: 120,
                      color: brand,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SlideTransition(
                position: _nameSlide,
                child: FadeTransition(
                  opacity: _nameFade,
                  child: const Text(
                    'ماندينا',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
