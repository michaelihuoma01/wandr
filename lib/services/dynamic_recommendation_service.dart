import 'dart:math';
import '../models/models.dart';
import 'user_persona_service.dart';
import 'vibe_definition_service.dart';

class DynamicRecommendationService {
  // ============================================================================
  // CONTEXT-AWARE RECOMMENDATION ENGINE
  // ============================================================================

  /// Generate personalized recommendations based on current context
  static Future<PersonalizedRecommendations> generateRecommendations({
    required String userId,
    required VibeProfile vibeProfile,
    DateTime? currentTime,
    WeatherCondition? weather,
    UserContext? userContext,
    String? location,
    double? userLatitude,
    double? userLongitude,
    Map<String, dynamic>? additionalContext,
  }) async {
    final now = currentTime ?? DateTime.now();
    
    // Generate current persona
    final persona = UserPersonaService.generatePersona(
      vibeProfile,
      currentTime: now,
      weather: weather,
      context: userContext,
    );

    // Get contextual adjustments
    final contextualFactors = _analyzeContextualFactors(
      now, weather, userContext, location, additionalContext,
    );

    // Generate different types of recommendations
    final primaryRecs = await _generatePrimaryRecommendations(persona, contextualFactors);
    final serendipityRecs = await _generateSerendipityRecommendations(persona, contextualFactors);
    final timeSensitiveRecs = await _generateTimeSensitiveRecommendations(persona, now);
    final socialRecs = await _generateSocialRecommendations(userId, persona);

    return PersonalizedRecommendations(
      userId: userId,
      persona: persona,
      primaryRecommendations: primaryRecs,
      serendipityFinds: serendipityRecs,
      timeSensitiveOffers: timeSensitiveRecs,
      socialRecommendations: socialRecs,
      contextualFactors: contextualFactors,
      generatedAt: now,
      validUntil: now.add(const Duration(hours: 2)),
    );
  }

  /// Update recommendations based on user interaction
  static Future<PersonalizedRecommendations> updateRecommendations(
    PersonalizedRecommendations current,
    UserInteractionFeedback feedback,
  ) async {
    // Analyze feedback and adjust future recommendations
    final adjustedPersona = _adjustPersonaFromFeedback(current.persona, feedback);
    
    return generateRecommendations(
      userId: current.userId,
      vibeProfile: _convertPersonaToVibeProfile(adjustedPersona),
      currentTime: DateTime.now(),
    );
  }

  // ============================================================================
  // RECOMMENDATION GENERATORS
  // ============================================================================

  static Future<List<RecommendationItem>> _generatePrimaryRecommendations(
    UserPersona persona,
    ContextualFactors context,
  ) async {
    final recommendations = <RecommendationItem>[];
    
    // Core persona-matched venues
    for (final venueType in persona.venueTypes.take(5)) {
      recommendations.add(RecommendationItem(
        id: _generateRecommendationId(),
        type: RecommendationType.venue,
        title: _getVenueTypeDisplayName(venueType),
        description: _generatePersonaDescription(persona, venueType),
        matchScore: _calculatePersonaMatch(persona, venueType),
        vibeReasons: persona.primaryVibes,
        timeRelevance: _calculateTimeRelevance(persona, context.timeOfDay),
        weatherSuitability: _calculateWeatherSuitability(venueType, context.weather),
        tags: [persona.name.toLowerCase().replaceAll(' ', '_'), venueType],
        priority: RecommendationPriority.high,
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
      ));
    }

    // Apply contextual boosts
    _applyContextualBoosts(recommendations, context);
    
    // Sort by total score and return top recommendations
    recommendations.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    
    return recommendations.take(8).toList();
  }

