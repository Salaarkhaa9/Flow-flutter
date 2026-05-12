import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/vehicle_profile.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  User? _currentUser;
  final List<User> _registeredUsers = [];
  final Map<String, VehicleProfile> _vehicleProfiles = {};

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  User? get currentUser => _currentUser;

  bool isLoggedIn() {
    return _currentUser != null;
  }

  // ── Persistence helpers ────────────────────────────────────────────────────

  static const _kMcNumber  = 'session_mc';
  static const _kUsername  = 'session_username';
  static const _kPassword  = 'session_password';
  static const _kEmail     = 'session_email';
  static const _kPhone     = 'session_phone';
  static const _kTruck     = 'session_truck';
  static const _kCompany   = 'session_company';

  Future<void> _persistSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMcNumber,  user.mcNumber);
    await prefs.setString(_kUsername,  user.username);
    await prefs.setString(_kPassword,  user.password);
    await prefs.setString(_kEmail,     user.email);
    await prefs.setString(_kPhone,     user.phoneNumber);
    await prefs.setString(_kTruck,     user.truckNumber);
    await prefs.setString(_kCompany,   user.companyName);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kMcNumber);
    await prefs.remove(_kUsername);
    await prefs.remove(_kPassword);
    await prefs.remove(_kEmail);
    await prefs.remove(_kPhone);
    await prefs.remove(_kTruck);
    await prefs.remove(_kCompany);
  }

  /// Call this once at app startup (before runApp or in a FutureBuilder).
  /// Returns true if a saved session was restored.
  static Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final mc = prefs.getString(_kMcNumber);
    if (mc == null || mc.isEmpty) return false;

    final user = User(
      mcNumber:    mc,
      username:    prefs.getString(_kUsername)  ?? '',
      password:    prefs.getString(_kPassword)  ?? '',
      email:       prefs.getString(_kEmail)     ?? '',
      phoneNumber: prefs.getString(_kPhone)     ?? '',
      truckNumber: prefs.getString(_kTruck)     ?? '',
      companyName: prefs.getString(_kCompany)   ?? '',
    );
    _instance._currentUser = user;
    return true;
  }

  // ── Auth methods ───────────────────────────────────────────────────────────

  Future<bool> register({
    required String username,
    required String mcNumber,
    required String password,
    required String email,
    required String phoneNumber,
    required String truckNumber,
    required String companyName,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      if (_registeredUsers.any((user) => user.mcNumber == mcNumber)) {
        return false;
      }

      final newUser = User(
        username:    username,
        mcNumber:    mcNumber,
        password:    password,
        email:       email,
        phoneNumber: phoneNumber,
        truckNumber: truckNumber,
        companyName: companyName,
      );

      _registeredUsers.add(newUser);
      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      return false;
    }
  }

  Future<bool> login({
    required String mcNumber,
    required String password,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final user = _registeredUsers.firstWhere(
        (user) => user.mcNumber == mcNumber && user.password == password,
        orElse: () => User(
          username: '', mcNumber: '', password: '',
          email: '', phoneNumber: '', truckNumber: '', companyName: '',
        ),
      );

      if (user.username.isEmpty) {
        // Fallback demo credentials
        if (mcNumber == 'MC123456' && password == 'password123') {
          _currentUser = User(
            username:    'Salar',
            mcNumber:    'MC123456',
            password:    'password123',
            email:       '',
            phoneNumber: '',
            truckNumber: '',
            companyName: '',
          );
          await _persistSession(_currentUser!);
          return true;
        }
        return false;
      }

      _currentUser = user;
      await _persistSession(_currentUser!);
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await _clearSession();
  }

  // ── Vehicle profile ────────────────────────────────────────────────────────

  VehicleProfile? getVehicleProfile(String userId) {
    return _vehicleProfiles[userId];
  }

  bool hasVehicleProfile(String userId) {
    return _vehicleProfiles.containsKey(userId);
  }

  Future<bool> saveVehicleProfile({
    required String userId,
    required VehicleProfile profile,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      _vehicleProfiles[userId] = profile;
      return true;
    } catch (e) {
      debugPrint('Vehicle profile save error: $e');
      return false;
    }
  }

  List<User> getAllUsers() {
    return _registeredUsers;
  }
}
