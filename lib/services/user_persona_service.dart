import 'dart:math';
import '../models/models.dart';
import 'vibe_definition_service.dart';

class UserPersonaService {
  // ============================================================================
  // SMART VIBE COMBINATION PERSONAS
  // ============================================================================

  /// Generate user persona based on vibe combination
  static UserPersona generatePersona(VibeProfile vibeProfile, {
    DateTime? currentTime,
    WeatherCondition? weather,
    UserContext? context,
  }) {
    final primaryVibes = vibeProfile.primaryVibes.take(3).toList();
    final vibeScores = vibeProfile.vibeScores;
    
    // Apply dynamic adjustments
    final adjustedVibes = _applyDynamicAdjustments(
      primaryVibes, 
      vibeScores,
      currentTime ?? DateTime.now(),
      weather,
      context,
    );

    // Find matching persona pattern
    final personaPattern = _findBestPersonaMatch(adjustedVibes);
    
    return UserPersona(
      id: _generatePersonaId(adjustedVibes),
      name: personaPattern.name,
      emoji: personaPattern.emoji,
      description: personaPattern.description,
      primaryVibes: adjustedVibes,
      traits: personaPattern.traits,
      preferences: personaPattern.preferences,
      timePreferences: personaPattern.timePreferences,
      venueTypes: personaPattern.venueTypes,
      priceRange: personaPattern.priceRange,
      socialStyle: personaPattern.socialStyle,
      explorationLevel: personaPattern.explorationLevel,
      tags: personaPattern.tags,
      contextualBoosts: _getContextualBoosts(currentTime, weather, context),
      generatedAt: DateTime.now(),
    );
  }

  /// Get recommended venues based on persona
  static List<String> getPersonaVenueRecommendations(UserPersona persona, {
    String? timeOfDay,
    WeatherCondition? weather,
  }) {
    var recommendations = List<String>.from(persona.venueTypes);
    
    // Apply time-based venue filtering
    if (timeOfDay != null) {
      recommendations = _filterVenuesByTime(recommendations, timeOfDay);
    }
    
    // Apply weather-based filtering
    if (weather != null) {
      recommendations = _filterVenuesByWeather(recommendations, weather);
    }
    
    return recommendations;
  }

