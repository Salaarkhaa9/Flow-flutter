import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: AppTheme.slateDeep,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Lime glow circle behind logo
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.limeVoltage.withOpacity(0.12),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 64,
                      color: AppTheme.limeVoltage,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // FLOW brand text
                Text(
                  'FLOW',
                  style: GoogleFonts.outfit(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 10,
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'Move Loads',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Not Mountains.',
                  style: GoogleFonts.outfit(
                    color: AppTheme.limeVoltage,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),

                const Spacer(),

                Text(
                  'Simplifying freight life-cycle\nfrom booking to delivery',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),

                // Login button — white pill
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.slateDeep,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Login',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Register button — lime-voltage pill
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.limeVoltage,
                      foregroundColor: AppTheme.slateDeep,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