  static Future<List<SerendipityRecommendation>> _generateSerendipityRecommendations(
    UserPersona persona,
    ContextualFactors context,
  ) async {
    final serendipityRecs = <SerendipityRecommendation>[];
    
    // Find complementary vibes (expand user's comfort zone slightly)
    final complementaryVibes = _findComplementaryVibes(persona.primaryVibes);
    
    for (final vibe in complementaryVibes.take(3)) {
      serendipityRecs.add(SerendipityRecommendation(
        id: _generateRecommendationId(),
        title: 'Expand Your ${vibe.capitalize()} Side',
        description: _generateSerendipityDescription(vibe, persona),
        newVibeIntroduced: vibe,
        compatibilityReason: _getCompatibilityReason(persona.primaryVibes.first, vibe),
        explorationType: _getExplorationType(vibe),
        riskLevel: _calculateRiskLevel(persona, vibe),
        potentialReward: _calculatePotentialReward(persona, vibe),
        tags: ['serendipity', vibe, 'expansion'],
      ));
    }

    return serendipityRecs;
  }

  static Future<List<TimeSensitiveRecommendation>> _generateTimeSensitiveRecommendations(
    UserPersona persona,
    DateTime currentTime,
  ) async {
    final timeSensitiveRecs = <TimeSensitiveRecommendation>[];
    
    // Happy hour recommendations
    if (_isHappyHourTime(currentTime)) {
      timeSensitiveRecs.add(TimeSensitiveRecommendation(
        id: _generateRecommendationId(),
        title: 'Happy Hour Vibes',
        description: 'Perfect timing for discounted drinks and social energy',
        timeWindow: 'Now until 7 PM',
        urgencyLevel: UrgencyLevel.medium,
        discountInfo: '50% off drinks',
        venueTypes: ['bar', 'rooftop_bar', 'brewery'],
        expiresAt: DateTime(currentTime.year, currentTime.month, currentTime.day, 19),
      ));
    }

    // Weekend brunch opportunities
    if (_isWeekendBrunchTime(currentTime)) {
      timeSensitiveRecs.add(TimeSensitiveRecommendation(
        id: _generateRecommendationId(),
        title: 'Weekend Brunch Scene',
        description: 'Perfect lazy weekend vibes await',
        timeWindow: 'Weekend brunch hours',
        urgencyLevel: UrgencyLevel.low,
        venueTypes: ['brunch_cafe', 'rooftop_restaurant', 'garden_cafe'],
        expiresAt: currentTime.add(const Duration(hours: 3)),
      ));
    }

    // Weather-based urgent recommendations
    if (_isWeatherChanging(currentTime)) {
      timeSensitiveRecs.add(TimeSensitiveRecommendation(
        id: _generateRecommendationId(),
        title: 'Beat the Weather',
        description: 'Enjoy outdoor spots before conditions change',
        timeWindow: 'Next 2 hours',
        urgencyLevel: UrgencyLevel.high,
        venueTypes: ['outdoor_cafe', 'terrace', 'garden_restaurant'],
        expiresAt: currentTime.add(const Duration(hours: 2)),
      ));
    }

    return timeSensitiveRecs;
  }

  static Future<List<SocialRecommendation>> _generateSocialRecommendations(
    String userId,
    UserPersona persona,
  ) async {
    final socialRecs = <SocialRecommendation>[];
    
    // Friend activity recommendations
    socialRecs.add(SocialRecommendation(
      id: _generateRecommendationId(),
      title: '3 Friends Are Active Nearby',
      description: 'See what your circle is discovering right now',
      socialTrigger: SocialTrigger.friendActivity,
      actionType: 'Check friend activity',
      potentialConnections: 3,
      mutualInterests: persona.primaryVibes,
    ));

    // Similar users recommendations
    socialRecs.add(SocialRecommendation(
      id: _generateRecommendationId(),
      title: 'Meet Your Vibe Tribe',
      description: 'Connect with other ${persona.name.toLowerCase()}s in your area',
      socialTrigger: SocialTrigger.similarUsers,
      actionType: 'Discover similar users',
      potentialConnections: 12,
      mutualInterests: persona.primaryVibes,
    ));

    // Group activity suggestions
    if (persona.socialStyle.contains('group')) {
      socialRecs.add(SocialRecommendation(
        id: _generateRecommendationId(),
        title: 'Perfect for Your Group',
        description: 'Venues that accommodate ${persona.preferences.socialGroupSize} people',
        socialTrigger: SocialTrigger.groupPlanning,
        actionType: 'Plan group outing',
        potentialConnections: _parseGroupSize(persona.preferences.socialGroupSize),
        mutualInterests: persona.primaryVibes,
      ));
    }

    return socialRecs;
  }

