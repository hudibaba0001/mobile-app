import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium gradient background (Mesh-like feel)
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gradientStart,
              Color(0xFF2A2A72), // Deep Blue/Purple for depth
              AppColors.gradientEnd,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Container with Glass/Glow effect
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neutral50.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.neutral50.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neutral50.withValues(alpha: 0.1),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.access_time_filled_rounded,
                  size: 64,
                  color: AppColors.neutral50.withValues(alpha: 0.95),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.04, 1.04),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              )
              .shimmer(duration: 2000.ms, color: Colors.white24) // Subtle shimmer
              .animate() // Separate animation for entrance
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),

              const SizedBox(height: AppSpacing.xl),

              // Title "KvikTime" with entrance animation
              Text(
                'KvikTime',
                style: GoogleFonts.dmSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral50,
                  letterSpacing: 1.2,
                ),
              )
              .animate()
              .fadeIn(duration: 900.ms, curve: Curves.easeOut)
              .slideY(begin: 0.12, end: 0, duration: 900.ms),

              const SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                'Smart Time Tracking',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.neutral50.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              )
              .animate()
              .fadeIn(delay: 800.ms, duration: 600.ms),

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
              .fadeIn(delay: 1000.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
