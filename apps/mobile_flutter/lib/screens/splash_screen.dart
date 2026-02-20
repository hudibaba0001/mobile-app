import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../design/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              Color(0xFF2A2A72),
              AppColors.gradientEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo GIF
              Image.asset(
                'assets/images/kviktime_logo.gif',
                width: 200,
                height: 200,
              )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 800.ms,
                curve: Curves.easeOutBack,
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // Minimal Progress Indicator
              SizedBox(
                width: 160,
                child: const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
              )
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
