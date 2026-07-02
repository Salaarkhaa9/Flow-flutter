import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _error = '';
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top header section (slate-deep) ──────────────────────────
            Container(
              width: double.infinity,
              color: AppTheme.slateDeep,
              padding: const EdgeInsets.fromLTRB(30, 60, 30, 36),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.limeVoltage.withOpacity(0.12),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/logo.png',
                        height: 40,
                        color: AppTheme.limeVoltage,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'FLOW',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Driver Portal',
                    style: GoogleFonts.inter(
                      color: AppTheme.limeVoltage,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // ── White form section ────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create account',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slateDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Join the FLOW driver network',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // First Name
                  _buildFieldLabel('First Name'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _firstNameController,
                    hint: 'Enter your first name',
                    icon: Icons.person_outline,
                    errorText: _firstNameError,
                  ),
                  const SizedBox(height: 16),

                  // Last Name
                  _buildFieldLabel('Last Name'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _lastNameController,
                    hint: 'Enter your last name',
                    icon: Icons.person_outline,
                    errorText: _lastNameError,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildFieldLabel('Email'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Enter your email address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _emailError,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _buildFieldLabel('Password'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Create a password (min. 8 chars)',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  _buildFieldLabel('Confirm Password'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    hint: 'Re-enter your password',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),

                  // Error banner
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.slateDeep,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                        disabledBackgroundColor: AppTheme.textMuted,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login link
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                              color: AppTheme.textSecondary, fontSize: 14),
                          children: [
                            const TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Login',
                              style: GoogleFonts.outfit(
                                color: AppTheme.slateDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        color: AppTheme.slateDeep,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      enabled: !_isLoading,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14),
        errorText: errorText,
        filled: true,
        fillColor: AppTheme.surfaceMid,
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppTheme.slateDeep, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _error = '';
      _isLoading = true;
    });

    final rawFirstName = _firstNameController.text;
    final rawLastName = _lastNameController.text;
    final rawEmail = _emailController.text;
    final pwd = _passwordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();

    bool hasValidationError = false;

    // Check empty fields first
    if (rawFirstName.trim().isEmpty) {
      setState(() {
        _firstNameError = 'First name is required';
        hasValidationError = true;
      });
    }

    if (rawEmail.trim().isEmpty) {
      setState(() {
        _emailError = 'Email is required';
        hasValidationError = true;
      });
    }

    // Name validation - alphabets only (no spaces, special chars, or integers)
    final nameRegex = RegExp(r'^[a-zA-Z]+$');

    if (rawFirstName.isNotEmpty && !nameRegex.hasMatch(rawFirstName)) {
      setState(() {
        _firstNameError = 'only alphabets are allowed';
        hasValidationError = true;
      });
    }

    if (rawLastName.isNotEmpty && !nameRegex.hasMatch(rawLastName)) {
      setState(() {
        _lastNameError = 'only alphabets are allowed';
        hasValidationError = true;
      });
    }

    // Email validation
    if (rawEmail.isNotEmpty && !rawEmail.contains('@')) {
      setState(() {
        _emailError = '@ is not mentioned';
        hasValidationError = true;
      });
    } else if (rawEmail.isNotEmpty && !rawEmail.contains('.')) {
      setState(() {
        _emailError = 'Please enter a valid email address';
        hasValidationError = true;
      });
    }

    if (pwd.isEmpty || confirmPwd.isEmpty) {
      setState(() {
        _error = 'Please fill all required fields';
        _isLoading = false;
      });
      return;
    }

    if (hasValidationError) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (pwd.length < 8) {
      setState(() {
        _error = 'Password must be at least 8 characters';
        _isLoading = false;
      });
      return;
    }

    if (pwd != confirmPwd) {
      setState(() {
        _error = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    try {
      final registered = await _authService.register(
        firstName: rawFirstName.trim(),
        lastName: rawLastName.trim(),
        email: rawEmail.trim(),
        password: pwd,
      );
      if (registered) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('just_registered', true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:  Text('Account created! Let\'s verify your identity.'),
              backgroundColor: AppTheme.slateDeep,
            ),
          );
          Navigator.pushReplacementNamed(
            context,
            '/otp_verification',
            arguments: rawEmail.trim(),
          );
        }
      } else {
        setState(() {
          _error = 'Registration failed. Please try again.';
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Connection error. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