  // ============================================================================
  // CONTEXTUAL ANALYSIS
  // ============================================================================

  static ContextualFactors _analyzeContextualFactors(
    DateTime currentTime,
    WeatherCondition? weather,
    UserContext? userContext,
    String? location,
    Map<String, dynamic>? additionalContext,
  ) {
    return ContextualFactors(
      timeOfDay: _getTimeOfDay(currentTime),
      dayOfWeek: _getDayOfWeek(currentTime),
      weather: weather ?? WeatherCondition.sunny,
      userContext: userContext,
      location: location,
      isRushHour: _isRushHour(currentTime),
      isWeekend: currentTime.weekday >= 6,
      seasonalFactors: _getSeasonalFactors(currentTime),
      localEvents: _getLocalEvents(location, currentTime),
      trafficLevel: _getTrafficLevel(currentTime, location),
    );
  }

  static String _getTimeOfDay(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 22) return 'evening';
    return 'night';
  }

  static String _getDayOfWeek(DateTime time) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[time.weekday - 1];
  }

  static bool _isRushHour(DateTime time) {
    final hour = time.hour;
    final isWeekday = time.weekday <= 5;
    return isWeekday && ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19));
  }

  static List<String> _getSeasonalFactors(DateTime time) {
    final month = time.month;
    if (month >= 12 || month <= 2) return ['winter', 'holiday_season'];
    if (month >= 3 && month <= 5) return ['spring', 'outdoor_season'];
    if (month >= 6 && month <= 8) return ['summer', 'peak_outdoor'];
    return ['autumn', 'cozy_season'];
  }

  static List<String> _getLocalEvents(String? location, DateTime time) {
    // This would integrate with local event APIs
    return ['farmers_market', 'art_exhibition']; // Placeholder
  }

  static String _getTrafficLevel(DateTime time, String? location) {
    if (_isRushHour(time)) return 'high';
    if (time.weekday >= 6) return 'low';
    return 'medium';
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  static List<String> _findComplementaryVibes(List<String> primaryVibes) {
    final complementaryMap = {
      'cozy': ['aesthetic', 'intimate'],
      'active': ['social', 'outdoor'],
      'aesthetic': ['luxurious', 'intimate'],
      'adventurous': ['hiddenGem', 'outdoor'],
      'luxurious': ['business', 'intimate'],
      'social': ['active', 'trendy'],
      'chill': ['outdoor', 'wellness'],
      'intimate': ['luxurious', 'aesthetic'],
      'fitness': ['wellness', 'active'],
    };

    final complementary = <String>[];
    for (final vibe in primaryVibes) {
      final comp = complementaryMap[vibe] ?? [];
      complementary.addAll(comp);
    }

    return complementary.toSet().toList();
  }

  static double _calculatePersonaMatch(UserPersona persona, String venueType) {
    if (persona.venueTypes.contains(venueType)) return 0.9;
    return 0.5; // Base score for unmatched venues
  }

  static double _calculateTimeRelevance(UserPersona persona, String timeOfDay) {
    return persona.timePreferences[timeOfDay] ?? 0.5;
  }

  static double _calculateWeatherSuitability(String venueType, WeatherCondition? weather) {
    if (weather == null) return 0.5;
    
    final outdoorVenues = ['rooftop', 'terrace', 'garden', 'beach', 'park'];
    final isOutdoor = outdoorVenues.any((outdoor) => venueType.contains(outdoor));
    
    switch (weather) {
      case WeatherCondition.sunny:
        return isOutdoor ? 0.9 : 0.6;
      case WeatherCondition.rainy:
        return isOutdoor ? 0.2 : 0.8;
      default:
        return 0.5;
    }
  }

  static void _applyContextualBoosts(
    List<RecommendationItem> recommendations,
    ContextualFactors context,
  ) {
    for (final rec in recommendations) {
      // Time-based boosts
      if (context.timeOfDay == 'morning' && rec.tags.contains('breakfast')) {
        rec.boostScore(0.2, 'Perfect morning timing');
      }
      
      // Weather boosts
      if (context.weather == WeatherCondition.rainy && rec.tags.contains('cozy')) {
        rec.boostScore(0.25, 'Cozy weather vibes');
      }
      
      // Weekend boosts
      if (context.isWeekend && rec.tags.contains('social')) {
        rec.boostScore(0.15, 'Weekend social energy');
      }
    }
  }

  static bool _isHappyHourTime(DateTime time) {
    final hour = time.hour;
    final isWeekday = time.weekday <= 5;
    return isWeekday && hour >= 16 && hour <= 18;
  }

  static bool _isWeekendBrunchTime(DateTime time) {
    final hour = time.hour;
    final isWeekend = time.weekday >= 6;
    return isWeekend && hour >= 9 && hour <= 14;
  }

  static bool _isWeatherChanging(DateTime time) {
    // This would integrate with weather APIs to predict changes
    return Random().nextBool(); // Placeholder
  }

  static String _generateRecommendationId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String _getVenueTypeDisplayName(String venueType) {
    return venueType.replaceAll('_', ' ').split(' ').map((word) => 
      word.isEmpty ? word : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  static String _generatePersonaDescription(UserPersona persona, String venueType) {
    return 'Perfect for ${persona.name.toLowerCase()}s who appreciate ${persona.primaryVibes.join(", ")} vibes';
  }

  static String _generateSerendipityDescription(String vibe, UserPersona persona) {
    return 'Discover your ${vibe} side - it complements your ${persona.primaryVibes.first} nature perfectly';
  }

  static String _getCompatibilityReason(String primaryVibe, String newVibe) {
    final reasonMap = {
      'cozy_aesthetic': 'Both appreciate beautiful, comfortable spaces',
      'active_social': 'High energy and group dynamics go hand in hand',
      'luxurious_intimate': 'Quality experiences in special settings',
    };
    
    return reasonMap['${primaryVibe}_$newVibe'] ?? 'These vibes complement each other beautifully';
  }

  static String _getExplorationType(String vibe) {
    final typeMap = {
      'aesthetic': 'Visual discovery',
      'social': 'Community connection',
      'luxurious': 'Premium experience',
      'adventurous': 'Hidden exploration',
    };
    
    return typeMap[vibe] ?? 'New experience';
  }

  static double _calculateRiskLevel(UserPersona persona, String newVibe) {
    // Higher exploration level = lower risk tolerance for new vibes
    return 1.0 - persona.explorationLevel;
  }

  static double _calculatePotentialReward(UserPersona persona, String newVibe) {
    // Calculate based on vibe compatibility and persona openness
    return 0.7 + (persona.explorationLevel * 0.3);
  }

  static int _parseGroupSize(String groupSize) {
    if (groupSize.contains('+')) {
      return int.tryParse(groupSize.replaceAll('+', '')) ?? 4;
    }
    if (groupSize.contains('-')) {
      final parts = groupSize.split('-');
      return int.tryParse(parts.last) ?? 4;
    }
    return int.tryParse(groupSize) ?? 2;
  }

  static UserPersona _adjustPersonaFromFeedback(
    UserPersona persona,
    UserInteractionFeedback feedback,
  ) {
    // Adjust persona based on user feedback (simplified)
    return persona; // Placeholder implementation
  }

  static VibeProfile _convertPersonaToVibeProfile(UserPersona persona) {
    final vibeScores = <String, VibeScore>{};
    for (int i = 0; i < persona.primaryVibes.length; i++) {
      vibeScores[persona.primaryVibes[i]] = VibeScore(
        vibeId: persona.primaryVibes[i],
        score: 0.9 - (i * 0.1),
        lastUpdated: DateTime.now(),
        interactionCount: 1,
      );
    }

    return VibeProfile(
      primaryVibes: persona.primaryVibes,
      vibeScores: vibeScores,
      vibeEvolution: [],
      contextualVibes: ContextualVibes(
        contextVibeMap: {},
        lastUpdated: DateTime.now(),
      ),
      lastUpdated: DateTime.now(),
    );
  }
}

// ============================================================================
// RECOMMENDATION DATA CLASSES
// ============================================================================

class PersonalizedRecommendations {
  final String userId;
  final UserPersona persona;
  final List<RecommendationItem> primaryRecommendations;
  final List<SerendipityRecommendation> serendipityFinds;
  final List<TimeSensitiveRecommendation> timeSensitiveOffers;
  final List<SocialRecommendation> socialRecommendations;
  final ContextualFactors contextualFactors;
  final DateTime generatedAt;
  final DateTime validUntil;

  PersonalizedRecommendations({
    required this.userId,
    required this.persona,
    required this.primaryRecommendations,
    required this.serendipityFinds,
    required this.timeSensitiveOffers,
    required this.socialRecommendations,
    required this.contextualFactors,
    required this.generatedAt,
    required this.validUntil,
  });
}

class RecommendationItem {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  final double matchScore;
  final List<String> vibeReasons;
  final double timeRelevance;
  final double weatherSuitability;
  final List<String> tags;
  final RecommendationPriority priority;
  final DateTime expiresAt;
  
  double _boostScore = 0.0;
  List<String> _boostReasons = [];

  RecommendationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.matchScore,
    required this.vibeReasons,
    required this.timeRelevance,
    required this.weatherSuitability,
    required this.tags,
    required this.priority,
    required this.expiresAt,
  });

  double get totalScore => matchScore + timeRelevance + weatherSuitability + _boostScore;
  
  List<String> get boostReasons => _boostReasons;

  void boostScore(double boost, String reason) {
    _boostScore += boost;
    _boostReasons.add(reason);
  }
}

