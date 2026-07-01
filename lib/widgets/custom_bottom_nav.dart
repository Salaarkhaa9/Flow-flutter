import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: AppTheme.slateDeep.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
          _navItem(Icons.explore_outlined, Icons.explore_rounded, 'Orders', 1),
          _buildCenterButton(),
          _navItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Load', 2),
          _navItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats', 3),
        ],
      ),
    );
  }

  Widget _buildCenterButton() {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.slateDeep,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 22,
            height: 22,
            color: AppTheme.limeVoltage,
            colorBlendMode: BlendMode.srcIn,
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.limeVoltage,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  color: AppTheme.slateDeep,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
      IconData outlinedIcon, IconData filledIcon, String label, int index) {
    final isSelected = index == currentIndex;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              color: isSelected ? AppTheme.slateDeep : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.slateDeep : AppTheme.textMuted,
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
