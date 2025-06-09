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