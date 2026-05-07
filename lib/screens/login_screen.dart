import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB066FE),
              Color(0xFF6A1B9A),
              Colors.black,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Logo icon only — tinted black so it shows on the light gradient top
            Image.asset(
              'assets/logo.png',
              height: 80,
              color: Colors.black,
              colorBlendMode: BlendMode.srcIn,
            ),
            const SizedBox(height: 10),

            // Separate FLOW text — Montserrat Alternates, BLACK on login
            Text(
              'FLOW',
              style: GoogleFonts.montserratAlternates(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Driver App',
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            const Spacer(),

            // White bottom sheet
            Container(
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'LOGIN',
                      style: GoogleFonts.montserratAlternates(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Text('MC number',
                      style: GoogleFonts.poppins(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter mc number...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  Text('Password',
                      style: GoogleFonts.poppins(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Enter password...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.poppins(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 10,
                      shadowColor: AppTheme.primaryPurple.withOpacity(0.5),
                    ),
                    child: Text(
                      'Sign in',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/register'),
                      child: Text(
                        "Don't have an account? Register",
                        style:
                            GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
