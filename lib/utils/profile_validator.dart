import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

Future<void> checkProfileAndNavigate(
    BuildContext context, VoidCallback onComplete) async {
  final auth = AuthService();
  final user = auth.currentUser;
  if (user == null) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) {
    return;
  }
  final emailKey = user.email.toLowerCase();
  final rawEmail = user.email;
  final hasId = prefs.getBool('${emailKey}_id_uploaded') ??
      prefs.getBool('${rawEmail}_id_uploaded') ??
      false;
  final hasCdl = prefs.getBool('${emailKey}_cdl_uploaded') ??
      prefs.getBool('${rawEmail}_cdl_uploaded') ??
      false;
  final cdlOptional = prefs.getBool('${emailKey}_cdl_optional') ??
      prefs.getBool('${rawEmail}_cdl_optional') ??
      false;

  final vehicle = auth.getVehicleProfile(user.id);
  final hasVehicle = vehicle != null;

  if (hasId && (hasCdl || cdlOptional) && hasVehicle) {
    onComplete();
  } else {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon — lime-voltage badge ring
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.slateDeep.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: AppTheme.slateDeep,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Profile Incomplete',
                  style: GoogleFonts.outfit(
                    color: AppTheme.slateDeep,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please complete your profile verification to unlock access to the load board.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Complete Profile button — lime-voltage
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      if (!hasId) {
                        Navigator.pushNamed(context, '/id_upload',
                            arguments: user.email);
                      } else if (!hasCdl) {
                        Navigator.pushNamed(context, '/cdl_upload',
                            arguments: user.email);
                      } else {
                        Navigator.pushNamed(context, '/vehicle_registration',
                            arguments: false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.limeVoltage,
                      foregroundColor: AppTheme.slateDeep,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      'Complete Profile',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
