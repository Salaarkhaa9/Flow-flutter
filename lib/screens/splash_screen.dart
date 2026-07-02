import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/token_service.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _dotOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeIn),
      ),
    );

    _dotOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Run all init work concurrently while the animation plays
    _initialize();
  }

  Future<void> _initialize() async {
    // Run token load and ensure a minimum display time concurrently
    await Future.wait([
      TokenService().load(),
      Future.delayed(const Duration(milliseconds: 1400)),
    ]);

    // Now check auth (needs tokens loaded first)
    final bool loggedIn = await AuthService.tryAutoLogin();

    // Load notifications in background — don't block navigation on it
    NotificationService().load();

    if (!mounted) return;

    // Fade out then navigate
    await _controller.reverse();

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      loggedIn ? '/home' : '/',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.slateDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.limeVoltage.withOpacity(0.12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 68,
                    color: AppTheme.limeVoltage,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FLOW brand text
            AnimatedBuilder(
              animation: _textOpacity,
              builder: (context, child) => Opacity(
                opacity: _textOpacity.value,
                child: child,
              ),
              child: Text(
                'FLOW',
                style: GoogleFonts.outfit(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 10,
                ),
              ),
            ),

            const SizedBox(height: 6),

            AnimatedBuilder(
              animation: _textOpacity,
              builder: (context, child) => Opacity(
                opacity: _textOpacity.value,
                child: child,
              ),
              child: Text(
                'Move Loads. Not Mountains.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white38,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            const SizedBox(height: 64),

            // Loading dots
            AnimatedBuilder(
              animation: _dotOpacity,
              builder: (context, child) => Opacity(
                opacity: _dotOpacity.value,
                child: child,
              ),
              child: const _PulsingDots(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three pulsing dots loading indicator
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final Animation<double> anim = Tween<double>(begin: 0.3, end: 1.0)
            .animate(
              CurvedAnimation(
                parent: _dotsController,
                curve: Interval(
                  i * 0.2,
                  i * 0.2 + 0.5,
                  curve: Curves.easeInOut,
                ),
              ),
            );
        return AnimatedBuilder(
          animation: anim,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Opacity(
              opacity: anim.value,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppTheme.limeVoltage,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
