import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart'; // This file will be generated

@JsonSerializable()
class PlaceDetails {
  final String? placeId;
  final String? dataSource;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String type;
  final List<String>? imageUrls;
  final double? rating;
  final String? priceLevel;
  final List<String>? reviewTexts;
  final List<String>? tags;
  final String? websiteUrl;
  final String? phoneNumber;
  final String? menuUrl;
  final List<SocialLink>? socialLinks;

  PlaceDetails({
    this.placeId,
    this.dataSource,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.imageUrls,
    this.rating,
    this.priceLevel,
    this.reviewTexts,
    this.tags,
    this.websiteUrl,
    this.phoneNumber,
    this.menuUrl,
    this.socialLinks,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) => _$PlaceDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceDetailsToJson(this);
}

@JsonSerializable()
class SocialLink {
  final String platform;
  final String url;

  SocialLink({required this.platform, required this.url});

  factory SocialLink.fromJson(Map<String, dynamic> json) => _$SocialLinkFromJson(json);
  Map<String, dynamic> toJson() => _$SocialLinkToJson(this);
}

@JsonSerializable()
class AnalyzeInputAndSuggestLocationsOutput {
  final List<PlaceDetails> locations;

  AnalyzeInputAndSuggestLocationsOutput({required this.locations});

  factory AnalyzeInputAndSuggestLocationsOutput.fromJson(Map<String, dynamic> json) => _$AnalyzeInputAndSuggestLocationsOutputFromJson(json);
  Map<String, dynamic> toJson() => _$AnalyzeInputAndSuggestLocationsOutputToJson(this);
}

@JsonSerializable()
class VibeList {
  final String id;
  final String title;
  final String description;
  final List<PlaceDetails> places;
  final List<String> tags;
  final String vibeType; // morning, midday, evening, night, romantic, budget-friendly, etc.
  final int estimatedDuration; // in minutes
  final DateTime createdAt;
  final String createdBy;
  final bool isShared;
  final List<String>? sharedWithCircles;
  final bool isMultiStop;
  final List<ItineraryStop>? itineraryStops;
  final List<EnhancedItineraryCategory>? enhancedCategories;
  final String? groupType;
  final String? specialOccasion;

  VibeList({
    required this.id,
    required this.title,
    required this.description,
    required this.places,
    required this.tags,
    required this.vibeType,
    required this.estimatedDuration,
    required this.createdAt,
    required this.createdBy,
    this.isShared = false,
    this.sharedWithCircles,
    this.isMultiStop = false,
    this.itineraryStops,
    this.enhancedCategories,
    this.groupType,
    this.specialOccasion,
  });

  factory VibeList.fromJson(Map<String, dynamic> json) => _$VibeListFromJson(json);
  Map<String, dynamic> toJson() => _$VibeListToJson(this);
}

@JsonSerializable()
class VibePreferences {
  final List<String> preferredVibes; // romantic, budget-friendly, adventurous, etc.
  final List<String> preferredPlaceTypes; // restaurant, cafe, bar, park, etc.
  final int? maxDistance; // in km
  final int? maxDuration; // in minutes
  final String? priceLevel; // $, $$, $$$, $$$$
  final double? minRating;
  final List<String>? dietaryRestrictions;
  final List<String>? accessibility;
  final String? groupType; // solo, couple, small_group, large_group
  final String? spotType; // single, multiple
  final String? specialOccasion; // date_night, first_date, birthday, valentine, team_dinner, etc.
  final List<String>? multiSpotCategories; // for multiple spots: pool, dinner, club, etc.

  VibePreferences({
    required this.preferredVibes,
    required this.preferredPlaceTypes,
    this.maxDistance,
    this.maxDuration,
    this.priceLevel,
    this.minRating,
    this.dietaryRestrictions,
    this.accessibility,
    this.groupType,
    this.spotType,
    this.specialOccasion,
    this.multiSpotCategories,
  });

  factory VibePreferences.fromJson(Map<String, dynamic> json) => _$VibePreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$VibePreferencesToJson(this);
}

@JsonSerializable()
class VibeQuizResponse {
  final Map<String, String> answers;
  final VibePreferences generatedPreferences;

