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
import 'photo_verification_service.dart';
import 'notification_service.dart';

class VisitService {
  static final VisitService _instance = VisitService._internal();
  factory VisitService() => _instance;
  VisitService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocationService _locationService = LocationService();
  final SearchService _searchService = SearchService();
  final PhotoVerificationService _photoService = PhotoVerificationService();
  final NotificationService _notificationService = NotificationService();

  // Getter for photo service access
  PhotoVerificationService get photoService => _photoService;

  StreamSubscription<Position>? _locationSubscription;
  Timer? _visitDetectionTimer;
  Position? _lastKnownPosition;
  DateTime? _lastVisitCheck;
  
  // Enhanced visit detection parameters
  static const double _visitDetectionRadiusMeters = 50.0; // 50m radius for auto-detection
  static const double _checkInVerificationRadiusMeters = 500.0; // 500m radius for manual check-ins
  static const Duration _minimumStayDuration = Duration(minutes: 5);
  static const Duration _checkInterval = Duration(minutes: 2);
  static const Duration _gracePeriodDuration = Duration(hours: 24); // 24-hour grace period
  
  // Notification tracking
  final Map<String, DateTime> _lastNotificationSent = {};
  final Set<String> _pendingCheckIns = {};

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Verify check-in eligibility
  Future<CheckInVerification> verifyCheckInEligibility({
    required PlaceDetails place,
    Position? currentPosition,
  }) async {
    if (_userId == null) {
      return CheckInVerification(
        isWithinRadius: false,
        distanceFromPlace: double.infinity,
        isWithinGracePeriod: false,
        canCheckIn: false,
        error: 'User not authenticated',
      );
    }

    try {
      // Get current position if not provided
      if (currentPosition == null) {
        final locationResult = await _locationService.getCurrentLocation();
        if (!locationResult.success || locationResult.position == null) {
          return CheckInVerification(
            isWithinRadius: false,
            distanceFromPlace: double.infinity,
            isWithinGracePeriod: false,
            canCheckIn: false,
            error: locationResult.error ?? 'Unable to get current location',
          );
        }
        currentPosition = locationResult.position;
      }

      // Calculate distance from place
      final distance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition.longitude,
        place.latitude,
        place.longitude,
      );

      // Check if within verification radius
      final isWithinRadius = distance <= _checkInVerificationRadiusMeters;

      // Check for existing check-in today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingCheckIn = await _firestore
          .collection('visits')
          .where('userId', isEqualTo: _userId)
          .where('placeId', isEqualTo: place.placeId)
          .where('visitTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('visitTime', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (existingCheckIn.docs.isNotEmpty) {
        final lastCheckIn = PlaceVisit.fromFirestore(existingCheckIn.docs.first);
        return CheckInVerification(
          isWithinRadius: isWithinRadius,
          distanceFromPlace: distance,
          isWithinGracePeriod: false,
          canCheckIn: false,
          error: 'Already checked in today',
          lastCheckInToday: lastCheckIn.visitTime,
        );
      }

      // Check if within grace period for delayed check-in
      final isWithinGracePeriod = !isWithinRadius && 
                                 distance <= _checkInVerificationRadiusMeters * 2; // Extended radius for grace period

      final canCheckIn = isWithinRadius || isWithinGracePeriod;

      return CheckInVerification(
        isWithinRadius: isWithinRadius,
        distanceFromPlace: distance,
        isWithinGracePeriod: isWithinGracePeriod,
        canCheckIn: canCheckIn,
        error: canCheckIn ? null : 'Too far from location to check in',
      );
    } catch (e) {
      return CheckInVerification(
        isWithinRadius: false,
        distanceFromPlace: double.infinity,
        isWithinGracePeriod: false,
        canCheckIn: false,
        error: e.toString(),
      );
    }
  }

  // Enhanced manual check-in with photo verification
  Future<CheckInResult> checkIn({
    required PlaceDetails place,
    required List<String> selectedVibes,
    String? userNote,
    int? rating,
    File? photoFile,
    String? storyCaption,
    bool isStoryPublic = false,
    DateTime? actualVisitTime, // For delayed check-ins
  }) async {
    if (_userId == null) {
      return CheckInResult(success: false, error: 'User not authenticated');
    }

    try {
      // Step 1: Verify check-in eligibility
      final verification = await verifyCheckInEligibility(place: place);
      if (!verification.canCheckIn) {
        return CheckInResult(success: false, error: verification.error);
      }

      // Step 2: Handle photo verification if provided
      PhotoVerificationResult? photoResult;
      if (photoFile != null) {
        photoResult = await _photoService.verifyPhoto(
          photoFile: photoFile,
          place: place,
          captureTime: actualVisitTime,
        );
      }

      // Step 3: Calculate credibility points
      int credibilityPoints = _calculateCredibilityPoints(
        verification: verification,
        photoResult: photoResult,
        hasNote: userNote?.isNotEmpty ?? false,
        hasRating: rating != null,
      );

      // Step 4: Determine if this is a delayed check-in
      final now = DateTime.now();
      final hasDelayedCheckIn = actualVisitTime != null && 
                              now.difference(actualVisitTime).inHours > 1;

      // Step 5: Create enhanced visit record
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
        visitTime: actualVisitTime ?? now,
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
        // Enhanced verification fields
        isVerified: verification.isWithinRadius,
        verificationDistance: verification.distanceFromPlace,
        actualVisitTime: actualVisitTime,
        hasDelayedCheckIn: hasDelayedCheckIn,
        // Photo verification fields
        hasVerifiedPhoto: photoResult?.isValid ?? false,
        photoCredibilityScore: photoResult?.credibilityScore,
        photoAnalysis: photoResult?.analysis,
        instantVibeTags: photoResult?.suggestedTags,
        // Check-in story
        storyCaption: storyCaption,
        isStoryPublic: isStoryPublic,
        // Trust score impact
        vibeCred: credibilityPoints,
      );

      // Step 6: Save to Firestore
      await visitRef.set(visit.toFirestore());

      // Step 7: Update user's vibe score
      await _updateUserVibeScore(credibilityPoints, photoResult?.isValid ?? false);

      // Step 8: Generate AI vibe if needed
      _generateAIVibe(visitRef.id, place, selectedVibes);

      return CheckInResult(
        success: true, 
        visitId: visitRef.id,
        credibilityPoints: credibilityPoints,
        photoVerification: photoResult,
      );
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
      
      // Send context-aware notifications
      sendContextualNotifications(position);
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

  // Calculate credibility points for a check-in
  int _calculateCredibilityPoints({
    required CheckInVerification verification,
    PhotoVerificationResult? photoResult,
    required bool hasNote,
    required bool hasRating,
  }) {
    int points = 0;

    // Base points for check-in
    points += 5;

    // Distance-based verification bonus
    if (verification.isWithinRadius) {
      points += 10; // Within 500m
      if (verification.distanceFromPlace <= 100) {
        points += 5; // Extra bonus for being very close
      }
    } else if (verification.isWithinGracePeriod) {
      points += 3; // Partial credit for grace period
    }

    // Photo bonus
    if (photoResult != null) {
      points += _photoService.calculateCredibilityPoints(photoResult);
    }

    // Content bonus
    if (hasNote) points += 2;
    if (hasRating) points += 2;

    return points;
  }

  // Update user's overall vibe score
  Future<void> _updateUserVibeScore(int credibilityPoints, bool hasVerifiedPhoto) async {
    if (_userId == null) return;

    try {
      final userScoreRef = _firestore.collection('user_vibe_scores').doc(_userId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userScoreRef);
        
        UserVibeScore currentScore;
        if (snapshot.exists) {
          currentScore = UserVibeScore.fromFirestore(snapshot);
        } else {
          // Create new user score
          currentScore = UserVibeScore(
            userId: _userId!,
            totalCredPoints: 0,
            verifiedCheckIns: 0,
            photoUploads: 0,
            communityLikes: 0,
            badges: ['newcomer'],
            lastUpdated: DateTime.now(),
            level: 1,
            title: 'Vibe Newcomer',
          );
        }

        // Update stats
        final newTotalPoints = currentScore.totalCredPoints + credibilityPoints;
        final newVerifiedCheckIns = currentScore.verifiedCheckIns + 1;
        final newPhotoUploads = hasVerifiedPhoto ? currentScore.photoUploads + 1 : currentScore.photoUploads;
        
        // Calculate new level (every 100 points = 1 level, max 10)
        final newLevel = ((newTotalPoints / 100).floor() + 1).clamp(1, 10);
        
        // Determine new title and badges
        final newTitle = _getTitleForLevel(newLevel);
        final newBadges = _updateBadges(currentScore.badges, newTotalPoints, newVerifiedCheckIns, newPhotoUploads);

        final updatedScore = UserVibeScore(
          userId: _userId!,
          totalCredPoints: newTotalPoints,
          verifiedCheckIns: newVerifiedCheckIns,
          photoUploads: newPhotoUploads,
          communityLikes: currentScore.communityLikes,
          badges: newBadges,
          lastUpdated: DateTime.now(),
          level: newLevel,
          title: newTitle,
        );

        transaction.set(userScoreRef, updatedScore.toFirestore());
      });
    } catch (e) {
      print('Error updating user vibe score: $e');
    }
  }

  String _getTitleForLevel(int level) {
    switch (level) {
      case 1: return 'Vibe Newcomer';
      case 2: return 'Vibe Explorer';
      case 3: return 'Place Discoverer';
      case 4: return 'Vibe Curator';
      case 5: return 'Local Guide';
      case 6: return 'Vibe Expert';
      case 7: return 'Place Connoisseur';
      case 8: return 'Local Tastemaker';
      case 9: return 'Vibe Legend';
      case 10: return 'Vibe Master';
      default: return 'Vibe Newcomer';
    }
  }

  List<String> _updateBadges(List<String> currentBadges, int totalPoints, int verifiedCheckIns, int photoUploads) {
    final badges = Set<String>.from(currentBadges);
    
    // Check for new badges
    for (final badge in VibeBadges.allBadges) {
      if (badges.contains(badge.id)) continue;
      
      bool eligible = totalPoints >= badge.requiredPoints;
      
      // Check specific requirements
      for (final requirement in badge.requirements.entries) {
        switch (requirement.key) {
          case 'verified_checkins':
            eligible = eligible && verifiedCheckIns >= requirement.value;
            break;
          case 'verified_photos':
            eligible = eligible && photoUploads >= requirement.value;
            break;
          case 'unique_places':
            // Would need to calculate this from visits
            break;
        }
      }
      
      if (eligible) {
        badges.add(badge.id);
      }
    }
    
    return badges.toList();
  }

  // Context-aware notifications for nearby places
  Future<void> sendContextualNotifications(Position position) async {
    if (_userId == null) return;

    try {
      // Search for nearby places
      final result = await _searchService.searchPlaces(
        query: 'venues near me',
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 0.5, // 500m radius
      );

      if (!result.success || result.locations.isEmpty) return;

      final nearbyPlaces = result.locations.where((place) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          place.latitude,
          place.longitude,
        );
        return distance <= 500; // Within 500m
      }).toList();

      if (nearbyPlaces.isEmpty) return;

      // Check if we've sent notifications recently
      final now = DateTime.now();
      final locationKey = '${position.latitude.toStringAsFixed(3)}_${position.longitude.toStringAsFixed(3)}';
      
      if (_lastNotificationSent.containsKey(locationKey)) {
        final lastSent = _lastNotificationSent[locationKey]!;
        if (now.difference(lastSent).inMinutes < 30) {
          return; // Don't spam notifications
        }
      }

      // Send appropriate notification
      if (nearbyPlaces.length == 1) {
        // Single venue notification
        final place = nearbyPlaces.first;
        await _notificationService.sendLocalNotification(
          title: 'Still at ${place.name}?',
          body: 'Tap to check in and share your vibe!',
          payload: 'checkin:${place.placeId}',
        );
      } else {
        // Multiple venues notification
        await _notificationService.sendLocalNotification(
          title: 'Multiple spots nearby!',
          body: 'You\'re near ${nearbyPlaces.length} places. Log a vibe now!',
          payload: 'nearby:${nearbyPlaces.length}',
        );
      }

      _lastNotificationSent[locationKey] = now;
    } catch (e) {
      print('Error sending contextual notification: $e');
    }
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
  final int? credibilityPoints;
  final PhotoVerificationResult? photoVerification;

  CheckInResult({
    required this.success, 
    this.visitId, 
    this.error,
    this.credibilityPoints,
    this.photoVerification,
  });
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