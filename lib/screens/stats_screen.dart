import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: Stack(
        children: [
          // ── Slate-deep gradient header ────────────────────────────────────
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.slateDeep, AppTheme.surfaceLight],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── App bar ────────────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.slateDeep,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Stats',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ── Coming Soon content ───────────────────────────────────
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon container — slate-deep ring
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: AppTheme.slateDeep.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            size: 52,
                            color: AppTheme.slateDeep,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Coming Soon',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.slateDeep,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your performance stats and\ninsights are on their way.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                            height: 1.6,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/order_history');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/load_board');
          }
        },
      ),
    );
  }
}
