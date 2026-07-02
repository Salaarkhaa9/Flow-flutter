import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/fuel_log.dart';
import '../services/fuel_service.dart';
import '../services/receipt_ocr_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class FuelLogScreen extends StatefulWidget {
  const FuelLogScreen({super.key});

  @override
  State<FuelLogScreen> createState() => _FuelLogScreenState();
}

class _FuelLogScreenState extends State<FuelLogScreen> {
  final FuelService _fuelService = FuelService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _expenseController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<FuelLog> _logs = [];
  bool _loading = true;
  bool _saving = false;
  bool _gettingLocation = false;
  bool _scanningReceipt = false;
  bool _checkingProfile = true;
  bool _profileComplete = false;
  bool _hasId = false;
  bool _hasCdl = false;
  DateTime _selectedDate = DateTime.now();
  double? _currentLatitude;
  double? _currentLongitude;
  File? _receiptImage;
  ParsedReceipt? _parsedReceipt;
  @override
  void initState() {
    super.initState();
    _checkProfileCompleteness();
    _loadLogs();
  }

  Future<void> _checkProfileCompleteness() async {
    final auth = AuthService();
    final user = auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _checkingProfile = false;
          _profileComplete = false;
        });
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
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

    if (mounted) {
      setState(() {
        _hasId = hasId;
        _hasCdl = hasCdl || cdlOptional;
        _profileComplete = hasId && (hasCdl || cdlOptional) && hasVehicle;
        _checkingProfile = false;
      });
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _loading = true);
    final logs = await _fuelService.getFuelLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _gettingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _gettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _gettingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Reverse geocode to get readable address
      String locationName =
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse'
            '?lat=${position.latitude}&lon=${position.longitude}&format=json&accept-language=en');
        final response =
            await http.get(url, headers: {'User-Agent': 'FlowDriverApp/1.0'});

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final addr = data['address'] as Map<String, dynamic>? ?? {};
          final suburb =
              addr['suburb'] ?? addr['neighbourhood'] ?? addr['village'] ?? '';
          final city = addr['city'] ?? addr['town'] ?? addr['county'] ?? '';
          final parts =
              [suburb, city].where((s) => (s as String).isNotEmpty).toList();
          if (parts.isNotEmpty) {
            locationName = parts.take(2).join(', ');
          }
        }
      } catch (e) {
        // If reverse geocoding fails, keep coordinates as fallback
      }

      if (mounted) {
        setState(() {
          _currentLatitude = position.latitude;
          _currentLongitude = position.longitude;
          _locationController.text = locationName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _receiptImage = File(picked.path);
      _scanningReceipt = true;
      _parsedReceipt = null;
    });

    try {
      final parsed = await ReceiptOcrParser.parse(_receiptImage!);
      if (!mounted) return;
      setState(() {
        _parsedReceipt = parsed;
        _scanningReceipt = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanningReceipt = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR failed: $e')),
      );
    }
  }

  void _applyParsedValues() {
    if (_parsedReceipt == null) return;
    if (_parsedReceipt!.expense != null) {
      _expenseController.text = _parsedReceipt!.expense!.toStringAsFixed(2);
    }
    if (_parsedReceipt!.quantity != null) {
      _quantityController.text = _parsedReceipt!.quantity!.toStringAsFixed(1);
    }
    setState(() {
      _receiptImage = null;
      _parsedReceipt = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt values applied to the form.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearReceipt() {
    setState(() {
      _receiptImage = null;
      _parsedReceipt = null;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0a2226),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveFuelLog() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final log = FuelLog(
      id: 'FL-${DateTime.now().millisecondsSinceEpoch}',
      expense: double.parse(_expenseController.text.trim()),
      quantity: double.parse(_quantityController.text.trim()),
      location: _locationController.text.trim(),
      latitude: _currentLatitude,
      longitude: _currentLongitude,
      date: _selectedDate,
      receiptImagePath: _receiptImage?.path,
    );

    final success = await _fuelService.addFuelLog(log);

    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      _expenseController.clear();
      _quantityController.clear();
      _locationController.clear();
      setState(() {
        _currentLatitude = null;
        _currentLongitude = null;
        _selectedDate = DateTime.now();
        _receiptImage = null;
        _parsedReceipt = null;
      });
      await _loadLogs();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fuel log saved successfully!'),
          backgroundColor: Colors.teal,
        ),
      );
    }
  }

  Future<void> _deleteLog(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Fuel Log?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this fuel log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _fuelService.deleteFuelLog(id);
      if (!mounted) return;
      if (success) {
        await _loadLogs();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fuel log deleted.'),
            backgroundColor: Colors.teal,
          ),
        );
      }
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Color(0xFF18181B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF71717A),
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA1A1AA)),
        filled: true,
        fillColor: const Color(0xFFF4F4F5),
        suffixIcon: suffix,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAFAFA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0a2226)),
        ),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy');

    Widget mainBody = Stack(
      children: [
        Container(
          height: 220,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0a2226), Color(0xFFFAFAFA)],
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0a2226),
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
                          'Fuel Log',
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
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0a2226).withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE4E4E7)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0a2226)
                                          .withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.local_gas_station,
                                        color: Color(0xFF0a2226)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Log Fuel Refill',
                                          style: GoogleFonts.outfit(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF0a2226)),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Record your fuel expenses and location.',
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
                              _buildField(
                                'Expense (PKR/USD)',
                                _expenseController,
                                hint: 'e.g. 150.00',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value.trim()) == null) {
                                    return 'Enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                'Quantity (Liters/Gallons)',
                                _quantityController,
                                hint: 'e.g. 15.20',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value.trim()) == null) {
                                    return 'Enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildField(
                                'Location',
                                _locationController,
                                hint: 'Enter location or use current',
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                suffix: _gettingLocation
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF0a2226),
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.my_location,
                                            color: Color(0xFF0a2226)),
                                        onPressed: _getCurrentLocation,
                                        tooltip: 'Use current location',
                                      ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F4F5),
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: const Color(0xFFE4E4E7)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 18, color: Color(0xFF0a2226)),
                                      const SizedBox(width: 12),
                                      Text(
                                        dateFormat.format(_selectedDate),
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.chevron_right,
                                          size: 18, color: Colors.black54),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // ── Receipt upload section ─────────────
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F4F5),
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: const Color(0xFFE4E4E7)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.receipt_long_outlined,
                                          size: 18,
                                          color: Color(0xFF0a2226),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Paid by card? Upload receipt',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: const Color(0xFF0a2226),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    if (_receiptImage == null) ...[
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _ReceiptSourceButton(
                                              icon: Icons.camera_alt_outlined,
                                              label: 'Camera',
                                              onTap: () => _pickReceiptImage(
                                                  ImageSource.camera),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _ReceiptSourceButton(
                                              icon: Icons.photo_outlined,
                                              label: 'Gallery',
                                              onTap: () => _pickReceiptImage(
                                                  ImageSource.gallery),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.file(
                                              _receiptImage!,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _scanningReceipt
                                                ? Row(
                                                    children: [
                                                      const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              Color(0xFF0a2226),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        'Scanning receipt...',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          color: const Color(0xFF71717A),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : _parsedReceipt != null
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          if (_parsedReceipt!
                                                                  .expense !=
                                                              null)
                                                            Text(
                                                              'Expense: ${_parsedReceipt!.currency ?? 'PKR/USD'} ${_parsedReceipt!.expense!.toStringAsFixed(2)}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ),
                                                          if (_parsedReceipt!
                                                                  .quantity !=
                                                              null)
                                                            Text(
                                                              'Quantity: ${_parsedReceipt!.quantity!.toStringAsFixed(1)} ${_parsedReceipt!.unit ?? 'litres/gallons'}',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ),
                                                          if (_parsedReceipt!
                                                                      .expense ==
                                                                  null &&
                                                              _parsedReceipt!
                                                                      .quantity ==
                                                                  null)
                                                            const Text(
                                                              'Could not read values. Type manually.',
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .orange,
                                                              ),
                                                            ),
                                                        ],
                                                      )
                                                    : const SizedBox(),
                                          ),
                                          if (!_scanningReceipt &&
                                              _parsedReceipt != null &&
                                              (_parsedReceipt!.expense !=
                                                      null ||
                                                  _parsedReceipt!.quantity !=
                                                      null))
                                            TextButton(
                                              onPressed: _applyParsedValues,
                                              child: const Text('Apply'),
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                size: 18,
                                                color: Colors.black54),
                                            onPressed: _clearReceipt,
                                            tooltip: 'Remove',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _saveFuelLog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0a2226),
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text('Save Fuel Log',
                                          style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Fuel History',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0a2226),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child:
                                CircularProgressIndicator(color: Color(0xFF0a2226)),
                          ),
                        ),
                      if (!_loading && _logs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.local_gas_station_outlined,
                                  size: 40, color: Color(0xFF71717A)),
                              const SizedBox(height: 8),
                              Text(
                                'No fuel logs yet',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF71717A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add your first fuel refill above.',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFA1A1AA),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!_loading && _logs.isNotEmpty)
                        ..._logs.map((log) => _buildFuelLogItem(log)),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!_profileComplete) {
      mainBody = Stack(
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
            child: mainBody,
          ),
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 4,
                shadowColor: const Color(0xFF0a2226).withOpacity(0.10),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0a2226).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF0a2226),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Profile Incomplete',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0a2226),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please complete your profile verification to unlock access to the fuel logging feature.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.black54,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            final auth = AuthService();
                            final user = auth.currentUser;
                            if (user != null) {
                              if (!_hasId) {
                                Navigator.pushReplacementNamed(
                                    context, '/id_upload',
                                    arguments: user.email);
                              } else if (!_hasCdl) {
                                Navigator.pushReplacementNamed(
                                    context, '/cdl_upload',
                                    arguments: user.email);
                              } else {
                                Navigator.pushReplacementNamed(
                                    context, '/vehicle_registration',
                                    arguments: false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFd6ff00),
                            foregroundColor: const Color(0xFF0a2226),
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
                          'Go Back',
                          style: GoogleFonts.poppins(
                            color: const Color.fromARGB(97, 0, 0, 0),
                            fontSize: 13,
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
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: mainBody,
    );
  }

  Widget _buildFuelLogItem(FuelLog log) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0a2226).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_gas_station,
                color: Color(0xFF0a2226), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USD ${log.expense.toStringAsFixed(2)}',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0a2226),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.quantity.toStringAsFixed(1)} gallons',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF71717A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Color(0xFF71717A)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        log.location,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF71717A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(log.date),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF71717A),
                  ),
                ),
              ],
            ),
          ),
          if (log.receiptImagePath != null)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0a2226).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 14,
                  color: Color(0xFF0a2226),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => _deleteLog(log.id),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ReceiptOcrParser.dispose();
    _expenseController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

class _ReceiptSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReceiptSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF0a2226)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF71717A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
