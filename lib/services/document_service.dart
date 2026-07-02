import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'api_client.dart';

/// Handles document upload and on-device OCR extraction.
///
/// Production note: In a production system, the [uploadDocument] result would
/// be sent to an eKYC provider (e.g. Stripe Identity or iDenfy) which holds
/// an AAMVA licence and can verify the document against official DMV records.
/// The backend would receive a webhook with the verification result and update
/// the driver's account status accordingly.
class DocumentService {
  static final DocumentService _instance = DocumentService._internal();
  factory DocumentService() => _instance;
  DocumentService._internal();

  final ApiClient _api = ApiClient();

  // ── Upload ─────────────────────────────────────────────────────────────────

  /// Uploads a document image (or PDF) to the backend.
  ///
  /// [filePath]  – absolute path to the local file.
  /// [type]      – one of: `government_id`, `drivers_license`.
  ///
  /// Returns the server response data on success, or null on failure.
  Future<Map<String, dynamic>?> uploadDocument({
    required String filePath,
    required String type,
  }) async {
    try {
      final data = await _api.uploadFile(
        '/documents/upload',
        filePath: filePath,
        fields: {'type': type},
      );
      if (data != null && data is Map<String, dynamic>) {
        return data;
      }
      return null;
    } on ApiException catch (e) {
      debugPrint('Document upload error ($type): $e');
      rethrow;
    } catch (e) {
      debugPrint('Document upload error ($type): $e');
      return null;
    }
  }

  // ── OCR ────────────────────────────────────────────────────────────────────

  /// Runs on-device OCR on [imagePath] and returns the raw recognised text.
  /// Uses Google ML Kit Text Recognition (Latin script).
  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final RecognizedText result = await textRecognizer.processImage(inputImage);
      return result.text;
    } finally {
      textRecognizer.close();
    }
  }

  // ── Parsers ────────────────────────────────────────────────────────────────

  /// Parses common US driver's license fields from raw OCR text.
  ///
  /// Fields attempted: licenseNumber, expiryDate, dateOfBirth, firstName,
  /// lastName, cdlClass, state.
  ParsedDocument parseDriversLicense(String rawText) {
    final fields = <String, String>{};

    // License / DL number (formats vary by state, e.g. A1234567, 1234567, etc.)
    final dlNumber = _firstMatch(
        rawText, [r'(?:DL|LIC(?:ENSE)?[#\s:]*|NO\s*[.:]?\s*)([A-Z0-9]{5,12})']);
    if (dlNumber != null) fields['licenseNumber'] = dlNumber;

    // Expiry date
    final expiry = _firstMatch(rawText, [
      r'(?:EXP(?:IRES?)?|EXPIRATION)[:\s]*(\d{2}[/\-]\d{2}[/\-]\d{2,4})',
      r'(\d{2}[/\-]\d{2}[/\-]\d{4})',
    ]);
    if (expiry != null) fields['expiryDate'] = expiry;

    // Date of birth
    final dob = _firstMatch(rawText, [
      r'(?:DOB|DATE OF BIRTH|BIRTH(?:DATE)?)[:\s]*(\d{2}[/\-]\d{2}[/\-]\d{2,4})',
    ]);
    if (dob != null) fields['dateOfBirth'] = dob;

    // CDL class (A, B, or C — A/B required for commercial trucking)
    final cdlClass = _firstMatch(rawText, [
      r'CLASS\s*[:\s]*([ABC](?:\s*,\s*[ABC])*)',
      r'\bCLASS-?([ABC])\b',
    ]);
    if (cdlClass != null) fields['cdlClass'] = cdlClass.trim();

    // State abbreviation (look for 2-letter uppercase word on its own line)
    final state = _firstMatch(rawText, [
      r'(?:STATE|ST)[:\s]*([A-Z]{2})\b',
      r'^([A-Z]{2})\s*DRIVER',
    ]);
    if (state != null) fields['state'] = state;

    // Name lines — many licenses put LAST,FIRST or separate lines
    final nameLine = _firstMatch(rawText, [
      r'(?:1\s+)?([A-Z]+),\s*([A-Z]+)',
    ]);
    if (nameLine != null) {
      // Already captured groups — re-extract
      final nameMatch = RegExp(r'([A-Z]+),\s*([A-Z]+)').firstMatch(rawText);
      if (nameMatch != null) {
        fields['lastName'] = nameMatch.group(1) ?? '';
        fields['firstName'] = nameMatch.group(2) ?? '';
      }
    }

    return ParsedDocument(type: 'drivers_license', fields: fields, rawText: rawText);
  }

  /// Parses Pakistani CNIC / Driving License fields from raw OCR text.
  ParsedDocument parseGovernmentId(String rawText) {
    final fields = <String, String>{};

    // ── Pakistani CNIC "Identity Number" (format: 12345-1234567-1 or 13 digits) ──
    final cnicNumber = _firstMatch(rawText, [
      // Standard CNIC format with optional spaces around dashes
      r'(\d{5}\s*-\s*\d{7}\s*-\s*\d)',
      // 13 digits (Pakistani CNIC length)
      r'\b(\d{13})\b',
      // Labelled fallback
      r'Identity\s+Number[\s\n]*[:\-]*\s*([A-Z0-9\-]{9,17})',
    ]);
    if (cnicNumber != null) {
      fields['idNumber'] = cnicNumber.replaceAll(RegExp(r'\s+'), '');
    }

    // ── Name (line after "Name") ──
    final nameMatch = RegExp(
      r'Name\s*\n\s*([^\r\n]+)',
      caseSensitive: false,
    ).firstMatch(rawText);
    if (nameMatch != null) {
      fields['firstName'] = nameMatch.group(1)?.trim() ?? '';
    }

    // ── Date of Expiry ──
    final expiry = _firstMatch(rawText, [
      r'Date\s+of\s+Expiry[:\s]*(\d{2}[.\-/]\d{2}[.\-/]\d{4})',
      r'(?:Expiry|EXP(?:IRES?)?|EXPIRATION)[:\s]*(\d{2}[.\-/]\d{2}[.\-/]\d{4})',
    ]);
    if (expiry != null) fields['expiryDate'] = expiry;

    return ParsedDocument(type: 'government_id', fields: fields, rawText: rawText);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String? _firstMatch(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final m = RegExp(pattern, caseSensitive: false, multiLine: true).firstMatch(text);
      if (m != null && m.groupCount >= 1) {
        return m.group(1)?.trim();
      }
    }
    return null;
  }
}

/// Holds the result of parsing a scanned document.
class ParsedDocument {
  final String type;
  final Map<String, String> fields;
  final String rawText;

  ParsedDocument({
    required this.type,
    required this.fields,
    required this.rawText,
  });

  bool get hasData => fields.isNotEmpty;

  String get displayName {
    final first = fields['firstName'] ?? '';
    final last = fields['lastName'] ?? '';
    if (first.isEmpty && last.isEmpty) return '';
    return '$first $last'.trim();
  }

  String get licenseOrIdNumber =>
      fields['licenseNumber'] ?? fields['idNumber'] ?? '';

  String get expiryDate => fields['expiryDate'] ?? '';
  String get dateOfBirth => fields['dateOfBirth'] ?? '';
  String get cdlClass => fields['cdlClass'] ?? '';
  String get state => fields['state'] ?? '';

  /// Returns true if the CDL class is A or B (valid for commercial trucking).
  bool get isValidCdlClass {
    final cls = cdlClass.toUpperCase();
    return cls.contains('A') || cls.contains('B');
  }
}
