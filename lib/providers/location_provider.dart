import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/database/app_database.dart';
import '../repositories/location_repository.dart';

class LocationProvider extends ChangeNotifier {
  LocationProvider(this._repository);

  final LocationRepository _repository;

  List<Location> _locations = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Location> get locations => List.unmodifiable(_locations);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<void> loadLocations() async {
    _setLoading(true);

    try {
      _errorMessage = null;
      _locations = await _repository.getAllLocations();
    } catch (error) {
      _errorMessage = 'ไม่สามารถโหลดสถานที่ได้';
      debugPrint('LocationProvider.loadLocations: $error');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addLocation(String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      _errorMessage = 'กรุณาระบุชื่อสถานที่';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      _errorMessage = null;

      await _repository.insertLocation(
        LocationsCompanion.insert(
          name: trimmedName,
          createdAt: DateTime.now(),
        ),
      );

      _locations = await _repository.getAllLocations();

      return true;
    } catch (error) {
      _errorMessage = _getLocationError(error);
      debugPrint('LocationProvider.addLocation: $error');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateLocation(int id, String name) async {
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      _errorMessage = 'กรุณาระบุชื่อสถานที่';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    try {
      _errorMessage = null;

      final existingLocation = await _findLocation(id);

      if (existingLocation == null) {
        _errorMessage = 'ไม่พบสถานที่ที่ต้องการแก้ไข';
        return false;
      }

      final updatedLocation = LocationsCompanion(
        id: Value(existingLocation.id),
        name: Value(trimmedName),
        createdAt: Value(existingLocation.createdAt),
      );

      await _repository.updateLocation(updatedLocation);

      _locations = await _repository.getAllLocations();

      return true;
    } catch (error) {
      _errorMessage = _getLocationError(error);
      debugPrint('LocationProvider.updateLocation: $error');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteLocation(int id) async {
    _setLoading(true);

    try {
      _errorMessage = null;

      final deleted = await _repository.deleteLocation(id);

      if (!deleted) {
        _errorMessage =
            'ไม่สามารถลบสถานที่นี้ได้ เนื่องจากมีทรัพย์สินใช้งานอยู่';
        return false;
      }

      _locations = await _repository.getAllLocations();

      return true;
    } catch (error) {
      _errorMessage = _getLocationError(error);
      debugPrint('LocationProvider.deleteLocation: $error');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<Location?> _findLocation(int id) async {
    for (final location in _locations) {
      if (location.id == id) {
        return location;
      }
    }

    return null;
  }

  String _getLocationError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('unique') || message.contains('constraint')) {
      return 'มีสถานที่นี้อยู่แล้ว';
    }

    return 'เกิดข้อผิดพลาดในการจัดการสถานที่';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}