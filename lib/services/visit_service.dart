// lib/services/visit_service.dart
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:myapp/models/models.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/visit_models.dart';
import 'location_service.dart';
import 'search_service.dart';

class VisitService {
  static final VisitService _instance = VisitService._internal();
  factory VisitService() => _instance;
  VisitService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();
  final SearchService _searchService = SearchService();

  StreamSubscription<Position>? _locationSubscription;
  Timer? _visitDetectionTimer;
  Position? _lastKnownPosition;
  DateTime? _lastVisitCheck;
  
  // Visit detection parameters
  static const double _visitDetectionRadiusMeters = 50.0; // 50m radius
  static const Duration _minimumStayDuration = Duration(minutes: 5);
  static const Duration _checkInterval = Duration(minutes: 2);

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Manual check-in
  Future<CheckInResult> checkIn({
    required PlaceDetails place,
    required List<String> selectedVibes,
    String? userNote,
    int? rating,
  }) async {
    if (_userId == null) {
      return CheckInResult(success: false, error: 'User not authenticated');
    }

    try {
      // Create visit record
      final visitRef = _firestore.collection('visits').doc();
      final visit = PlaceVisit(
        id: visitRef.id,
        userId: _userId!,
        placeId: place.placeId ?? visitRef.id,
        placeName: place.name,
        placeType: place.type,
        placeCategory: _categorizePlace(place.type, place.tags),
        latitude: place.latitude,
        longitude: place.longitude,
        visitTime: DateTime.now(),
        isManualCheckIn: true,
        vibes: selectedVibes,
        userNote: userNote,
        rating: rating,
        address: _formatAddress(place),
        placeDetails: {
          'rating': place.rating,
          'priceLevel': place.priceLevel,
          'websiteUrl': place.websiteUrl,
          'phoneNumber': place.phoneNumber,
          'imageUrls': place.imageUrls,
        },
      );

      // Save to Firestore
      await visitRef.set(visit.toFirestore());

      // Generate AI vibe if needed
      _generateAIVibe(visitRef.id, place, selectedVibes);

      return CheckInResult(success: true, visitId: visitRef.id);
    } catch (e) {
      return CheckInResult(success: false, error: e.toString());
    }
  }

