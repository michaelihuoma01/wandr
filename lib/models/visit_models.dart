// lib/models/visit_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'visit_models.g.dart';

@JsonSerializable()
class PlaceVisit {
  final String id;
  final String userId;
  final String placeId;
  final String placeName;
  final String placeType;
  final String? placeCategory; // restaurant, cafe, hotel, club, lounge, cultural, adventure
  final double latitude;
  final double longitude;
  final DateTime visitTime;
  final bool isManualCheckIn;
  final List<String> vibes; // e.g., ["romantic", "trendy", "cozy"]
  final String? aiGeneratedVibe; // AI-generated vibe description
  final String? userNote;
  final List<String>? photoUrls;
  final int? rating;
  final String? address;
  final Map<String, dynamic>? placeDetails; // Store additional place info
  
  // Enhanced verification fields
  final bool isVerified; // GPS verification within 500m
  final double? verificationDistance; // Distance from place when checked in
  final DateTime? actualVisitTime; // For delayed check-ins, when they were actually there
  final bool hasDelayedCheckIn; // If checked in after 24h grace period
  
  // Photo verification fields
  final bool hasVerifiedPhoto; // AI verified photo
  final double? photoCredibilityScore; // AI confidence score (0-1)
  final String? photoAnalysis; // AI analysis results
  final List<String>? instantVibeTags; // AI-suggested vibe tags from photo
  
  // Check-in story
  final String? storyCaption; // User's story caption
  final bool isStoryPublic; // Share story publicly
  
  // Trust score impact
  final int vibeCred; // Credibility points earned from this check-in

  PlaceVisit({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.placeName,
    required this.placeType,
    this.placeCategory,
    required this.latitude,
    required this.longitude,
    required this.visitTime,
    required this.isManualCheckIn,
    this.vibes = const [],
    this.aiGeneratedVibe,
    this.userNote,
    this.photoUrls,
    this.rating,
    this.address,
    this.placeDetails,
    // Enhanced verification fields
    this.isVerified = false,
    this.verificationDistance,
    this.actualVisitTime,
    this.hasDelayedCheckIn = false,
    // Photo verification fields
    this.hasVerifiedPhoto = false,
    this.photoCredibilityScore,
    this.photoAnalysis,
    this.instantVibeTags,
    // Check-in story
    this.storyCaption,
    this.isStoryPublic = false,
    // Trust score impact
    this.vibeCred = 0,
  });

  factory PlaceVisit.fromJson(Map<String, dynamic> json) => _$PlaceVisitFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceVisitToJson(this);

  factory PlaceVisit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlaceVisit(
      id: doc.id,
      userId: data['userId'] ?? '',
      placeId: data['placeId'] ?? '',
      placeName: data['placeName'] ?? '',
      placeType: data['placeType'] ?? '',
      placeCategory: data['placeCategory'],
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      visitTime: (data['visitTime'] as Timestamp).toDate(),
      isManualCheckIn: data['isManualCheckIn'] ?? false,
      vibes: List<String>.from(data['vibes'] ?? []),
      aiGeneratedVibe: data['aiGeneratedVibe'],
      userNote: data['userNote'],
      photoUrls: data['photoUrls'] != null ? List<String>.from(data['photoUrls']) : null,
      rating: data['rating'],
      address: data['address'],
      placeDetails: data['placeDetails'],
      // Enhanced verification fields
      isVerified: data['isVerified'] ?? false,
      verificationDistance: data['verificationDistance']?.toDouble(),
      actualVisitTime: data['actualVisitTime'] != null ? (data['actualVisitTime'] as Timestamp).toDate() : null,
      hasDelayedCheckIn: data['hasDelayedCheckIn'] ?? false,
      // Photo verification fields
      hasVerifiedPhoto: data['hasVerifiedPhoto'] ?? false,
      photoCredibilityScore: data['photoCredibilityScore']?.toDouble(),
      photoAnalysis: data['photoAnalysis'],
      instantVibeTags: data['instantVibeTags'] != null ? List<String>.from(data['instantVibeTags']) : null,
      // Check-in story
      storyCaption: data['storyCaption'],
      isStoryPublic: data['isStoryPublic'] ?? false,
      // Trust score impact
      vibeCred: data['vibeCred'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'placeId': placeId,
      'placeName': placeName,
      'placeType': placeType,
      'placeCategory': placeCategory,
      'latitude': latitude,
      'longitude': longitude,
      'visitTime': Timestamp.fromDate(visitTime),
      'isManualCheckIn': isManualCheckIn,
      'vibes': vibes,
      'aiGeneratedVibe': aiGeneratedVibe,
      'userNote': userNote,
      'photoUrls': photoUrls,
      'rating': rating,
      'address': address,
      'placeDetails': placeDetails,
      // Enhanced verification fields
      'isVerified': isVerified,
      'verificationDistance': verificationDistance,
      'actualVisitTime': actualVisitTime != null ? Timestamp.fromDate(actualVisitTime!) : null,
      'hasDelayedCheckIn': hasDelayedCheckIn,
      // Photo verification fields
      'hasVerifiedPhoto': hasVerifiedPhoto,
      'photoCredibilityScore': photoCredibilityScore,
      'photoAnalysis': photoAnalysis,
      'instantVibeTags': instantVibeTags,
      // Check-in story
      'storyCaption': storyCaption,
      'isStoryPublic': isStoryPublic,
      // Trust score impact
      'vibeCred': vibeCred,
    };
  }
}