  VibeQuizResponse({
    required this.answers,
    required this.generatedPreferences,
  });

  factory VibeQuizResponse.fromJson(Map<String, dynamic> json) => _$VibeQuizResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VibeQuizResponseToJson(this);
}

@JsonSerializable()
class ItineraryStop {
  final PlaceDetails place;
  final String timeSlot; // morning, afternoon, evening, night
  final String category; // pool, restaurant, club, etc.
  final int order;
  final String? description;

  ItineraryStop({
    required this.place,
    required this.timeSlot,
    required this.category,
    required this.order,
    this.description,
  });

  factory ItineraryStop.fromJson(Map<String, dynamic> json) => _$ItineraryStopFromJson(json);
  Map<String, dynamic> toJson() => _$ItineraryStopToJson(this);
}

@JsonSerializable()
class EnhancedItineraryCategory {
  final String categoryTitle; // "With a View", "Fine Dining", etc.
  final String categoryDescription; // Description of the category
  final String timeSlot; // sunset, dinner, night, etc.
  final List<PlaceDetails> places; // 3-5 places in this category
  final int order;

  EnhancedItineraryCategory({
    required this.categoryTitle,
    required this.categoryDescription,
    required this.timeSlot,
    required this.places,
    required this.order,
  });

  factory EnhancedItineraryCategory.fromJson(Map<String, dynamic> json) => _$EnhancedItineraryCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$EnhancedItineraryCategoryToJson(this);
}

@JsonSerializable()
class Board {
  final String id;
  final String name;
  final String description;
  final String? coverPhotoUrl;
  final List<String> tags;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final BoardType type; // normal or itinerary
  final List<PlaceDetails> places;
  final List<ItineraryStop>? itineraryStops; // For itinerary boards
  final String? groupType; // solo, couple, small_group, large_group
  final String? specialOccasion;

  Board({
    required this.id,
    required this.name,
    required this.description,
    this.coverPhotoUrl,
    this.tags = const [],
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isPublic = false,
    this.type = BoardType.normal,
    this.places = const [],
    this.itineraryStops,
    this.groupType,
    this.specialOccasion,
  });

  factory Board.fromJson(Map<String, dynamic> json) => _$BoardFromJson(json);
  Map<String, dynamic> toJson() => _$BoardToJson(this);
}

@JsonSerializable()
class EditableItineraryStop {
  final String id;
  final PlaceDetails place;
  final String timeSlot;
  final String category;
  final int order;
  final String? description;
  final bool isCustomCategory; // If user edited the category name

  EditableItineraryStop({
    required this.id,
    required this.place,
    required this.timeSlot,
    required this.category,
    required this.order,
    this.description,
    this.isCustomCategory = false,
  });

  factory EditableItineraryStop.fromJson(Map<String, dynamic> json) => _$EditableItineraryStopFromJson(json);
  Map<String, dynamic> toJson() => _$EditableItineraryStopToJson(this);

  factory EditableItineraryStop.fromItineraryStop(ItineraryStop stop) {
    return EditableItineraryStop(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      place: stop.place,
      timeSlot: stop.timeSlot,
      category: stop.category,
      order: stop.order,
      description: stop.description,
    );
  }
}

enum BoardType {
  @JsonValue('normal')
  normal,
  @JsonValue('itinerary')
  itinerary,
}

// ============================================================================
// ENHANCED USER MODEL & VIBE SYSTEM
// ============================================================================

enum CoreVibe {
  @JsonValue('cozy')
  cozy,
  @JsonValue('active')
  active,
  @JsonValue('aesthetic')
  aesthetic,
  @JsonValue('adventurous')
  adventurous,
  @JsonValue('luxurious')
  luxurious,
  @JsonValue('social')
  social,
  @JsonValue('chill')
  chill,
  @JsonValue('intimate')
  intimate,
  @JsonValue('fitness')
  fitness,
}

enum DiningVibe {
  @JsonValue('breakfast')
  breakfast,
  @JsonValue('business')
  business,
  @JsonValue('dateNight')
  dateNight,
  @JsonValue('quickBite')
  quickBite,
  @JsonValue('lateNight')
  lateNight,
}

enum ExperienceVibe {
  @JsonValue('hiddenGem')
  hiddenGem,
  @JsonValue('trending')
  trending,
  @JsonValue('outdoor')
  outdoor,
  @JsonValue('coworking')
  coworking,
  @JsonValue('wellness')
  wellness,
  @JsonValue('budgetFriend')
  budgetFriend,
}

@JsonSerializable()
class VibeScore {
  final String vibeId;
  final double score; // 0.0 to 1.0
  final DateTime lastUpdated;
  final int interactionCount; // Number of times user selected this vibe

