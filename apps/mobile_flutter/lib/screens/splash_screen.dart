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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/kviktime_logo.png',
                width: 200,
                height: 200,
              ).animate().fadeIn(duration: 600.ms).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: 700.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ).animate().fadeIn(delay: 520.ms, duration: 360.ms),
            ],
          ),
        ),
      ),
    );
  }
}