// Predefined vibe tags
class VibeTag {
  final String id;
  final String name;
  final String emoji;
  final String category; // mood, atmosphere, crowd, style

  const VibeTag({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
  });
}

// Predefined vibe tags users can select
class VibeConstants {
  static const List<VibeTag> allVibes = [
    // Mood vibes
    VibeTag(id: 'romantic', name: 'Romantic', emoji: '💕', category: 'mood'),
    VibeTag(id: 'fun', name: 'Fun', emoji: '🎉', category: 'mood'),
    VibeTag(id: 'relaxing', name: 'Relaxing', emoji: '😌', category: 'mood'),
    VibeTag(id: 'exciting', name: 'Exciting', emoji: '🔥', category: 'mood'),
    
    // Atmosphere vibes
    VibeTag(id: 'cozy', name: 'Cozy', emoji: '🛋️', category: 'atmosphere'),
    VibeTag(id: 'lively', name: 'Lively', emoji: '🎭', category: 'atmosphere'),
    VibeTag(id: 'intimate', name: 'Intimate', emoji: '🕯️', category: 'atmosphere'),
    VibeTag(id: 'energetic', name: 'Energetic', emoji: '⚡', category: 'atmosphere'),
    
    // Crowd vibes
    VibeTag(id: 'trendy', name: 'Trendy', emoji: '✨', category: 'crowd'),
    VibeTag(id: 'hipster', name: 'Hipster', emoji: '🎨', category: 'crowd'),
    VibeTag(id: 'family_friendly', name: 'Family Friendly', emoji: '👨‍👩‍👧‍👦', category: 'crowd'),
    VibeTag(id: 'professional', name: 'Professional', emoji: '💼', category: 'crowd'),
    
    // Style vibes
    VibeTag(id: 'aesthetic', name: 'Aesthetic', emoji: '📸', category: 'style'),
    VibeTag(id: 'rustic', name: 'Rustic', emoji: '🌿', category: 'style'),
    VibeTag(id: 'modern', name: 'Modern', emoji: '🏙️', category: 'style'),
    VibeTag(id: 'vintage', name: 'Vintage', emoji: '🕰️', category: 'style'),
  ];

  static VibeTag? getVibeById(String id) {
    try {
      return allVibes.firstWhere((vibe) => vibe.id == id);
    } catch (e) {
      return null;
    }
  }
}

// Categories for filtering
enum PlaceCategory {
  restaurant('Restaurant', '🍽️'),
  cafe('Cafe', '☕'),
  hotel('Hotel', '🏨'),
  club('Club', '🎵'),
  lounge('Lounge', '🍸'),
  cultural('Cultural', '🎭'),
  adventure('Adventure', '🏔️'),
  other('Other', '📍');

  final String displayName;
  final String emoji;
  
  const PlaceCategory(this.displayName, this.emoji);
  
  static PlaceCategory fromString(String? value) {
    if (value == null) return PlaceCategory.other;
    try {
      return PlaceCategory.values.firstWhere(
        (cat) => cat.name == value.toLowerCase(),
        orElse: () => PlaceCategory.other,
      );
    } catch (e) {
      return PlaceCategory.other;
    }
  }
}

// Filter options for visit history
class VisitFilter {
  final Set<PlaceCategory> categories;
  final Set<String> vibes;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool showOnlyManualCheckIns;

  VisitFilter({
    this.categories = const {},
    this.vibes = const {},
    this.startDate,
    this.endDate,
    this.showOnlyManualCheckIns = false,
  });

  VisitFilter copyWith({
    Set<PlaceCategory>? categories,
    Set<String>? vibes,
    DateTime? startDate,
    DateTime? endDate,
    bool? showOnlyManualCheckIns,
  }) {
    return VisitFilter(
      categories: categories ?? this.categories,
      vibes: vibes ?? this.vibes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      showOnlyManualCheckIns: showOnlyManualCheckIns ?? this.showOnlyManualCheckIns,
    );
  }