  /// Update persona based on user behavior
  static UserPersona evolvePersona(
    UserPersona currentPersona,
    List<String> recentVibeChoices,
    Map<String, double> behaviorMetrics,
  ) {
    final updatedVibes = _calculateEvolvedVibes(
      currentPersona.primaryVibes,
      recentVibeChoices,
      behaviorMetrics,
    );

    return generatePersona(
      VibeProfile(
        primaryVibes: updatedVibes,
        vibeScores: _convertVibesToScores(updatedVibes),
        vibeEvolution: [],
        contextualVibes: ContextualVibes(
          contextVibeMap: {},
          lastUpdated: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  // ============================================================================
  // PERSONA PATTERN DEFINITIONS
  // ============================================================================

  static final List<PersonaPattern> _personaPatterns = [
    // Classic Cafe Culture
    PersonaPattern(
      vibeSignature: ['cozy', 'aesthetic', 'breakfast'],
      name: 'Cafe Connoisseur',
      emoji: '☕',
      description: 'Lives for beautiful morning rituals and Instagram-worthy coffee moments',
      traits: [
        'Morning person',
        'Aesthetic appreciation',
        'Coffee enthusiast',
        'Social media savvy',
        'Routine-oriented',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['7:00-11:00', '14:00-17:00'],
        preferredDays: ['weekend', 'weekday_morning'],
        avoidTimes: ['late_night'],
        socialGroupSize: '1-3',
        planningStyle: 'planned',
      ),
      timePreferences: {
        'morning': 0.9,
        'afternoon': 0.7,
        'evening': 0.3,
        'night': 0.1,
      },
      venueTypes: [
        'specialty_coffee',
        'brunch_cafe',
        'artisan_bakery',
        'aesthetic_cafe',
        'coworking_cafe',
      ],
      priceRange: 0.6,
      socialStyle: 'intimate_small_groups',
      explorationLevel: 0.4,
      tags: ['coffee_lover', 'morning_person', 'aesthetic', 'routine'],
    ),

    // High-Energy Social
    PersonaPattern(
      vibeSignature: ['active', 'social', 'lateNight'],
      name: 'Nightlife Explorer',
      emoji: '🌃',
      description: 'Thrives in high-energy environments and late-night social scenes',
      traits: [
        'Night owl',
        'Highly social',
        'Energy-driven',
        'Group organizer',
        'Experience collector',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['19:00-02:00'],
        preferredDays: ['friday', 'saturday', 'weekend'],
        avoidTimes: ['early_morning'],
        socialGroupSize: '4+',
        planningStyle: 'spontaneous',
      ),
      timePreferences: {
        'morning': 0.2,
        'afternoon': 0.4,
        'evening': 0.8,
        'night': 1.0,
      },
      venueTypes: [
        'rooftop_bar',
        'dance_club',
        'sports_bar',
        'karaoke',
        'night_market',
      ],
      priceRange: 0.7,
      socialStyle: 'large_groups',
      explorationLevel: 0.8,
      tags: ['night_owl', 'social_butterfly', 'energy', 'party'],
    ),

    // Romantic Luxury
    PersonaPattern(
      vibeSignature: ['intimate', 'luxurious', 'dateNight'],
      name: 'Romance Curator',
      emoji: '💕',
      description: 'Seeks magical moments and creates unforgettable romantic experiences',
      traits: [
        'Romantic idealist',
        'Quality over quantity',
        'Special occasion focused',
        'Detail-oriented',
        'Experience connoisseur',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['18:00-22:00'],
        preferredDays: ['friday', 'saturday', 'special_occasions'],
        avoidTimes: ['busy_lunch_hours'],
        socialGroupSize: '2',
        planningStyle: 'carefully_planned',
      ),
      timePreferences: {
        'morning': 0.3,
        'afternoon': 0.5,
        'evening': 1.0,
        'night': 0.6,
      },
      venueTypes: [
        'fine_dining',
        'wine_bar',
        'rooftop_terrace',
        'romantic_restaurant',
        'cocktail_lounge',
      ],
      priceRange: 0.9,
      socialStyle: 'couples',
      explorationLevel: 0.5,
      tags: ['romantic', 'luxury', 'special_occasions', 'intimate'],
    ),

    // Budget Adventure Seeker
    PersonaPattern(
      vibeSignature: ['adventurous', 'hiddenGem', 'budgetFriend'],
      name: 'Local Discovery Hunter',
      emoji: '🕵️',
      description: 'Uncovers the city\'s best-kept secrets without breaking the bank',
      traits: [
        'Bargain hunter',
        'Local culture enthusiast',
        'Authentic experience seeker',
        'Word-of-mouth networker',
        'Anti-mainstream',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['flexible'],
        preferredDays: ['any_day'],
        avoidTimes: ['peak_hours'],
        socialGroupSize: '2-4',
        planningStyle: 'semi_spontaneous',
      ),
      timePreferences: {
        'morning': 0.6,
        'afternoon': 0.8,
        'evening': 0.7,
        'night': 0.5,
      },
      venueTypes: [
        'hole_in_wall',
        'ethnic_restaurant',
        'food_truck',
        'local_market',
        'neighborhood_cafe',
      ],
      priceRange: 0.3,
      socialStyle: 'small_groups',
      explorationLevel: 0.9,
      tags: ['budget_conscious', 'local', 'authentic', 'explorer'],
    ),

    // Digital Nomad
    PersonaPattern(
      vibeSignature: ['chill', 'coworking', 'quickBite'],
      name: 'Digital Nomad',
      emoji: '💻',
      description: 'Seamlessly blends work and lifestyle in productivity-friendly spaces',
      traits: [
        'Location independent',
        'Efficiency-focused',
        'Tech-savvy',
        'Flexible schedule',
        'Productivity optimizer',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['9:00-17:00', '20:00-22:00'],
        preferredDays: ['weekday'],
        avoidTimes: ['peak_lunch', 'late_night'],
        socialGroupSize: '1-2',
        planningStyle: 'flexible',
      ),
      timePreferences: {
        'morning': 0.8,
        'afternoon': 0.9,
        'evening': 0.6,
        'night': 0.3,
      },
      venueTypes: [
        'coworking_cafe',
        'hotel_lobby',
        'quiet_restaurant',
        'library_cafe',
        'business_lounge',
      ],
      priceRange: 0.6,
      socialStyle: 'solo_or_small',
      explorationLevel: 0.4,
      tags: ['remote_work', 'productivity', 'flexible', 'tech'],
    ),

    // Health & Wellness
    PersonaPattern(
      vibeSignature: ['wellness', 'outdoor', 'breakfast'],
      name: 'Wellness Warrior',
      emoji: '🌱',
      description: 'Champions healthy living through mindful food and nature connection',
      traits: [
        'Health-conscious',
        'Nature lover',
        'Mindful living',
        'Early riser',
        'Balance seeker',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['6:00-10:00', '17:00-19:00'],
        preferredDays: ['any_day'],
        avoidTimes: ['late_night'],
        socialGroupSize: '1-3',
        planningStyle: 'routine_based',
      ),
      timePreferences: {
        'morning': 1.0,
        'afternoon': 0.7,
        'evening': 0.5,
        'night': 0.1,
      },
      venueTypes: [
        'juice_bar',
        'organic_cafe',
        'garden_restaurant',
        'healthy_restaurant',
        'meditation_cafe',
      ],
      priceRange: 0.7,
      socialStyle: 'wellness_community',
      explorationLevel: 0.6,
      tags: ['health', 'wellness', 'organic', 'mindful'],
    ),

    // Fitness Enthusiast
    PersonaPattern(
      vibeSignature: ['fitness', 'active', 'wellness'],
      name: 'Fitness Fanatic',
      emoji: '💪',
      description: 'Fuels an active lifestyle with performance-focused nutrition',
      traits: [
        'Fitness-focused',
        'Goal-oriented',
        'Energy-driven',
        'Performance-minded',
        'Community-oriented',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['6:00-9:00', '17:00-20:00'],
        preferredDays: ['any_day'],
        avoidTimes: ['mid_afternoon'],
        socialGroupSize: '2-5',
        planningStyle: 'routine_based',
      ),
      timePreferences: {
        'morning': 0.9,
        'afternoon': 0.6,
        'evening': 0.8,
        'night': 0.3,
      },
      venueTypes: [
        'protein_bar',
        'gym_cafe',
        'smoothie_shop',
        'athletic_restaurant',
        'recovery_lounge',
      ],
      priceRange: 0.6,
      socialStyle: 'fitness_community',
      explorationLevel: 0.5,
      tags: ['fitness', 'performance', 'protein', 'active'],
    ),

    // Cultural Explorer
    PersonaPattern(
      vibeSignature: ['adventurous', 'aesthetic', 'social'],
      name: 'Culture Collector',
      emoji: '🎭',
      description: 'Seeks authentic cultural experiences and artistic inspiration',
      traits: [
        'Culturally curious',
        'Art appreciator',
        'Story collector',
        'Experience documentarian',
        'Community connector',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['14:00-18:00', '19:00-22:00'],
        preferredDays: ['weekend', 'cultural_events'],
        avoidTimes: ['early_morning'],
        socialGroupSize: '2-6',
        planningStyle: 'event_driven',
      ),
      timePreferences: {
        'morning': 0.4,
        'afternoon': 0.8,
        'evening': 0.9,
        'night': 0.6,
      },
      venueTypes: [
        'art_gallery_cafe',
        'cultural_center',
        'ethnic_restaurant',
        'live_music_venue',
        'museum_cafe',
      ],
      priceRange: 0.6,
      socialStyle: 'cultural_groups',
      explorationLevel: 0.8,
      tags: ['culture', 'art', 'music', 'authentic'],
    ),

    // Luxury Lifestyle
    PersonaPattern(
      vibeSignature: ['luxurious', 'aesthetic', 'business'],
      name: 'Luxury Lifestyle Curator',
      emoji: '✨',
      description: 'Curates exceptional experiences with impeccable taste and style',
      traits: [
        'Quality connoisseur',
        'Style influencer',
        'Network builder',
        'Trendsetter',
        'Experience perfectionist',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['12:00-14:00', '19:00-22:00'],
        preferredDays: ['weekday_lunch', 'weekend_evening'],
        avoidTimes: ['busy_periods'],
        socialGroupSize: '2-4',
        planningStyle: 'meticulously_planned',
      ),
      timePreferences: {
        'morning': 0.6,
        'afternoon': 0.8,
        'evening': 1.0,
        'night': 0.7,
      },
      venueTypes: [
        'michelin_restaurant',
        'luxury_hotel_bar',
        'private_club',
        'champagne_bar',
        'exclusive_lounge',
      ],
      priceRange: 1.0,
      socialStyle: 'exclusive_circles',
      explorationLevel: 0.4,
      tags: ['luxury', 'exclusive', 'premium', 'style'],
    ),

    // Chill Socializer
    PersonaPattern(
      vibeSignature: ['chill', 'social', 'outdoor'],
      name: 'Laid-Back Social',
      emoji: '😎',
      description: 'Creates relaxed social moments in beautiful, pressure-free environments',
      traits: [
        'Stress-free approach',
        'Easy-going nature',
        'Natural connector',
        'Atmosphere appreciator',
        'Balance maintainer',
      ],
      preferences: PersonaPreferences(
        peakTimes: ['15:00-18:00', '20:00-23:00'],
        preferredDays: ['weekend', 'casual_hangouts'],
        avoidTimes: ['rush_hours'],
        socialGroupSize: '3-6',
        planningStyle: 'loose_plans',
      ),
      timePreferences: {
        'morning': 0.5,
        'afternoon': 0.8,
        'evening': 0.9,
        'night': 0.6,
      },
      venueTypes: [
        'beach_bar',
        'garden_cafe',
        'brewery',
        'park_restaurant',
        'casual_terrace',
      ],
      priceRange: 0.5,
      socialStyle: 'relaxed_groups',
      explorationLevel: 0.6,
      tags: ['chill', 'relaxed', 'outdoor', 'social'],
    ),
  ];

  // ============================================================================
  // DYNAMIC ADJUSTMENT SYSTEM
  // ============================================================================

  static List<String> _applyDynamicAdjustments(
    List<String> baseVibes,
    Map<String, VibeScore> vibeScores,
    DateTime currentTime,
    WeatherCondition? weather,
    UserContext? context,
  ) {
    var adjustedVibes = List<String>.from(baseVibes);
    final adjustments = <String, double>{};

    // Time-based adjustments
    _applyTimeBasedAdjustments(adjustments, currentTime);
    
    // Weather-based adjustments
    if (weather != null) {
      _applyWeatherAdjustments(adjustments, weather);
    }
    
    // Context-based adjustments
    if (context != null) {
      _applyContextAdjustments(adjustments, context);
    }

    // Apply adjustments to create modified vibe list
    final modifiedVibes = <String, double>{};
    
    // Start with base vibes
    for (final vibe in adjustedVibes) {
      final baseScore = vibeScores[vibe]?.score ?? 0.7;
      modifiedVibes[vibe] = baseScore;
    }
    
    // Apply dynamic boosts
    adjustments.forEach((vibe, boost) {
      modifiedVibes[vibe] = (modifiedVibes[vibe] ?? 0.5) + boost;
    });

    // Sort by adjusted scores and return top vibes
    final sortedVibes = modifiedVibes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedVibes.take(3).map((e) => e.key).toList();
  }

  static void _applyTimeBasedAdjustments(
    Map<String, double> adjustments,
    DateTime currentTime,
  ) {
    final hour = currentTime.hour;
    final isWeekend = currentTime.weekday >= 6;
    
    // Morning boosts (6-11 AM)
    if (hour >= 6 && hour <= 11) {
      adjustments['breakfast'] = 0.3;
      adjustments['coworking'] = 0.2;
      adjustments['wellness'] = 0.2;
      adjustments['fitness'] = 0.25;
    }
    
    // Lunch time (11 AM - 2 PM)
    if (hour >= 11 && hour <= 14) {
      adjustments['business'] = 0.3;
      adjustments['quickBite'] = 0.2;
      adjustments['coworking'] = 0.15;
    }
    
    // Afternoon (2-6 PM)
    if (hour >= 14 && hour <= 18) {
      adjustments['aesthetic'] = 0.2;
      adjustments['cozy'] = 0.15;
      adjustments['outdoor'] = 0.2;
    }
    
    // Evening (6-10 PM)
    if (hour >= 18 && hour <= 22) {
      adjustments['social'] = 0.3;
      adjustments['dateNight'] = 0.25;
      adjustments['intimate'] = 0.2;
    }
    
    // Late night (10 PM+)
    if (hour >= 22 || hour <= 2) {
      adjustments['lateNight'] = 0.4;
      adjustments['active'] = 0.2;
    }
    
    // Weekend adjustments
    if (isWeekend) {
      adjustments['adventurous'] = 0.2;
      adjustments['social'] = 0.15;
      adjustments['chill'] = 0.15;
      
      // Weekend brunch boost
      if (hour >= 9 && hour <= 14) {
        adjustments['breakfast'] = 0.25;
        adjustments['aesthetic'] = 0.2;
      }
    }
  }

  static void _applyWeatherAdjustments(
    Map<String, double> adjustments,
    WeatherCondition weather,
  ) {
    switch (weather) {
      case WeatherCondition.rainy:
        adjustments['cozy'] = 0.3;
        adjustments['indoor'] = 0.25;
        adjustments['intimate'] = 0.2;
        adjustments['outdoor'] = -0.4; // Negative boost (reduce)
        break;
        
      case WeatherCondition.sunny:
        adjustments['outdoor'] = 0.3;
        adjustments['aesthetic'] = 0.2;
        adjustments['active'] = 0.15;
        break;
        
      case WeatherCondition.hot:
        adjustments['chill'] = 0.2;
        adjustments['outdoor'] = -0.2;
        adjustments['indoor'] = 0.15;
        break;
        
      case WeatherCondition.cold:
        adjustments['cozy'] = 0.3;
        adjustments['indoor'] = 0.2;
        adjustments['warm'] = 0.25;
        break;
        
      case WeatherCondition.windy:
        adjustments['indoor'] = 0.2;
        adjustments['cozy'] = 0.15;
        break;
      case WeatherCondition.cloudy:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  static void _applyContextAdjustments(
    Map<String, double> adjustments,
    UserContext context,
  ) {
    switch (context) {
      case UserContext.payday:
        adjustments['luxurious'] = 0.3;
        adjustments['aesthetic'] = 0.2;
        adjustments['budgetFriend'] = -0.2;
        break;
        
      case UserContext.budgetMode:
        adjustments['budgetFriend'] = 0.4;
        adjustments['hiddenGem'] = 0.2;
        adjustments['luxurious'] = -0.3;
        break;
        
      case UserContext.celebration:
        adjustments['luxurious'] = 0.3;
        adjustments['social'] = 0.25;
        adjustments['intimate'] = 0.2;
        break;
        
      case UserContext.workMode:
        adjustments['coworking'] = 0.4;
        adjustments['business'] = 0.3;
        adjustments['chill'] = 0.15;
        break;
        
      case UserContext.dateNight:
        adjustments['intimate'] = 0.4;
        adjustments['dateNight'] = 0.35;
        adjustments['luxurious'] = 0.2;
        break;
        
      case UserContext.groupHangout:
        adjustments['social'] = 0.4;
        adjustments['active'] = 0.25;
        adjustments['chill'] = 0.2;
        break;
        
      case UserContext.selfCare:
        adjustments['wellness'] = 0.4;
        adjustments['cozy'] = 0.3;
        adjustments['outdoor'] = 0.2;
        break;
      case UserContext.exploration:
        // TODO: Handle this case.
        throw UnimplementedError();
      case UserContext.routine:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  static PersonaPattern _findBestPersonaMatch(List<String> vibes) {
    double bestScore = 0.0;
    PersonaPattern? bestMatch;

    for (final pattern in _personaPatterns) {
      final score = _calculatePatternMatchScore(vibes, pattern.vibeSignature);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = pattern;
      }
    }

    // If no good match found, create a generic explorer persona
    return bestMatch ?? _createGenericPersona(vibes);
  }

  static double _calculatePatternMatchScore(
    List<String> userVibes,
    List<String> patternVibes,
  ) {
    final intersection = userVibes.where((vibe) => patternVibes.contains(vibe)).length;
    final union = {...userVibes, ...patternVibes}.length;
    return union > 0 ? intersection / union : 0.0;
  }

  static PersonaPattern _createGenericPersona(List<String> vibes) {
    return PersonaPattern(
      vibeSignature: vibes,
      name: 'Vibe Explorer',
      emoji: '🎯',
      description: 'Unique combination of vibes creating a personalized experience',
      traits: ['Unique', 'Exploratory', 'Adaptive'],
      preferences: PersonaPreferences(
        peakTimes: ['flexible'],
        preferredDays: ['any_day'],
        avoidTimes: [],
        socialGroupSize: '2-4',
        planningStyle: 'adaptive',
      ),
      timePreferences: {
        'morning': 0.5,
        'afternoon': 0.6,
        'evening': 0.7,
        'night': 0.4,
      },
      venueTypes: ['diverse_options'],
      priceRange: 0.6,
      socialStyle: 'adaptive',
      explorationLevel: 0.7,
      tags: ['unique', 'explorer', 'adaptive'],
    );
  }

  static String _generatePersonaId(List<String> vibes) {
    return vibes.join('_');
  }

  static Map<String, double> _getContextualBoosts(
    DateTime? currentTime,
    WeatherCondition? weather,
    UserContext? context,
  ) {
    final boosts = <String, double>{};
    
    if (currentTime != null) {
      _applyTimeBasedAdjustments(boosts, currentTime);
    }
    
    if (weather != null) {
      _applyWeatherAdjustments(boosts, weather);
    }
    
    if (context != null) {
      _applyContextAdjustments(boosts, context);
    }
    
    return boosts;
  }

  static List<String> _filterVenuesByTime(List<String> venues, String timeOfDay) {
    // Implementation for time-based venue filtering
    return venues; // Simplified for now
  }

  static List<String> _filterVenuesByWeather(List<String> venues, WeatherCondition weather) {
    // Implementation for weather-based venue filtering
    return venues; // Simplified for now
  }

  static List<String> _calculateEvolvedVibes(
    List<String> currentVibes,
    List<String> recentChoices,
    Map<String, double> behaviorMetrics,
  ) {
    // Weighted combination of current and recent preferences
    final vibeWeights = <String, double>{};
    
    // Current vibes get base weight
    for (final vibe in currentVibes) {
      vibeWeights[vibe] = 0.6;
    }
    
    // Recent choices get additional weight
    for (final choice in recentChoices) {
      vibeWeights[choice] = (vibeWeights[choice] ?? 0.0) + 0.4;
    }
    
    // Sort and return top vibes
    final sortedVibes = vibeWeights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedVibes.take(3).map((e) => e.key).toList();
  }

  static Map<String, VibeScore> _convertVibesToScores(List<String> vibes) {
    final scores = <String, VibeScore>{};
    for (int i = 0; i < vibes.length; i++) {
      scores[vibes[i]] = VibeScore(
        vibeId: vibes[i],
        score: 0.9 - (i * 0.1),
        lastUpdated: DateTime.now(),
        interactionCount: 1,
      );
    }
    return scores;
  }
}

// ============================================================================
// PERSONA DATA CLASSES
// ============================================================================

class UserPersona {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<String> primaryVibes;
  final List<String> traits;
  final PersonaPreferences preferences;
  final Map<String, double> timePreferences;
  final List<String> venueTypes;
  final double priceRange;
  final String socialStyle;
  final double explorationLevel;
  final List<String> tags;
  final Map<String, double> contextualBoosts;
  final DateTime generatedAt;

  UserPersona({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.primaryVibes,
    required this.traits,
    required this.preferences,
    required this.timePreferences,
    required this.venueTypes,
    required this.priceRange,
    required this.socialStyle,
    required this.explorationLevel,
    required this.tags,
    required this.contextualBoosts,
    required this.generatedAt,
  });
}

class PersonaPattern {
  final List<String> vibeSignature;
  final String name;
  final String emoji;
  final String description;
  final List<String> traits;
  final PersonaPreferences preferences;
  final Map<String, double> timePreferences;
  final List<String> venueTypes;
  final double priceRange;
  final String socialStyle;
  final double explorationLevel;
  final List<String> tags;

  PersonaPattern({
    required this.vibeSignature,
    required this.name,
    required this.emoji,
    required this.description,
    required this.traits,
    required this.preferences,
    required this.timePreferences,
    required this.venueTypes,
    required this.priceRange,
    required this.socialStyle,
    required this.explorationLevel,
    required this.tags,
  });
}

class PersonaPreferences {
  final List<String> peakTimes;
  final List<String> preferredDays;
  final List<String> avoidTimes;
  final String socialGroupSize;
  final String planningStyle;

  PersonaPreferences({
    required this.peakTimes,
    required this.preferredDays,
    required this.avoidTimes,
    required this.socialGroupSize,
    required this.planningStyle,
  });
}

// ============================================================================
// ENUMS FOR CONTEXT
// ============================================================================

enum WeatherCondition {
  sunny,
  rainy,
  cloudy,
  hot,
  cold,
  windy,
}

enum UserContext {
  payday,
  budgetMode,
  celebration,
  workMode,
  dateNight,
  groupHangout,
  selfCare,
  exploration,
  routine,
}