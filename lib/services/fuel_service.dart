import '../models/fuel_log.dart';

class FuelService {
  static final FuelService _instance = FuelService._internal();

  final List<FuelLog> _fuelLogs = [];

  factory FuelService() {
    return _instance;
  }

  FuelService._internal();

  Future<List<FuelLog>> getFuelLogs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_fuelLogs);
  }

  Future<bool> addFuelLog(FuelLog log) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      _fuelLogs.insert(0, log);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFuelLog(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      _fuelLogs.removeWhere((log) => log.id == id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
