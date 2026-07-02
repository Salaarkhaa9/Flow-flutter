import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../models/vehicle_profile.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  final bool isEditing;

  const VehicleRegistrationScreen({super.key, this.isEditing = false});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _VehicleRegistrationScreenState();
}

class _VehicleRegistrationScreenState extends State<VehicleRegistrationScreen> {
  final AuthService _auth = AuthService();
  final GlobalKey<FormState> _vehicleFormKey = GlobalKey<FormState>();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _trailerLengthController =
      TextEditingController();
  final TextEditingController _trailerWidthController = TextEditingController();
  final TextEditingController _trailerHeightController =
      TextEditingController();
  final TextEditingController _maxWeightController = TextEditingController();
  final TextEditingController _internalFleetIdController =
      TextEditingController();
  final TextEditingController _registrationDocumentController =
      TextEditingController();
  final TextEditingController _insuranceDocumentController =
      TextEditingController();

  String? _equipmentType;
  String _registrationDocumentType = 'Image';
  String _insuranceDocumentType = 'PDF';
  XFile? _registrationImage;
  XFile? _insuranceImage;
  String? _registrationPdfPath;
  String? _insurancePdfPath;
  bool _isLoading = false;
  bool _isLoadingVin = false;
  bool _showAllFields = false;
  bool _hasLiftgate = false;
  bool _isHazmatCertified = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingProfile();
    }
  }

  void _loadExistingProfile() {
    final user = _auth.currentUser;
    if (user == null) return;
    final profile = _auth.getVehicleProfile(user.id);
    if (profile == null) return;

    _licensePlateController.text = profile.licensePlate;
    _stateController.text = profile.state;
    _vinController.text = profile.vinNumber;
    _yearController.text = profile.year;
    _makeController.text = profile.make;
    _modelController.text = profile.model;
    _trailerLengthController.text = profile.trailerLength;
    _trailerWidthController.text = profile.trailerWidth;
    _trailerHeightController.text = profile.trailerHeight;
    _maxWeightController.text = profile.maxWeight;
    _internalFleetIdController.text = profile.internalFleetId;
    _registrationDocumentController.text = profile.registrationDocumentLabel;
    _insuranceDocumentController.text = profile.insuranceDocumentLabel;
    _equipmentType = profile.equipmentType;
    _registrationDocumentType = profile.registrationDocumentType;
    _insuranceDocumentType = profile.insuranceDocumentType;
    _showAllFields = true;
  }

  Future<void> _lookupVin() async {
    final vin = _vinController.text.trim();
    if (vin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a VIN first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (vin.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('VIN must be at least 11 characters.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoadingVin = true);

    try {
      final uri = Uri.parse(
        'https://vpic.nhtsa.dot.gov/api/vehicles/decodevin/$vin?format=json',
      );
      final resp = await http.get(uri);
      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        final results = data['Results'] as List;

        String? getValue(String variable) {
          for (final r in results) {
            if (r['Variable'] == variable) {
              final v = (r['Value'] as String?)?.trim() ?? '';
              return v.isNotEmpty ? v : null;
            }
          }
          return null;
        }

        final year = getValue('Model Year');
        final make = getValue('Make');
        final model = getValue('Model');
        final bodyClass = getValue('Body Class');
        final engineCylinders = getValue('Engine Number of Cylinders');
        final displacement = getValue('Displacement (L)');
        final fuelType = getValue('Fuel Type - Primary');
        final plant = getValue('Plant City');
        final manufacturer = getValue('Manufacturer Name');

        if (year == null && make == null && model == null) {
          setState(() => _isLoadingVin = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No vehicle data found for this VIN.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          if (year != null) _yearController.text = year;
          if (make != null) _makeController.text = make;
          if (model != null) _modelController.text = model;
          _isLoadingVin = false;
          _showAllFields = true;
        });

        // Show decoded details in a dialog
        final details = <String>[];
        if (year != null) details.add('Year: $year');
        if (make != null) details.add('Make: $make');
        if (model != null) details.add('Model: $model');
        if (manufacturer != null) details.add('Manufacturer: $manufacturer');
        if (bodyClass != null) details.add('Body: $bodyClass');
        if (engineCylinders != null) details.add('Cylinders: $engineCylinders');
        if (displacement != null) details.add('Displacement: ${displacement}L');
        if (fuelType != null) details.add('Fuel: $fuelType');
        if (plant != null) details.add('Plant: $plant');

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle,
                        color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('VIN Decoded',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vin,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  ...details.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white)),
                      )),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Year, Make & Model fields have been populated.'),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() => _isLoadingVin = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect to NHTSA.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingVin = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveVehicleRegistration() async {
    if (!(_vehicleFormKey.currentState?.validate() ?? false)) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final registrationPath = _registrationDocumentType == 'Image'
        ? _registrationImage?.path
        : _registrationPdfPath;
    final insurancePath = _insuranceDocumentType == 'Image'
        ? _insuranceImage?.path
        : _insurancePdfPath;

    final profile = VehicleProfile(
      equipmentType: _equipmentType ?? '',
      licensePlate: _licensePlateController.text.trim(),
      state: _stateController.text.trim(),
      vinNumber: _vinController.text.trim(),
      year: _yearController.text.trim(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      trailerLength: _trailerLengthController.text.trim(),
      trailerWidth: _trailerWidthController.text.trim(),
      trailerHeight: _trailerHeightController.text.trim(),
      maxWeight: _maxWeightController.text.trim(),
      internalFleetId: '',
      registrationDocumentLabel: _registrationDocumentController.text.trim(),
      registrationDocumentType: _registrationDocumentType,
      insuranceDocumentLabel: _insuranceDocumentController.text.trim(),
      insuranceDocumentType: _insuranceDocumentType,
      registrationDocumentPath: registrationPath,
      insuranceDocumentPath: insurancePath,
      hasLiftgate: _hasLiftgate,
      isHazmatCertified: _isHazmatCertified,
    );

    try {
      final saved =
          await _auth.saveVehicleProfile(userId: user.id, profile: profile);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (saved) {
        // Fire notification
        await NotificationService().notifyVehicleRegistered();
        if (mounted) Navigator.pop(context, true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle registration saved successfully!'),
              backgroundColor: Colors.teal,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    _licensePlateController.clear();
    _stateController.clear();
    _vinController.clear();
    _yearController.clear();
    _makeController.clear();
    _modelController.clear();
    _trailerLengthController.clear();
    _trailerWidthController.clear();
    _trailerHeightController.clear();
    _maxWeightController.clear();
    _internalFleetIdController.clear();
    _registrationDocumentController.clear();
    _insuranceDocumentController.clear();
    setState(() {
      _equipmentType = null;
      _registrationDocumentType = 'Image';
      _insuranceDocumentType = 'PDF';
      _registrationImage = null;
      _insuranceImage = null;
      _registrationPdfPath = null;
      _insurancePdfPath = null;
      _showAllFields = false;
    });
  }

  void _toggleVehicleDocumentType({
    required bool isRegistration,
    required String documentType,
  }) {
    setState(() {
      if (isRegistration) {
        _registrationDocumentType = documentType;
      } else {
        _insuranceDocumentType = documentType;
      }
    });
  }

  Future<void> _pickImageForDocument({required bool isRegistration}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null && mounted) {
      setState(() {
        if (isRegistration) {
          _registrationImage = image;
          _registrationDocumentController.text =
              image.name.isNotEmpty ? image.name : 'registration_image.jpg';
        } else {
          _insuranceImage = image;
          _insuranceDocumentController.text =
              image.name.isNotEmpty ? image.name : 'insurance_image.jpg';
        }
      });
    }
  }

  Future<void> _pickPdfForDocument({required bool isRegistration}) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        final file = result.files.first;
        setState(() {
          if (isRegistration) {
            _registrationPdfPath = file.path;
            _registrationDocumentController.text =
                file.name.isNotEmpty ? file.name : 'registration_document.pdf';
          } else {
            _insurancePdfPath = file.path;
            _insuranceDocumentController.text =
                file.name.isNotEmpty ? file.name : 'insurance_document.pdf';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument({
    required bool isRegistration,
    required String documentType,
  }) async {
    if (documentType == 'Image') {
      await _pickImageForDocument(isRegistration: isRegistration);
    } else {
      await _pickPdfForDocument(isRegistration: isRegistration);
    }
  }

  Widget _buildDocumentTypeButton({
    required bool selected,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? const Color(0xFF0a2226) : const Color(0xFFF4F4F5),
          foregroundColor: selected ? Colors.white : const Color(0xFF71717A),
          side: BorderSide(
              color:
                  selected ? const Color(0xFF0a2226) : const Color(0xFFE4E4E7)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF71717A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildVinLookupButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoadingVin ? null : _lookupVin,
        icon: _isLoadingVin
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.search, size: 18),
        label: Text(
          _isLoadingVin ? 'Looking up...' : 'Lookup',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0a2226),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF0a2226).withOpacity(0.6),
          disabledForegroundColor: Colors.white70,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildVehicleField(
    String label,
    TextEditingController controller, {
    String? hint,
    String? Function(String?)? validator,
    double width = 145,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(color: Color(0xFF18181B), fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF71717A),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
          filled: true,
          fillColor: const Color(0xFFF4F4F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0a2226), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF0a2226) : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE4E4E7),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              color: value ? Colors.white : const Color(0xFF71717A),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: value ? Colors.white : const Color(0xFF71717A),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required TextEditingController controller,
    required String documentType,
    required bool isRegistration,
  }) {
    final hasFile = isRegistration
        ? (_registrationDocumentType == 'Image'
            ? _registrationImage != null
            : _registrationPdfPath != null)
        : (_insuranceDocumentType == 'Image'
            ? _insuranceImage != null
            : _insurancePdfPath != null);

    final fileName = isRegistration
        ? (_registrationDocumentType == 'Image'
            ? (_registrationImage?.name ?? '')
            : (_registrationPdfPath != null
                ? _registrationPdfPath!.split(Platform.pathSeparator).last
                : ''))
        : (_insuranceDocumentType == 'Image'
            ? (_insuranceImage?.name ?? '')
            : (_insurancePdfPath != null
                ? _insurancePdfPath!.split(Platform.pathSeparator).last
                : ''));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0a2226).withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF0a2226)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDocumentTypeButton(
                selected: documentType == 'Image',
                label: 'Image',
                onPressed: () => _toggleVehicleDocumentType(
                    isRegistration: isRegistration, documentType: 'Image'),
              ),
              const SizedBox(width: 10),
              _buildDocumentTypeButton(
                selected: documentType == 'PDF',
                label: 'PDF',
                onPressed: () => _toggleVehicleDocumentType(
                    isRegistration: isRegistration, documentType: 'PDF'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _pickDocument(
                isRegistration: isRegistration, documentType: documentType),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasFile
                      ? const Color(0xFF0a2226).withOpacity(0.4)
                      : const Color(0xFFE4E4E7),
                  width: hasFile ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasFile
                        ? Icons.check_circle
                        : (documentType == 'Image'
                            ? Icons.image_outlined
                            : Icons.picture_as_pdf_outlined),
                    color: hasFile
                        ? const Color(0xFF0a2226)
                        : const Color(0xFF71717A),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasFile
                          ? fileName
                          : 'Upload ${documentType.toLowerCase()} from device',
                      style: TextStyle(
                        color: hasFile
                            ? const Color(0xFF18181B)
                            : const Color(0xFF71717A),
                        fontWeight: hasFile ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.upload_file,
                    color: Color(0xFF0a2226),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (hasFile) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    if (isRegistration) {
                      if (_registrationDocumentType == 'Image') {
                        _registrationImage = null;
                      } else {
                        _registrationPdfPath = null;
                      }
                      _registrationDocumentController.clear();
                    } else {
                      if (_insuranceDocumentType == 'Image') {
                        _insuranceImage = null;
                      } else {
                        _insurancePdfPath = null;
                      }
                      _insuranceDocumentController.clear();
                    }
                  });
                },
                child: const Text(
                  'Remove',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar({required int step, required int total}) {
    return Row(
      children: List.generate(total, (i) {
        final active = i < step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0a2226),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    if (!widget.isEditing) ...[
                      _buildProgressBar(step: 3, total: 3),
                      const SizedBox(height: 20),
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
                              'Step 3 of 3 — Vehicle Registration',
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
                    ],
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
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
                          widget.isEditing
                              ? 'Vehicle Management'
                              : 'Vehicle Registration',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (!widget.isEditing) ...[
                      Text(
                        'Register your vehicle details to start accepting loads',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Form(
                  key: _vehicleFormKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF0a2226).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_shipping_outlined,
                                  color: Color(0xFF0a2226)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Vehicle Details',
                                    style: GoogleFonts.outfit(
                                        color: const Color(0xFF0a2226),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Enter your VIN and tap Lookup to auto-fill details.',
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFF71717A),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // VIN lookup row (always visible)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: _buildVehicleField(
                                'VIN Number',
                                _vinController,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                width: double.infinity,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _buildVinLookupButton(),
                          ],
                        ),
                        if (_showAllFields) ...[
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 145,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: _equipmentType,
                                  hint: const Text(
                                    'Not Selected',
                                    style: TextStyle(
                                        color: Color(0xFFA1A1AA), fontSize: 14),
                                  ),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                      color: Color(0xFF18181B),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400),
                                  decoration: InputDecoration(
                                    labelText: 'Equipment Type',
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF71717A),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF4F4F5),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE4E4E7)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE4E4E7)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF0a2226), width: 1.5),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'Flatbed',
                                        child: Text('Flatbed',
                                            style: TextStyle(
                                                color: Color(0xFF18181B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400))),
                                    DropdownMenuItem(
                                        value: 'Dry Van',
                                        child: Text('Dry Van',
                                            style: TextStyle(
                                                color: Color(0xFF18181B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400))),
                                    DropdownMenuItem(
                                        value: 'Reefer',
                                        child: Text('Reefer',
                                            style: TextStyle(
                                                color: Color(0xFF18181B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400))),
                                    DropdownMenuItem(
                                        value: 'Step Deck',
                                        child: Text('Step Deck',
                                            style: TextStyle(
                                                color: Color(0xFF18181B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400))),
                                    DropdownMenuItem(
                                        value: 'Other',
                                        child: Text('Other',
                                            style: TextStyle(
                                                color: Color(0xFF18181B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400))),
                                  ],
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() => _equipmentType = value);
                                  },
                                ),
                              ),
                              _buildVehicleField(
                                'License Plate',
                                _licensePlateController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (!RegExp(r'^[a-zA-Z0-9]+$')
                                      .hasMatch(value.trim())) {
                                    return 'Alphanumeric only';
                                  }
                                  return null;
                                },
                              ),
                              _buildVehicleField(
                                'Year',
                                _yearController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                              _buildVehicleField(
                                'Make',
                                _makeController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                              _buildVehicleField(
                                'Model',
                                _modelController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                              _buildVehicleField(
                                'Max Weight (lbs)',
                                _maxWeightController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (!RegExp(r'^\d{1,7}$')
                                      .hasMatch(value.trim())) {
                                    return 'Invalid Weight';
                                  }
                                  return null;
                                },
                              ),
                              _buildVehicleField(
                                'Trailer Length (ft)',
                                _trailerLengthController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (!RegExp(r'^\d{1,4}$')
                                      .hasMatch(value.trim())) {
                                    return 'Invalid Length';
                                  }
                                  return null;
                                },
                              ),
                              _buildVehicleField(
                                'Trailer Width (ft)',
                                _trailerWidthController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (!RegExp(r'^\d{1,3}$')
                                      .hasMatch(value.trim())) {
                                    return 'Invalid width';
                                  }
                                  return null;
                                },
                              ),
                              _buildVehicleField(
                                'Trailer Height (ft)',
                                _trailerHeightController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (!RegExp(r'^\d{1,3}$')
                                      .hasMatch(value.trim())) {
                                    return 'Invalid height';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildToggleChip(
                                  label: 'Liftgate',
                                  value: _hasLiftgate,
                                  onChanged: (v) =>
                                      setState(() => _hasLiftgate = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildToggleChip(
                                  label: 'Hazmat Certified',
                                  value: _isHazmatCertified,
                                  onChanged: (v) =>
                                      setState(() => _isHazmatCertified = v),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 18),
                        Text(
                          'Documents',
                          style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0a2226)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Vehicle registration and insurance can be added as either an image or a PDF.',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF71717A), fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        _buildDocumentSection(
                          title: 'Vehicle Registration',
                          controller: _registrationDocumentController,
                          documentType: _registrationDocumentType,
                          isRegistration: true,
                        ),
                        const SizedBox(height: 14),
                        _buildDocumentSection(
                          title: 'Insurance Certificate',
                          controller: _insuranceDocumentController,
                          documentType: _insuranceDocumentType,
                          isRegistration: false,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _resetForm,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF71717A),
                                  side: const BorderSide(
                                      color: Color(0xFFE4E4E7)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                ),
                                child: const Text('Reset'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _saveVehicleRegistration,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0a2226),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Save Vehicle'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    if (AuthService().isLoggedIn()) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/home',
                                        (route) => false,
                                      );
                                    } else {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/login',
                                        (route) => false,
                                      );
                                    }
                                  },
                            child: Text(
                              'Skip for now — Complete Verification later',
                              style: GoogleFonts.inter(
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

  @override
  void dispose() {
    _licensePlateController.dispose();
    _stateController.dispose();
    _vinController.dispose();
    _yearController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _trailerLengthController.dispose();
    _trailerWidthController.dispose();
    _trailerHeightController.dispose();
    _maxWeightController.dispose();
    _internalFleetIdController.dispose();
    _registrationDocumentController.dispose();
    _insuranceDocumentController.dispose();
    super.dispose();
  }
}
