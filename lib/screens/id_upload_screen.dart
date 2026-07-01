import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/document_service.dart';
import '../services/api_client.dart';

class IdUploadScreen extends StatefulWidget {
  /// Email passed from registration (for display purposes).
  final String userEmail;

  const IdUploadScreen({super.key, required this.userEmail});

  @override
  State<IdUploadScreen> createState() => _IdUploadScreenState();
}

class _IdUploadScreenState extends State<IdUploadScreen>
    with TickerProviderStateMixin {
  final DocumentService _docService = DocumentService();
  final ImagePicker _picker = ImagePicker();

  // State
  XFile? _frontImage;
  XFile? _backImage;
  bool _isProcessing = false;
  bool _isUploading = false;
  ParsedDocument? _parsedDoc;
  String _error = '';
  bool _uploadSuccess = false;

  String _selectedIdType = 'State ID';
  final List<String> _idTypes = ['State ID', 'Driver\'s License'];

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  // ── Image picking ──────────────────────────────────────────────────────────

  Future<void> _pickImage({required bool isFront, required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 1920,
    );
    if (picked == null) return;

    setState(() {
      if (isFront) {
        _frontImage = picked;
      } else {
        _backImage = picked;
      }
      _parsedDoc = null;
      _error = '';
      _uploadSuccess = false;
    });

    // Auto-run OCR on front image
    if (isFront) {
      await _runOcr(picked.path);
    }
  }

  Future<void> _runOcr(String path) async {
    setState(() => _isProcessing = true);
    try {
      final text = await _docService.extractTextFromImage(path);
      final parsed = _docService.parseGovernmentId(text);
      setState(() {
        _parsedDoc = parsed;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        // OCR failed — user can still proceed manually
      });
    }
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> _handleUpload() async {
    if (_frontImage == null) {
      setState(() => _error = 'Please capture or upload the front of your ID.');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = '';
    });

    try {
      final resFront = await _docService.uploadDocument(
        filePath: _frontImage!.path,
        type: 'government_id',
      );
      final urlFront = resFront?['fileUrl']?.toString() ?? _frontImage!.path;

      // Upload back too if provided
      String? urlBack;
      if (_backImage != null) {
        final resBack = await _docService.uploadDocument(
          filePath: _backImage!.path,
          type: 'government_id_back',
        );
        urlBack = resBack?['fileUrl']?.toString() ?? _backImage!.path;
      }

      // Save status locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${widget.userEmail}_id_uploaded', true);
      await prefs.setString('${widget.userEmail}_id_front_path', urlFront);
      if (urlBack != null) {
        await prefs.setString('${widget.userEmail}_id_back_path', urlBack);
      }

      setState(() {
        _isUploading = false;
        _uploadSuccess = true;
      });
      _checkController.forward();

      // Brief pause then navigate
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/cdl_upload',
          arguments: widget.userEmail,
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _isUploading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _error = 'Upload failed. You can skip and upload later from your profile.';
      });
    }
  }

  void _skipForNow() {
    Navigator.pushReplacementNamed(
      context,
      '/cdl_upload',
      arguments: widget.userEmail,
    );
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  void _showPickerSheet({required bool isFront}) {
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
                isFront ? 'Upload Front of ID' : 'Upload Back of ID',
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
                        _pickImage(isFront: isFront, source: ImageSource.camera);
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
                        _pickImage(isFront: isFront, source: ImageSource.gallery);
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
                    // Progress bar
                    _buildProgressBar(step: 1, total: 3),
                    const SizedBox(height: 20),
                    // Step label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Step 1 of 3 — Government ID',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Verify Your Identity',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upload a clear photo of your\ngovernment-issued ID',
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
                      // ID type selector
                      Text(
                        'Document Type',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0a2226),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildIdTypeSelector(),
                      const SizedBox(height: 24),

                      // Front image upload
                      Text(
                        'Front Side',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0a2226),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildUploadZone(
                        image: _frontImage,
                        label: 'Tap to capture front of ID',
                        isFront: true,
                      ),
                      const SizedBox(height: 16),

                      // Back image upload
                      Text(
                        'Back Side (Optional)',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0a2226),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildUploadZone(
                        image: _backImage,
                        label: 'Tap to capture back of ID',
                        isFront: false,
                      ),
                      const SizedBox(height: 24),

                      // OCR processing indicator
                      if (_isProcessing) _buildOcrProcessing(),

                      // Parsed data display
                      if (_parsedDoc != null && !_isProcessing)
                        _buildParsedFields(_parsedDoc!),

                      // Error
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildError(_error),
                      ],

                      const SizedBox(height: 24),

                      // Verification notice
                      _buildVerificationNotice(),
                      const SizedBox(height: 24),

                      // Upload button
                      _buildUploadButton(),
                      const SizedBox(height: 14),

                      // Skip
                      Center(
                        child: TextButton(
                          onPressed: (_isUploading || _uploadSuccess) ? null : _skipForNow,
                          child: Text(
                            'Skip for now',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF71717A),
                              fontSize: 13,
                            ),
                          ),
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
    );
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildProgressBar({required int step, required int total}) {
    return Row(
      children: List.generate(total, (i) {
        final active = i < step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIdTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        children: _idTypes.map((type) {
          final selected = _selectedIdType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIdType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0a2226)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  type,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : const Color(0xFF71717A),
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUploadZone({
    required XFile? image,
    required String label,
    required bool isFront,
  }) {
    return GestureDetector(
      onTap: () => _showPickerSheet(isFront: isFront),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: image != null
              ? Colors.transparent
              : const Color(0xFF0a2226).withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: image != null
                ? const Color(0xFF0a2226).withOpacity(0.4)
                : const Color(0xFFE4E4E7),
            width: 1.5,
          ),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a2226).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      color: Color(0xFF0a2226),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
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
                      File(image.path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Overlay edit button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _showPickerSheet(isFront: isFront),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
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
            'Scanning document…',
            style: GoogleFonts.inter(
              color: const Color(0xFF0a2226),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedFields(ParsedDocument doc) {
    if (!doc.hasData) return const SizedBox.shrink();

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
                'Extracted from document',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0a2226),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...doc.fields.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        _fieldLabel(e.key),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF71717A),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        e.value,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF18181B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _fieldLabel(String key) {
    const labels = {
      'idNumber': 'ID Number',
      'licenseNumber': 'License No.',
      'expiryDate': 'Expires',
      'dateOfBirth': 'Date of Birth',
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'cdlClass': 'Class',
      'state': 'State',
    };
    return labels[key] ?? key;
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

  Widget _buildVerificationNotice() {
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
                    : Icons.verified_user_rounded,
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
                        ? 'Document Received'
                        : 'Verification Pending',
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
                        ? 'Your document is queued for review by our team.'
                        : 'Documents are reviewed within 24 hours. You may continue setting up your account.',
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

  Widget _buildUploadButton() {
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
                'Uploaded Successfully',
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
      onPressed: _isUploading ? null : _handleUpload,
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
                const Icon(Icons.upload_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Upload & Continue',
                  style: GoogleFonts.outfit(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
    );
  }
}