class SerendipityRecommendation {
  final String id;
  final String title;
  final String description;
  final String newVibeIntroduced;
  final String compatibilityReason;
  final String explorationType;
  final double riskLevel;
  final double potentialReward;
  final List<String> tags;

  SerendipityRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.newVibeIntroduced,
    required this.compatibilityReason,
    required this.explorationType,
    required this.riskLevel,
    required this.potentialReward,
    required this.tags,
  });
}

class TimeSensitiveRecommendation {
  final String id;
  final String title;
  final String description;
  final String timeWindow;
  final UrgencyLevel urgencyLevel;
  final String? discountInfo;
  final List<String> venueTypes;
  final DateTime expiresAt;

  TimeSensitiveRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.timeWindow,
    required this.urgencyLevel,
    this.discountInfo,
    required this.venueTypes,
    required this.expiresAt,
  });
}

class SocialRecommendation {
  final String id;
  final String title;
  final String description;
  final SocialTrigger socialTrigger;
  final String actionType;
  final int potentialConnections;
  final List<String> mutualInterests;

  SocialRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.socialTrigger,
    required this.actionType,
    required this.potentialConnections,
    required this.mutualInterests,
  });
}

class ContextualFactors {
  final String timeOfDay;
  final String dayOfWeek;
  final WeatherCondition weather;
  final UserContext? userContext;
  final String? location;
  final bool isRushHour;
  final bool isWeekend;
  final List<String> seasonalFactors;
  final List<String> localEvents;
  final String trafficLevel;

  ContextualFactors({
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.weather,
    this.userContext,
    this.location,
    required this.isRushHour,
    required this.isWeekend,
    required this.seasonalFactors,
    required this.localEvents,
    required this.trafficLevel,
  });
}

class UserInteractionFeedback {
  final String recommendationId;
  final FeedbackType feedbackType;
  final double rating;
  final List<String> likedAspects;
  final List<String> dislikedAspects;
  final String? comment;

  UserInteractionFeedback({
    required this.recommendationId,
    required this.feedbackType,
    required this.rating,
    required this.likedAspects,
    required this.dislikedAspects,
    this.comment,
  });
}

// ============================================================================
// ENUMS
// ============================================================================

enum RecommendationType {
  venue,
  experience,
  social,
  event,
}

enum RecommendationPriority {
  low,
  medium,
  high,
  urgent,
}

enum UrgencyLevel {
  low,
  medium,
  high,
  critical,
}

enum SocialTrigger {
  friendActivity,
  similarUsers,
  groupPlanning,
  eventInvitation,
}

enum FeedbackType {
  liked,
  disliked,
  visited,
  saved,
  shared,
}

// ============================================================================
// EXTENSIONS
// ============================================================================

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1);
  }
}