import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/document_service.dart';
import '../services/api_client.dart';

class CdlUploadScreen extends StatefulWidget {
  /// Email passed from the previous onboarding step.
  final String userEmail;

  const CdlUploadScreen({super.key, required this.userEmail});

  @override
  State<CdlUploadScreen> createState() => _CdlUploadScreenState();
}

class _CdlUploadScreenState extends State<CdlUploadScreen>
    with TickerProviderStateMixin {
  final DocumentService _docService = DocumentService();
  final ImagePicker _picker = ImagePicker();

  // State
  XFile? _frontImage;
  bool _isProcessing = false;
  bool _isUploading = false;
  ParsedDocument? _parsedDoc;
  String _error = '';
  bool _uploadSuccess = false;
  bool _cdlClassWarning = false;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  late AnimationController _cardController;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (picked == null) return;

    setState(() {
      _frontImage = picked;
      _parsedDoc = null;
      _error = '';
      _cdlClassWarning = false;
      _uploadSuccess = false;
    });

    await _runOcr(picked.path);
  }

  Future<void> _runOcr(String path) async {
    setState(() => _isProcessing = true);
    try {
      final text = await _docService.extractTextFromImage(path);
      final parsed = _docService.parseDriversLicense(text);
      setState(() {
        _parsedDoc = parsed;
        _isProcessing = false;
        // Warn if CDL class is found but is not A or B
        if (parsed.cdlClass.isNotEmpty && !parsed.isValidCdlClass) {
          _cdlClassWarning = true;
        }
      });
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  // ── Upload & Complete ──────────────────────────────────────────────────────

  Future<void> _handleComplete() async {
    if (_frontImage == null) {
      setState(() => _error = 'Please capture or upload your CDL.');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = '';
    });

    try {
      final resCdl = await _docService.uploadDocument(
        filePath: _frontImage!.path,
        type: 'drivers_license',
      );
      final urlCdl = resCdl?['fileUrl']?.toString() ?? _frontImage!.path;

      // Save status locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${widget.userEmail.toLowerCase()}_cdl_uploaded', true);
      await prefs.setString('${widget.userEmail.toLowerCase()}_cdl_front_path', urlCdl);

      setState(() {
        _isUploading = false;
        _uploadSuccess = true;
      });
      _checkController.forward();

      // Brief pause, then show success and go to login
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) {
        _showSuccessAndNavigate();
      }
    } on ApiException catch (e) {
      setState(() {
        _isUploading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = 'Upload failed. You can complete this later from your profile.';
      });
    }
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0a2226),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFFd6ff00),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Setup Complete!',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF0a2226),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your documents have been submitted for review. You can now log in and start accepting loads.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF71717A),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a2226).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF0a2226).withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: Color(0xFF0a2226), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Verification within 24 hours',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0a2226),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/vehicle_registration',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd6ff00),
                  foregroundColor: const Color(0xFF0a2226),
                  minimumSize: const Size(double.infinity, 50),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: Text(
                  'Continue to Vehicle Setup',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _skipForNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${widget.userEmail.toLowerCase()}_cdl_optional', true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/vehicle_registration',
    );
  }

  // ── Bottom sheet picker ────────────────────────────────────────────────────

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Upload Your CDL',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF0a2226),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _sheetOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sheetOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0a2226).withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0a2226).withOpacity(0.20)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0a2226), size: 30),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.inter(color: const Color(0xFF0a2226), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: const Color(0xFF0a2226),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    _buildProgressBar(step: 2, total: 3),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Step 2 of 3 — Commercial Driver\'s License',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                              context, 
                              '/id_upload',
                              arguments: widget.userEmail,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        Text(
                          'Upload Your CDL',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'A valid Class A or B CDL is required\nto operate as a truck driver',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Card body ─────────────────────────────────────────────────
            Expanded(
              child: SlideTransition(
                position: _cardSlide,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // CDL info banner
                        _buildCdlInfoBanner(),
                        const SizedBox(height: 24),

                        // Upload zone
                        Text(
                          'CDL Front',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0a2226),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildUploadZone(),
                        const SizedBox(height: 24),

                        // OCR processing
                        if (_isProcessing) _buildOcrProcessing(),

                        // CDL class warning
                        if (_cdlClassWarning && !_isProcessing) _buildClassWarning(),

                        // Parsed fields
                        if (_parsedDoc != null && !_isProcessing)
                          _buildParsedFields(_parsedDoc!),

                        // What we verify section
                        _buildVerificationDetails(),
                        const SizedBox(height: 16),

                        // Error
                        if (_error.isNotEmpty) ...[
                          _buildError(_error),
                          const SizedBox(height: 16),
                        ],

                        // Verification status
                        _buildVerificationBadge(),
                        const SizedBox(height: 24),

                        // Complete button
                        _buildCompleteButton(),
                        const SizedBox(height: 14),

                        // Skip
                        Center(
                          child: TextButton(
                            onPressed:
                                (_isUploading || _uploadSuccess) ? null : _skipForNow,
                            child: Text(
                              'Mark as optional',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF71717A),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildProgressBar({required int step, required int total}) {
    return Row(
      children: List.generate(total, (i) {
        final filled = i < step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: filled ? Colors.white : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCdlInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0a2226).withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0a2226).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded,
              color: Color(0xFF0a2226), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CDL Required for Trucking',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF0a2226),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Class A (combination vehicles) or Class B (heavy single vehicles) required.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF71717A),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _showPickerSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: _frontImage != null
              ? Colors.transparent
              : const Color(0xFF0a2226).withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _frontImage != null
                ? const Color(0xFF0a2226).withOpacity(0.4)
                : const Color(0xFFE4E4E7),
            width: 1.5,
          ),
        ),
        child: _frontImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Licence card icon mockup
                  Container(
                    width: 72,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF0a2226).withOpacity(0.08),
                      border: Border.all(
                          color: const Color(0xFF0a2226).withOpacity(0.15)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.credit_card_rounded,
                        color: Color(0xFF0a2226),
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tap to upload your CDL',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF71717A),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Camera or Gallery',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFA1A1AA),
                      fontSize: 11,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: Image.file(
                      File(_frontImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _showPickerSheet,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOcrProcessing() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0a2226).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0a2226).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFF0a2226)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Reading license details…',
            style: GoogleFonts.inter(
                color: const Color(0xFF0a2226), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildClassWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CDL Class May Be Insufficient',
                  style: GoogleFonts.outfit(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We detected a Class ${_parsedDoc?.cdlClass} license. A Class A or B CDL is required for commercial truck driving. Please verify this is the correct document.',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF71717A), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedFields(ParsedDocument doc) {
    if (!doc.hasData) return const SizedBox.shrink();

    final isValidClass = doc.cdlClass.isEmpty || doc.isValidCdlClass;

    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0a2226).withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0a2226).withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF0a2226), size: 16),
              const SizedBox(width: 6),
              Text(
                'Extracted license details',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0a2226),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...doc.fields.entries.map((e) {
            final isClass = e.key == 'cdlClass';
            final valueColor = isClass && !isValidClass
                ? Colors.orange
                : (isClass ? Colors.green : const Color(0xFF18181B));
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      _fieldLabel(e.key),
                      style: GoogleFonts.inter(
                          color: const Color(0xFF71717A), fontSize: 11),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: [
                        Text(
                          e.value,
                          style: GoogleFonts.inter(
                            color: valueColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isClass && isValidClass) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 14),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _fieldLabel(String key) {
    const labels = {
      'licenseNumber': 'License No.',
      'expiryDate': 'Expires',
      'dateOfBirth': 'Date of Birth',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'cdlClass': 'CDL Class',
      'state': 'State',
    };
    return labels[key] ?? key;
  }

  Widget _buildVerificationDetails() {
    final items = [
      ('License number validity', Icons.numbers_rounded),
      ('Expiry date check', Icons.calendar_today_rounded),
      ('CDL class validation (A/B)', Icons.local_shipping_rounded),
      ('Document authenticity scan', Icons.document_scanner_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What we verify',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0a2226),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a2226).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.$2,
                      color: const Color(0xFF0a2226), size: 14),
                ),
                const SizedBox(width: 10),
                Text(
                  item.$1,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF71717A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.poppins(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) => Transform.scale(
        scale: _frontImage != null ? _pulseAnimation.value : 1.0,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0a2226).withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF0a2226).withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0a2226).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _uploadSuccess
                    ? Icons.check_circle_rounded
                    : Icons.verified_rounded,
                color: _uploadSuccess ? Colors.green : const Color(0xFF0a2226),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uploadSuccess
                        ? 'CDL Submitted'
                        : 'Pending Review',
                    style: GoogleFonts.inter(
                      color: _uploadSuccess
                          ? Colors.green
                          : const Color(0xFF0a2226),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _uploadSuccess
                        ? 'Our team will review your CDL within 24 hours.'
                        : 'Reviewed by our compliance team. Production systems connect to AAMVA-certified verification.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF71717A),
                      fontSize: 11,
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

  Widget _buildCompleteButton() {
    if (_uploadSuccess) {
      return ScaleTransition(
        scale: _checkAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.green.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'CDL Uploaded!',
                style: GoogleFonts.poppins(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isUploading ? null : _handleComplete,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0a2226),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
      child: _isUploading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Complete Setup',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
    );
  }
}
