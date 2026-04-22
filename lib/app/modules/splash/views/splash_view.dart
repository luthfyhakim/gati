import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:gati/app/modules/splash/controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Access controller to trigger initialization
    controller.isBusy;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // App Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4DB6AC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.show_chart,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            // App Name
            const Text(
              'Gati',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'Track Your Sport Activity',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const Spacer(),
            // Loading dots
            const _LoadingDots(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_controller.value - delay) % 1.0;
            final opacity = animationValue < 0.5
                ? 0.3 + (animationValue * 1.4)
                : 1.0 - ((animationValue - 0.5) * 1.4);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(
                  0xFF4DB6AC,
                ).withValues(alpha: opacity.clamp(0.3, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
