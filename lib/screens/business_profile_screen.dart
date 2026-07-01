import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../models/vehicle_profile.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final AuthService _auth = AuthService();
  
  bool _isLoading = true;
  bool _idUploaded = false;
  String? _idFrontPath;
  String? _idBackPath;

  bool _cdlUploaded = false;
  String? _cdlFrontPath;

  VehicleProfile? _vehicleProfile;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfileData();
  }

  Future<void> _loadBusinessProfileData() async {
    setState(() => _isLoading = true);
    
    final user = _auth.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      _idUploaded = prefs.getBool('${user.email}_id_uploaded') ?? false;
      _idFrontPath = prefs.getString('${user.email}_id_front_path');
      _idBackPath = prefs.getString('${user.email}_id_back_path');

      _cdlUploaded = prefs.getBool('${user.email}_cdl_uploaded') ?? false;
      _cdlFrontPath = prefs.getString('${user.email}_cdl_front_path');

      _vehicleProfile = _auth.getVehicleProfile(user.id);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDocPreview(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF71717A), size: 28),
              const SizedBox(height: 8),
              Text(
                'No image preview available',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF71717A)),
              ),
            ],
          ),
        ),
      );
    }

    final isUrl = path.startsWith('http');
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: isUrl
            ? Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(path),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(path),
              ),
      ),
    );
  }

  Widget _buildPlaceholder(String path) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_present_rounded, color: Color(0xFF0a2226), size: 28),
            const SizedBox(height: 6),
            Text(
              path.split('/').last,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF0a2226), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool complete, {String activeText = 'Uploaded', String inactiveText = 'Pending'}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: complete
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: complete ? const Color(0xFFC8E6C9) : const Color(0xFFFFE0B2),
        ),
      ),
      child: Text(
        complete ? activeText : inactiveText,
        style: GoogleFonts.inter(
          color: complete ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? trailingHeader,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0a2226).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0a2226),
                ),
              ),
              if (trailingHeader != null) trailingHeader,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF71717A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: GoogleFonts.inter(
                color: const Color(0xFF18181B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Header Background Gradient
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0a2226),
                  Color(0xFFFAFAFA),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Header bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0a2226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Business Profile',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _loadBusinessProfileData,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content list
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF0a2226)),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                          child: Column(
                            children: [
                              // ── 1. GOVERNMENT ID CARD ────────────────────
                              _buildSectionCard(
                                title: 'Government ID',
                                trailingHeader: _buildStatusBadge(_idUploaded),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_idUploaded) ...[
                                      Text(
                                        'Front Side:',
                                        style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0a2226)),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildDocPreview(_idFrontPath),
                                      if (_idBackPath != null && _idBackPath!.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        Text(
                                          'Back Side:',
                                          style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF0a2226)),
                                        ),
                                        const SizedBox(height: 6),
                                        _buildDocPreview(_idBackPath),
                                      ],
                                    ] else ...[
                                      Center(
                                        child: Text(
                                          'No Government ID document uploaded.',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF71717A),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // ── 2. DRIVER\'S LICENSE / CDL CARD ──────────
                              _buildSectionCard(
                                title: 'Driver\'s License & CDL',
                                trailingHeader: _buildStatusBadge(_cdlUploaded),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_cdlUploaded) ...[
                                      Text(
                                        'License Front Side:',
                                        style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0a2226)),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildDocPreview(_cdlFrontPath),
                                    ] else ...[
                                      Center(
                                        child: Text(
                                          'No Driver\'s License / CDL document uploaded.',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF71717A),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // ── 3. VEHICLE REGISTRATION INFO ──────────────
                              _buildSectionCard(
                                title: 'Vehicle Registration Info',
                                trailingHeader: _buildStatusBadge(
                                  _vehicleProfile != null,
                                  activeText: 'Registered',
                                  inactiveText: 'Not Setup',
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_vehicleProfile != null) ...[
                                      _buildInfoRow('Equipment Type', _vehicleProfile!.equipmentType),
                                      _buildInfoRow('License Plate', _vehicleProfile!.licensePlate),
                                      _buildInfoRow('Plate State', _vehicleProfile!.state),
                                      _buildInfoRow('VIN Number', _vehicleProfile!.vinNumber),
                                      _buildInfoRow('Year', _vehicleProfile!.year),
                                      _buildInfoRow('Make', _vehicleProfile!.make),
                                      _buildInfoRow('Model', _vehicleProfile!.model),
                                      _buildInfoRow('Trailer Length', '${_vehicleProfile!.trailerLength} ft'),
                                      _buildInfoRow('Trailer Width', '${_vehicleProfile!.trailerWidth} in'),
                                      _buildInfoRow('Trailer Height', '${_vehicleProfile!.trailerHeight} in'),
                                      _buildInfoRow('Max Load Weight', '${_vehicleProfile!.maxWeight} lbs'),
                                      _buildInfoRow('Fleet ID', _vehicleProfile!.internalFleetId),
                                      _buildInfoRow('Registration Doc', _vehicleProfile!.registrationDocumentLabel),
                                      _buildInfoRow('Insurance Policy', _vehicleProfile!.insuranceDocumentLabel),
                                    ] else ...[
                                      Center(
                                        child: Text(
                                          'No vehicle profile registered.',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF71717A),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