  bool get hasActiveFilters => 
    categories.isNotEmpty || 
    vibes.isNotEmpty || 
    startDate != null || 
    endDate != null || 
    showOnlyManualCheckIns;
}

// User trust score and badges
@JsonSerializable()
class UserVibeScore {
  final String userId;
  final int totalCredPoints;
  final int verifiedCheckIns;
  final int photoUploads;
  final int communityLikes;
  final List<String> badges;
  final DateTime lastUpdated;
  final int level; // 1-10 based on total points
  final String title; // e.g., "Local Tastemaker", "Vibe Explorer"

  UserVibeScore({
    required this.userId,
    required this.totalCredPoints,
    required this.verifiedCheckIns,
    required this.photoUploads,
    required this.communityLikes,
    required this.badges,
    required this.lastUpdated,
    required this.level,
    required this.title,
  });

  factory UserVibeScore.fromJson(Map<String, dynamic> json) => _$UserVibeScoreFromJson(json);
  Map<String, dynamic> toJson() => _$UserVibeScoreToJson(this);

  factory UserVibeScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserVibeScore(
      userId: doc.id,
      totalCredPoints: data['totalCredPoints'] ?? 0,
      verifiedCheckIns: data['verifiedCheckIns'] ?? 0,
      photoUploads: data['photoUploads'] ?? 0,
      communityLikes: data['communityLikes'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      level: data['level'] ?? 1,
      title: data['title'] ?? 'Vibe Newcomer',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalCredPoints': totalCredPoints,
      'verifiedCheckIns': verifiedCheckIns,
      'photoUploads': photoUploads,
      'communityLikes': communityLikes,
      'badges': badges,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'level': level,
      'title': title,
    };
  }
}

// Check-in verification result
class CheckInVerification {
  final bool isWithinRadius;
  final double distanceFromPlace;
  final bool isWithinGracePeriod;
  final bool canCheckIn;
  final String? error;
  final DateTime? lastCheckInToday;

  CheckInVerification({
    required this.isWithinRadius,
    required this.distanceFromPlace,
    required this.isWithinGracePeriod,
    required this.canCheckIn,
    this.error,
    this.lastCheckInToday,
  });
}

// Photo verification result
class PhotoVerificationResult {
  final bool isValid;
  final double credibilityScore; // 0-1
  final bool isRecent; // Within 24 hours
  final bool isOriginal; // Not screenshot/stock
  final bool isRelevant; // Matches venue
  final List<String> suggestedTags;
  final String analysis;
  final String? error;

  PhotoVerificationResult({
    required this.isValid,
    required this.credibilityScore,
    required this.isRecent,
    required this.isOriginal,
    required this.isRelevant,
    required this.suggestedTags,
    required this.analysis,
    this.error,
  });
}

// Badge definitions
class VibeBadge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int requiredPoints;
  final Map<String, int> requirements; // e.g., {'verified_checkins': 50}

  const VibeBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requiredPoints,
    required this.requirements,
  });
}

// Predefined badges
class VibeBadges {
  static const List<VibeBadge> allBadges = [
    VibeBadge(
      id: 'newcomer',
      name: 'Vibe Newcomer',
      description: 'Welcome to the community!',
      emoji: '🌟',
      requiredPoints: 0,
      requirements: {},
    ),
    VibeBadge(
      id: 'explorer',
      name: 'Vibe Explorer',
      description: 'Checked into 10 different places',
      emoji: '🗺️',
      requiredPoints: 100,
      requirements: {'unique_places': 10},
    ),
    VibeBadge(
      id: 'photographer',
      name: 'Vibe Photographer',
      description: 'Uploaded 25 verified photos',
      emoji: '📸',
      requiredPoints: 250,
      requirements: {'verified_photos': 25},
    ),
    VibeBadge(
      id: 'local_tastemaker',
      name: 'Local Tastemaker',
      description: 'Trusted by the community',
      emoji: '👑',
      requiredPoints: 500,
      requirements: {'verified_checkins': 50, 'community_likes': 100},
    ),
    VibeBadge(
      id: 'vibe_master',
      name: 'Vibe Master',
      description: 'The ultimate vibe curator',
      emoji: '🏆',
      requiredPoints: 1000,
      requirements: {'verified_checkins': 100, 'verified_photos': 50, 'community_likes': 200},
    ),
  ];

  static VibeBadge? getBadgeById(String id) {
    try {
      return allBadges.firstWhere((badge) => badge.id == id);
    } catch (e) {
      return null;
    }
  }
}