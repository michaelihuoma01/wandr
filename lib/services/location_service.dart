// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String _currentCity = 'Unknown Location';
  
  Position? get currentPosition => _currentPosition;
  String get currentCity => _currentCity;

  // Get current location with proper error handling
  Future<LocationResult> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          success: false,
          error: 'Location services are disabled. Please enable them in settings.',
          errorType: LocationErrorType.serviceDisabled,
        );
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            success: false,
            error: 'Location permissions are denied',
            errorType: LocationErrorType.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          success: false,
          error: 'Location permissions are permanently denied. Please enable them in settings.',
          errorType: LocationErrorType.permissionDeniedForever,
        );
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Get city name
      await _updateCityName(_currentPosition!);

      return LocationResult(
        success: true,
        position: _currentPosition,
        cityName: _currentCity,
      );
    } catch (e) {
      print('Error getting location: $e');
      return LocationResult(
        success: false,
        error: 'Failed to get location: ${e.toString()}',
        errorType: LocationErrorType.unknown,
      );
    }
  }

  // Update city name from coordinates
  Future<void> _updateCityName(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentCity = place.locality ?? 
                      place.subAdministrativeArea ?? 
                      place.administrativeArea ?? 
                      'Unknown Location';
      }
    } catch (e) {
      print('Error getting city name: $e');
      _currentCity = 'Location found';
    }
  }

  // Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Convert to kilometers
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings (for permissions)
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

// Result class for location operations
class LocationResult {
  final bool success;
  final Position? position;
  final String? cityName;
  final String? error;
  final LocationErrorType? errorType;

  LocationResult({
    required this.success,
    this.position,
    this.cityName,
    this.error,
    this.errorType,
  });
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}