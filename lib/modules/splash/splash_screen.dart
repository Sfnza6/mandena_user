// lib/modules/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'splash_controller.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final AnimationController _nameCtrl;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _nameFade;

  late final AnimationController _loadingCtrl;

  // ignore: unused_field
  late final SplashController _controller;

  static const Color _orange = Color(0xFFFF5A1F);
  static const Color _orangeDark = Color(0xFFFF2D00);
  static const Color _orangeLight = Color(0xFFFF7A3D);

  @override
  void initState() {
    super.initState();

    _controller = Get.put(SplashController(), permanent: false);

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _logoScale = Tween<double>(
      begin: 0.82,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn);

    _nameCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _nameSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _nameCtrl, curve: Curves.easeOutCubic));

    _nameFade = CurvedAnimation(parent: _nameCtrl, curve: Curves.easeIn);

    _loadingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 260));

    if (mounted) {
      _nameCtrl.forward();
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _nameCtrl.dispose();
    _loadingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_orangeLight, _orange, _orangeDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -80,
                right: -60,
                child: _BlurCircle(
                  size: 190,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              Positioned(
                bottom: -110,
                left: -70,
                child: _BlurCircle(
                  size: 240,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Container(
                          width: 132,
                          height: 132,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.16),
                                blurRadius: 28,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/Logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.restaurant_rounded,
                                    color: _orange,
                                    size: 58,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SlideTransition(
                      position: _nameSlide,
                      child: FadeTransition(
                        opacity: _nameFade,
                        child: const Column(
                          children: [
                            Text(
                              'ماندينا',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 7),
                            Text(
                              'تجربة طلب أسهل وأسرع',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 34),

                    FadeTransition(
                      opacity: _nameFade,
                      child: _LoadingDots(controller: _loadingCtrl),
                    ),
                  ],
                ),
              ),

              const Positioned(
                left: 0,
                right: 0,
                bottom: 34,
                child: Text(
                  'Powered by BRAINWARE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
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

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.18;
                final value = ((controller.value - delay) % 1.0);
                final scale = value < 0.5
                    ? 0.75 + (value * 2 * 0.35)
                    : 1.10 - ((value - 0.5) * 2 * 0.35);

                final opacity = value < 0.5
                    ? 0.45 + (value * 2 * 0.55)
                    : 1.0 - ((value - 0.5) * 2 * 0.55);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'جاري تجهيز تجربتك...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