  VibeScore({
    required this.vibeId,
    required this.score,
    required this.lastUpdated,
    this.interactionCount = 0,
  });

  factory VibeScore.fromJson(Map<String, dynamic> json) => _$VibeScoreFromJson(json);
  Map<String, dynamic> toJson() => _$VibeScoreToJson(this);
}

@JsonSerializable()
class VibeEvolutionDataPoint {
  final DateTime timestamp;
  final Map<String, double> vibeScores; // vibeId -> score
  final String context; // "onboarding", "visit", "board_creation", etc.

  VibeEvolutionDataPoint({
    required this.timestamp,
    required this.vibeScores,
    required this.context,
  });

  factory VibeEvolutionDataPoint.fromJson(Map<String, dynamic> json) => _$VibeEvolutionDataPointFromJson(json);
  Map<String, dynamic> toJson() => _$VibeEvolutionDataPointToJson(this);
}

@JsonSerializable()
class ContextualVibes {
  final Map<String, List<String>> contextVibeMap; // context -> list of vibes
  final DateTime lastUpdated;

  ContextualVibes({
    required this.contextVibeMap,
    required this.lastUpdated,
  });

  factory ContextualVibes.fromJson(Map<String, dynamic> json) => _$ContextualVibesFromJson(json);
  Map<String, dynamic> toJson() => _$ContextualVibesToJson(this);
}

@JsonSerializable()
class TasteSignature {
  final Map<String, double> venuePreferences; // venue_type -> preference_weight (0.0-1.0)
  final Map<String, double> priceRangeAffinity; // price_level -> comfort_score (0.0-1.0)
  final double socialPreference; // 0.0 (solo) to 1.0 (group enthusiast)
  final double discoveryQuotient; // 0.0 (mainstream) to 1.0 (early adopter)
  final Map<String, List<String>> timePatterns; // time_context -> preferred_activities
  final DateTime lastCalculated;

  TasteSignature({
    required this.venuePreferences,
    required this.priceRangeAffinity,
    required this.socialPreference,
    required this.discoveryQuotient,
    required this.timePatterns,
    required this.lastCalculated,
  });

  factory TasteSignature.fromJson(Map<String, dynamic> json) => _$TasteSignatureFromJson(json);
  Map<String, dynamic> toJson() => _$TasteSignatureToJson(this);
}

@JsonSerializable()
class BehavioralSignals {
  final double vibeConsistencyScore; // 0.0-1.0, how consistent their choices are
  final double explorationRadius; // 0.0-1.0, willingness to try new experiences
  final double influenceScore; // 0.0-1.0, likelihood to influence others' choices
  final Map<String, int> activityPatterns; // day_of_week/time -> activity_count
  final DateTime lastCalculated;

  BehavioralSignals({
    required this.vibeConsistencyScore,
    required this.explorationRadius,
    required this.influenceScore,
    required this.activityPatterns,
    required this.lastCalculated,
  });

  factory BehavioralSignals.fromJson(Map<String, dynamic> json) => _$BehavioralSignalsFromJson(json);
  Map<String, dynamic> toJson() => _$BehavioralSignalsToJson(this);
}

@JsonSerializable()
class VibeProfile {
  final List<String> primaryVibes; // Top 3-5 core vibes
  final Map<String, VibeScore> vibeScores; // All vibe scores
  final List<VibeEvolutionDataPoint> vibeEvolution; // Time-series data
  final ContextualVibes contextualVibes; // Context-based vibe mapping
  final DateTime lastUpdated;