  // Start background location tracking
  Future<bool> startBackgroundTracking() async {
    if (Platform.isIOS) {
      // iOS requires special handling for background location
      final status = await Permission.locationAlways.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }

    // Configure location settings for background tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Update every 50 meters
      // forceLocationManager: true, // Use location manager on iOS
      // iOS specific settings
      // activityType: ActivityType.fitness,
      // showBackgroundLocationIndicator: true,
    );

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _lastKnownPosition = position;
      _checkForVisits(position);
    });

    // Start periodic visit detection
    _visitDetectionTimer = Timer.periodic(_checkInterval, (_) {
      if (_lastKnownPosition != null) {
        _checkForVisits(_lastKnownPosition!);
      }
    });

    return true;
  }

  // Stop background tracking
  void stopBackgroundTracking() {
    _locationSubscription?.cancel();
    _visitDetectionTimer?.cancel();
    _locationSubscription = null;
    _visitDetectionTimer = null;
  }

  // Check for visits at current location
  Future<void> _checkForVisits(Position position) async {
    if (_userId == null) return;

    final now = DateTime.now();
    
    // Don't check too frequently
    if (_lastVisitCheck != null && 
        now.difference(_lastVisitCheck!).inMinutes < 5) {
      return;
    }
    
    _lastVisitCheck = now;

    try {
      // Search for nearby places
      final result = await _searchService.searchPlaces(
        query: 'venues near me',
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 0.1, // 100m radius
      );

      if (!result.success || result.locations.isEmpty) return;

      // Check each nearby place
      for (final place in result.locations) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          place.latitude,
          place.longitude,
        );

        // If user is within visit detection radius
        if (distance <= _visitDetectionRadiusMeters) {
          await _recordAutomaticVisit(place, position);
        }
      }
    } catch (e) {
      print('Error checking for visits: $e');
    }
  }

  // Record automatic visit
  Future<void> _recordAutomaticVisit(PlaceDetails place, Position position) async {
    if (_userId == null) return;

    try {
      // Check if we've already recorded a visit to this place recently
      final recentVisit = await _firestore
          .collection('visits')
          .where('userId', isEqualTo: _userId)
          .where('placeId', isEqualTo: place.placeId)
          .where('visitTime', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 2))
          ))
          .limit(1)
          .get();

      if (recentVisit.docs.isNotEmpty) {
        return; // Already recorded a visit recently
      }

      // Create automatic visit record
      final visitRef = _firestore.collection('visits').doc();
      final visit = PlaceVisit(
        id: visitRef.id,
        userId: _userId!,
        placeId: place.placeId ?? visitRef.id,
        placeName: place.name,
        placeType: place.type,
        placeCategory: _categorizePlace(place.type, place.tags),
        latitude: place.latitude,
        longitude: place.longitude,
        visitTime: DateTime.now(),
        isManualCheckIn: false,
        vibes: [], // Will be filled by AI
        address: _formatAddress(place),
        placeDetails: {
          'rating': place.rating,
          'priceLevel': place.priceLevel,
          'websiteUrl': place.websiteUrl,
          'phoneNumber': place.phoneNumber,
          'imageUrls': place.imageUrls,
        },
      );

      await visitRef.set(visit.toFirestore());

      // Generate AI vibes for automatic visits
      _generateAIVibe(visitRef.id, place, []);
    } catch (e) {
      print('Error recording automatic visit: $e');
    }
  }

  // Get visit history with filters
  Stream<List<PlaceVisit>> getVisitHistory({
    VisitFilter? filter,
    int limit = 50,
  }) {
    if (_userId == null) {
      return Stream.value([]);
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('visits')
        .where('userId', isEqualTo: _userId)
        .orderBy('visitTime', descending: true)
        .limit(limit);

    // Apply date filters
    if (filter?.startDate != null) {
      query = query.where('visitTime', 
        isGreaterThanOrEqualTo: Timestamp.fromDate(filter!.startDate!));
    }
    if (filter?.endDate != null) {
      query = query.where('visitTime', 
        isLessThanOrEqualTo: Timestamp.fromDate(filter!.endDate!));
    }

    // Apply check-in type filter
    if (filter?.showOnlyManualCheckIns == true) {
      query = query.where('isManualCheckIn', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      var visits = snapshot.docs
          .map((doc) => PlaceVisit.fromFirestore(doc))
          .toList();

      // Apply local filters (categories and vibes)
      if (filter != null) {
        if (filter.categories.isNotEmpty) {
          visits = visits.where((visit) {
            final category = PlaceCategory.fromString(visit.placeCategory);
            return filter.categories.contains(category);
          }).toList();
        }

        if (filter.vibes.isNotEmpty) {
          visits = visits.where((visit) {
            return visit.vibes.any((vibe) => filter.vibes.contains(vibe));
          }).toList();
        }
      }

      return visits;
    });
  }

  // Get visit statistics
  Future<VisitStats> getVisitStats() async {
    if (_userId == null) {
      return VisitStats.empty();
    }

    try {
      final visits = await _firestore
          .collection('visits')
          .where('userId', isEqualTo: _userId)
          .get();

      final visitList = visits.docs
          .map((doc) => PlaceVisit.fromFirestore(doc))
          .toList();

      // Calculate stats
      final totalVisits = visitList.length;
      final uniquePlaces = visitList.map((v) => v.placeId).toSet().length;
      final manualCheckIns = visitList.where((v) => v.isManualCheckIn).length;
      
      // Count by category
      final Map<PlaceCategory, int> categoryCount = {};
      for (final visit in visitList) {
        final category = PlaceCategory.fromString(visit.placeCategory);
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      // Most used vibes
      final Map<String, int> vibeCount = {};
      for (final visit in visitList) {
        for (final vibe in visit.vibes) {
          vibeCount[vibe] = (vibeCount[vibe] ?? 0) + 1;
        }
      }

      return VisitStats(
        totalVisits: totalVisits,
        uniquePlaces: uniquePlaces,
        manualCheckIns: manualCheckIns,
        automaticVisits: totalVisits - manualCheckIns,
        categoryBreakdown: categoryCount,
        topVibes: vibeCount,
      );
    } catch (e) {
      print('Error getting visit stats: $e');
      return VisitStats.empty();
    }
  }

  // Delete a visit
  Future<bool> deleteVisit(String visitId) async {
    if (_userId == null) return false;

    try {
      await _firestore.collection('visits').doc(visitId).delete();
      return true;
    } catch (e) {
      print('Error deleting visit: $e');
      return false;
    }
  }

  // Update visit (add note, change vibes, etc.)
  Future<bool> updateVisit({
    required String visitId,
    List<String>? vibes,
    String? userNote,
    int? rating,
  }) async {
    if (_userId == null) return false;

    try {
      final updates = <String, dynamic>{};
      if (vibes != null) updates['vibes'] = vibes;
      if (userNote != null) updates['userNote'] = userNote;
      if (rating != null) updates['rating'] = rating;

      await _firestore.collection('visits').doc(visitId).update(updates);
      return true;
    } catch (e) {
      print('Error updating visit: $e');
      return false;
    }
  }

  // Helper method to categorize places
  String _categorizePlace(String placeType, List<String>? tags) {
    final type = placeType.toLowerCase();
    final tagList = tags?.map((t) => t.toLowerCase()) ?? [];

    if (type.contains('restaurant') || tagList.any((t) => t.contains('restaurant'))) {
      return PlaceCategory.restaurant.name;
    } else if (type.contains('cafe') || type.contains('coffee') || tagList.any((t) => t.contains('cafe') || t.contains('coffee'))) {
      return PlaceCategory.cafe.name;
    } else if (type.contains('hotel') || type.contains('accommodation')) {
      return PlaceCategory.hotel.name;
    } else if (type.contains('club') || type.contains('nightclub') || tagList.any((t) => t.contains('club'))) {
      return PlaceCategory.club.name;
    } else if (type.contains('bar') || type.contains('lounge') || tagList.any((t) => t.contains('lounge'))) {
      return PlaceCategory.lounge.name;
    } else if (type.contains('museum') || type.contains('gallery') || type.contains('theater') || tagList.any((t) => t.contains('cultural'))) {
      return PlaceCategory.cultural.name;
    } else if (type.contains('park') || type.contains('trail') || tagList.any((t) => t.contains('outdoor') || t.contains('adventure'))) {
      return PlaceCategory.adventure.name;
    }
    
    return PlaceCategory.other.name;
  }

  // Helper method to format address
  String? _formatAddress(PlaceDetails place) {
    // You can enhance this based on your PlaceDetails structure
    return null; // Placeholder
  }

  // Generate AI vibe (placeholder - implement with your AI service)
  Future<void> _generateAIVibe(String visitId, PlaceDetails place, List<String> userVibes) async {
    // TODO: Implement AI vibe generation
    // This would call your AI service to generate a vibe description
    // based on the place details and user-selected vibes
  }
}

// Result classes
class CheckInResult {
  final bool success;
  final String? visitId;
  final String? error;

  CheckInResult({required this.success, this.visitId, this.error});
}

class VisitStats {
  final int totalVisits;
  final int uniquePlaces;
  final int manualCheckIns;
  final int automaticVisits;
  final Map<PlaceCategory, int> categoryBreakdown;
  final Map<String, int> topVibes;

  VisitStats({
    required this.totalVisits,
    required this.uniquePlaces,
    required this.manualCheckIns,
    required this.automaticVisits,
    required this.categoryBreakdown,
    required this.topVibes,
  });

  factory VisitStats.empty() {
    return VisitStats(
      totalVisits: 0,
      uniquePlaces: 0,
      manualCheckIns: 0,
      automaticVisits: 0,
      categoryBreakdown: {},
      topVibes: {},
    );
  }
}