  VibeProfile({
    required this.primaryVibes,
    required this.vibeScores,
    required this.vibeEvolution,
    required this.contextualVibes,
    required this.lastUpdated,
  });

  factory VibeProfile.fromJson(Map<String, dynamic> json) => _$VibeProfileFromJson(json);
  Map<String, dynamic> toJson() => _$VibeProfileToJson(this);
}

@JsonSerializable()
class OnboardingData {
  final List<String> completedSteps; // Track progress through onboarding
  final Map<String, dynamic> quizResponses; // Raw quiz data for ML training
  final List<String> initialMatches; // First suggested circles/users/boards
  final String onboardingVersion; // Track which version they experienced
  final DateTime? completionTimestamp; // When they finished
  final double engagementScore; // 0.0-1.0, how thoroughly they engaged

  OnboardingData({
    required this.completedSteps,
    required this.quizResponses,
    required this.initialMatches,
    required this.onboardingVersion,
    this.completionTimestamp,
    required this.engagementScore,
  });

  factory OnboardingData.fromJson(Map<String, dynamic> json) => _$OnboardingDataFromJson(json);
  Map<String, dynamic> toJson() => _$OnboardingDataToJson(this);
}

@JsonSerializable()
class PrivacySettings {
  final bool vibeVisibility; // Show vibe profile to others
  final bool locationSharing; // Share location-based recommendations
  final String activityPrivacyLevel; // 'public', 'circles', 'private'
  final bool allowVibeMatching; // Allow others to find them via vibe matching
  final bool showBehavioralInsights; // Show behavioral patterns to others

  PrivacySettings({
    this.vibeVisibility = true,
    this.locationSharing = true,
    this.activityPrivacyLevel = 'circles',
    this.allowVibeMatching = true,
    this.showBehavioralInsights = false,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) => _$PrivacySettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PrivacySettingsToJson(this);
}

@JsonSerializable()
class NotificationPreferences {
  final bool boardUpdateAlerts;
  final bool circleActivityNotifications;
  final bool vibeMatchAlerts;
  final bool discoveryRecommendations;
  final bool weeklyInsights;
  final List<String> mutedCircles; // Circle IDs to mute

  NotificationPreferences({
    this.boardUpdateAlerts = true,
    this.circleActivityNotifications = true,
    this.vibeMatchAlerts = true,
    this.discoveryRecommendations = true,
    this.weeklyInsights = true,
    this.mutedCircles = const [],
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) => _$NotificationPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationPreferencesToJson(this);
}

@JsonSerializable()
class EnhancedUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLogin;
  
  // Enhanced Profile Data
  final VibeProfile vibeProfile;
  final TasteSignature tasteSignature;
  final BehavioralSignals behavioralSignals;
  final OnboardingData onboardingData;
  
  // Settings
  final PrivacySettings privacySettings;
  final NotificationPreferences notificationPreferences;
  
  // Profile Enhancement
  final String? bio; // User description
  final String? location; // Home city/location
  final List<String> interests; // Additional interests beyond vibes
  final String? vibeTitle; // Auto-generated or custom title
  final int trustScore; // Based on check-in authenticity, review quality
  final List<String> achievements; // Badges earned
  
  // Metadata
  final DateTime profileLastUpdated;
  final String appVersion; // Version when profile was created/updated

  EnhancedUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    required this.lastLogin,
    required this.vibeProfile,
    required this.tasteSignature,
    required this.behavioralSignals,
    required this.onboardingData,
    required this.privacySettings,
    required this.notificationPreferences,
    this.bio,
    this.location,
    this.interests = const [],
    this.vibeTitle,
    this.trustScore = 0,
    this.achievements = const [],
    required this.profileLastUpdated,
    required this.appVersion,
  });

  factory EnhancedUser.fromJson(Map<String, dynamic> json) => _$EnhancedUserFromJson(json);
  Map<String, dynamic> toJson() => _$EnhancedUserToJson(this);
}
