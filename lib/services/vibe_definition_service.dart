import '../models/models.dart';

class VibeDefinitionService {
  // ============================================================================
  // COMPREHENSIVE VIBE DEFINITIONS & ATTRIBUTES
  // ============================================================================

  /// Get detailed definition and attributes for a specific vibe
  static VibeDefinition getVibeDefinition(String vibeId) {
    return _vibeDefinitions[vibeId] ?? _getDefaultDefinition(vibeId);
  }

  /// Get all vibe definitions organized by category
  static Map<String, List<VibeDefinition>> getAllVibesByCategory() {
    return {
      'Core Personality': _coreVibeDefinitions,
      'Dining Context': _diningVibeDefinitions,
      'Experience Modifiers': _experienceVibeDefinitions,
    };
  }

  /// Get vibe attributes for matching algorithms
  static VibeAttributes getVibeAttributes(String vibeId) {
    final definition = getVibeDefinition(vibeId);
    return definition.attributes;
  }

  /// Get vibes that are compatible/complementary
  static List<String> getCompatibleVibes(String vibeId) {
    final definition = getVibeDefinition(vibeId);
    return definition.compatibleVibes;
  }

  /// Get vibes that conflict with each other
  static List<String> getConflictingVibes(String vibeId) {
    final definition = getVibeDefinition(vibeId);
    return definition.conflictingVibes;
  }

  // ============================================================================
  // CORE VIBE DEFINITIONS
  // ============================================================================

  static final List<VibeDefinition> _coreVibeDefinitions = [
    VibeDefinition(
      id: 'cozy',
      name: 'Cozy',
      emoji: '🛋️',
      description: 'Intimate, comfortable spaces with warm atmosphere',
      keyAttributes: [
        'Intimate atmosphere',
        'Comfortable seating',
        'Warm lighting',
        'Quiet conversations',
        'Soft textures',
        'Home-like feel',
      ],
      venueTypes: ['cafe', 'wine_bar', 'bookstore_cafe', 'living_room_bar', 'tea_house'],
      timeContexts: ['morning', 'afternoon', 'rainy_day', 'winter'],
      attributes: VibeAttributes(
        energyLevel: 0.3,
        socialIntensity: 0.4,
        noiseLevel: 0.2,
        intimacyScore: 0.9,
        aestheticFocus: 0.7,
        priceRange: 0.6,
      ),
      compatibleVibes: ['intimate', 'aesthetic', 'wellness'],
      conflictingVibes: ['active', 'social', 'fitness'],
    ),

    VibeDefinition(
      id: 'active',
      name: 'Active',
      emoji: '⚡',
      description: 'High-energy spaces that get your blood pumping',
      keyAttributes: [
        'High energy atmosphere',
        'Upbeat music',
        'Dynamic environment',
        'Movement-friendly',
        'Stimulating vibes',
        'Motivational energy',
      ],
      venueTypes: ['sports_bar', 'dance_club', 'arcade', 'active_cafe', 'rooftop_bar'],
      timeContexts: ['evening', 'weekend', 'happy_hour', 'night'],
      attributes: VibeAttributes(
        energyLevel: 0.9,
        socialIntensity: 0.8,
        noiseLevel: 0.8,
        intimacyScore: 0.2,
        aestheticFocus: 0.5,
        priceRange: 0.6,
      ),
      compatibleVibes: ['social', 'adventurous', 'fitness'],
      conflictingVibes: ['cozy', 'intimate', 'chill'],
    ),

    VibeDefinition(
      id: 'aesthetic',
      name: 'Aesthetic',
      emoji: '📸',
      description: 'Instagram-worthy spots with stunning visual appeal',
      keyAttributes: [
        'Instagram-worthy',
        'Beautiful design',
        'Photogenic food',
        'Unique interiors',
        'Color-coordinated',
        'Artistic elements',
        'Perfect lighting for photos',
      ],
      venueTypes: ['trendy_cafe', 'art_gallery_cafe', 'rooftop_restaurant', 'concept_store', 'flower_cafe'],
      timeContexts: ['brunch', 'afternoon', 'golden_hour', 'weekend'],
      attributes: VibeAttributes(
        energyLevel: 0.6,
        socialIntensity: 0.7,
        noiseLevel: 0.5,
        intimacyScore: 0.5,
        aestheticFocus: 1.0,
        priceRange: 0.7,
      ),
      compatibleVibes: ['trendy', 'luxurious', 'cozy'],
      conflictingVibes: ['chill', 'budgetFriend'],
    ),

    VibeDefinition(
      id: 'adventurous',
      name: 'Adventurous',
      emoji: '🗺️',
      description: 'Off-the-beaten-path discoveries and unique experiences',
      keyAttributes: [
        'New experiences',
        'Hidden gems',
        'Off the beaten path',
        'Local discoveries',
        'Unique concepts',
        'Cultural immersion',
        'Unexpected finds',
      ],
      venueTypes: ['speakeasy', 'ethnic_restaurant', 'pop_up', 'food_truck', 'underground_bar'],
      timeContexts: ['weekend', 'vacation', 'exploration_day', 'any_time'],
      attributes: VibeAttributes(
        energyLevel: 0.7,
        socialIntensity: 0.6,
        noiseLevel: 0.6,
        intimacyScore: 0.4,
        aestheticFocus: 0.6,
        priceRange: 0.5,
      ),
      compatibleVibes: ['hiddenGem', 'active', 'social'],
      conflictingVibes: ['luxurious', 'cozy'],
    ),

    VibeDefinition(
      id: 'luxurious',
      name: 'Luxurious',
      emoji: '✨',
      description: 'Premium experiences with exceptional service and exclusivity',
      keyAttributes: [
        'Premium experience',
        'High-end service',
        'Exclusive feel',
        'Special treatment',
        'Fine dining',
        'Elegant atmosphere',
        'VIP experience',
      ],
      venueTypes: ['fine_dining', 'luxury_hotel_bar', 'private_club', 'champagne_bar', 'michelin_restaurant'],
      timeContexts: ['special_occasion', 'date_night', 'celebration', 'business_dinner'],
      attributes: VibeAttributes(
        energyLevel: 0.5,
        socialIntensity: 0.6,
        noiseLevel: 0.3,
        intimacyScore: 0.7,
        aestheticFocus: 0.9,
        priceRange: 1.0,
      ),
      compatibleVibes: ['intimate', 'aesthetic', 'business'],
      conflictingVibes: ['budgetFriend', 'chill', 'adventurous'],
    ),

    VibeDefinition(
      id: 'social',
      name: 'Social',
      emoji: '🤝',
      description: 'Community-focused spaces perfect for meeting people',
      keyAttributes: [
        'Group friendly',
        'Meet people',
        'Community feel',
        'Networking space',
        'Shared tables',
        'Interactive atmosphere',
        'Easy conversations',
      ],
      venueTypes: ['brewery', 'community_cafe', 'board_game_cafe', 'food_hall', 'pub'],
      timeContexts: ['after_work', 'weekend', 'networking_event', 'group_hangout'],
      attributes: VibeAttributes(
        energyLevel: 0.7,
        socialIntensity: 1.0,
        noiseLevel: 0.7,
        intimacyScore: 0.2,
        aestheticFocus: 0.5,
        priceRange: 0.6,
      ),
      compatibleVibes: ['active', 'adventurous', 'coworking'],
      conflictingVibes: ['intimate', 'cozy'],
    ),

    VibeDefinition(
      id: 'chill',
      name: 'Chill',
      emoji: '😌',
      description: 'Laid-back, relaxed atmosphere with no pressure',
      keyAttributes: [
        'Laid-back vibe',
        'Come as you are',
        'Relaxed atmosphere',
        'No pressure',
        'Casual dress code',
        'Unhurried pace',
        'Stress-free zone',
      ],
      venueTypes: ['beach_bar', 'park_cafe', 'local_diner', 'juice_bar', 'casual_restaurant'],
      timeContexts: ['lazy_sunday', 'vacation', 'casual_meetup', 'any_time'],
      attributes: VibeAttributes(
        energyLevel: 0.3,
        socialIntensity: 0.5,
        noiseLevel: 0.4,
        intimacyScore: 0.6,
        aestheticFocus: 0.4,
        priceRange: 0.4,
      ),
      compatibleVibes: ['outdoor', 'budgetFriend', 'wellness'],
      conflictingVibes: ['luxurious', 'active', 'business'],
    ),

    VibeDefinition(
      id: 'intimate',
      name: 'Intimate',
      emoji: '💕',
      description: 'Perfect for romantic dates and special moments',
      keyAttributes: [
        'Date-worthy',
        'Intimate setting',
        'Beautiful ambiance',
        'Special occasions',
        'Romantic lighting',
        'Private conversations',
        'Memorable experiences',
      ],
      venueTypes: ['wine_bar', 'romantic_restaurant', 'rooftop_terrace', 'cocktail_lounge', 'garden_restaurant'],
      timeContexts: ['date_night', 'anniversary', 'proposal', 'romantic_evening'],
      attributes: VibeAttributes(
        energyLevel: 0.4,
        socialIntensity: 0.3,
        noiseLevel: 0.3,
        intimacyScore: 1.0,
        aestheticFocus: 0.8,
        priceRange: 0.8,
      ),
      compatibleVibes: ['luxurious', 'aesthetic', 'cozy'],
      conflictingVibes: ['social', 'active', 'fitness'],
    ),

    VibeDefinition(
      id: 'fitness',
      name: 'Fitness',
      emoji: '💪',
      description: 'Health-focused spaces for active lifestyle enthusiasts',
      keyAttributes: [
        'Workout-friendly',
        'Health-conscious menu',
        'Protein-rich options',
        'Pre/post-gym vibes',
        'Athletic atmosphere',
        'Energy-boosting',
        'Fitness community',
      ],
      venueTypes: ['juice_bar', 'protein_cafe', 'gym_cafe', 'smoothie_shop', 'healthy_restaurant'],
      timeContexts: ['pre_workout', 'post_workout', 'morning', 'healthy_lifestyle'],
      attributes: VibeAttributes(
        energyLevel: 0.8,
        socialIntensity: 0.6,
        noiseLevel: 0.5,
        intimacyScore: 0.3,
        aestheticFocus: 0.6,
        priceRange: 0.6,
      ),
      compatibleVibes: ['wellness', 'active', 'outdoor'],
      conflictingVibes: ['luxurious', 'intimate', 'cozy'],
    ),
  ];

  // ============================================================================
  // DINING CONTEXT DEFINITIONS
  // ============================================================================

  static final List<VibeDefinition> _diningVibeDefinitions = [
    VibeDefinition(
      id: 'breakfast',
      name: 'Breakfast & Brunch',
      emoji: '🌅',
      description: 'Perfect morning and weekend brunch destinations',
      keyAttributes: [
        'Morning person spots',
        'Weekend brunch scenes',
        'Coffee culture',
        'Fresh pastries',
        'All-day breakfast',
        'Mimosa-friendly',
      ],
      venueTypes: ['brunch_cafe', 'bakery', 'coffee_shop', 'breakfast_restaurant', 'hotel_restaurant'],
      timeContexts: ['morning', 'weekend_brunch', 'early_bird', 'lazy_sunday'],
      attributes: VibeAttributes(
        energyLevel: 0.6,
        socialIntensity: 0.7,
        noiseLevel: 0.5,
        intimacyScore: 0.5,
        aestheticFocus: 0.7,
        priceRange: 0.6,
      ),
      compatibleVibes: ['aesthetic', 'cozy', 'social'],
      conflictingVibes: ['lateNight', 'active'],
    ),

    VibeDefinition(
      id: 'business',
      name: 'Business Dining',
      emoji: '💼',
      description: 'Professional atmosphere for meetings and networking',
      keyAttributes: [
        'Client meetings',
        'Power lunches',
        'Professional atmosphere',
        'Reliable WiFi',
        'Quiet enough for conversation',
        'Business-friendly hours',
      ],
      venueTypes: ['hotel_restaurant', 'upscale_cafe', 'business_district_restaurant', 'private_dining'],
      timeContexts: ['lunch', 'business_hours', 'networking', 'client_meeting'],
      attributes: VibeAttributes(
        energyLevel: 0.5,
        socialIntensity: 0.6,
        noiseLevel: 0.4,
        intimacyScore: 0.4,
        aestheticFocus: 0.7,
        priceRange: 0.8,
      ),
      compatibleVibes: ['luxurious', 'coworking', 'professional'],
      conflictingVibes: ['chill', 'active', 'fitness'],
    ),

    VibeDefinition(
      id: 'dateNight',
      name: 'Date Night',
      emoji: '🥂',
      description: 'Romantic dining experiences for special moments',
      keyAttributes: [
        'Romantic dinners',
        'Special occasions',
        'Intimate dining',
        'Wine selection',
        'Candlelit ambiance',
        'Memorable service',
      ],
      venueTypes: ['fine_dining', 'wine_bar', 'romantic_restaurant', 'rooftop_dining', 'private_booth'],
      timeContexts: ['dinner', 'date_night', 'anniversary', 'special_occasion'],
      attributes: VibeAttributes(
        energyLevel: 0.4,
        socialIntensity: 0.3,
        noiseLevel: 0.3,
        intimacyScore: 0.9,
        aestheticFocus: 0.8,
        priceRange: 0.8,
      ),
      compatibleVibes: ['intimate', 'luxurious', 'aesthetic'],
      conflictingVibes: ['social', 'fitness', 'chill'],
    ),

    VibeDefinition(
      id: 'quickBite',
      name: 'Quick Bites',
      emoji: '🏃',
      description: 'Fast, convenient dining for busy schedules',
      keyAttributes: [
        'Fast service',
        'Grab and go',
        'Casual eats',
        'Efficient ordering',
        'Counter service',
        'Time-friendly',
      ],
      venueTypes: ['food_truck', 'fast_casual', 'counter_service', 'grab_n_go', 'food_court'],
      timeContexts: ['lunch_break', 'between_meetings', 'on_the_go', 'quick_meal'],
      attributes: VibeAttributes(
        energyLevel: 0.7,
        socialIntensity: 0.4,
        noiseLevel: 0.6,
        intimacyScore: 0.2,
        aestheticFocus: 0.3,
        priceRange: 0.4,
      ),
      compatibleVibes: ['budgetFriend', 'fitness', 'coworking'],
      conflictingVibes: ['luxurious', 'intimate', 'dateNight'],
    ),

    VibeDefinition(
      id: 'lateNight',
      name: 'Late Night',
      emoji: '🌙',
      description: 'After-hours spots for night owls and late dining',
      keyAttributes: [
        'After hours',
        'Night owl spots',
        '24/7 options',
        'Late night menu',
        'Bar atmosphere',
        'Night scene',
      ],
      venueTypes: ['24h_diner', 'late_night_bar', 'night_club', 'ramen_shop', 'dive_bar'],
      timeContexts: ['late_night', 'after_party', 'shift_work', 'insomnia_eats'],
      attributes: VibeAttributes(
        energyLevel: 0.6,
        socialIntensity: 0.7,
        noiseLevel: 0.7,
        intimacyScore: 0.4,
        aestheticFocus: 0.4,
        priceRange: 0.5,
      ),
      compatibleVibes: ['active', 'social', 'adventurous'],
      conflictingVibes: ['breakfast', 'business', 'wellness'],
    ),
  ];

  // ============================================================================
  // EXPERIENCE MODIFIER DEFINITIONS
  // ============================================================================

  static final List<VibeDefinition> _experienceVibeDefinitions = [
    VibeDefinition(
      id: 'hiddenGem',
      name: 'Hidden Gems',
      emoji: '💎',
      description: 'Secret spots known only to locals and insiders',
      keyAttributes: [
        'Secret spots',
        'Local favorites',
        'Under the radar',
        'Word of mouth',
        'Authentic experiences',
        'Undiscovered treasures',
      ],
      venueTypes: ['speakeasy', 'hole_in_wall', 'family_restaurant', 'local_dive', 'neighborhood_cafe'],
      timeContexts: ['discovery_mode', 'local_exploration', 'insider_access'],
      attributes: VibeAttributes(
        energyLevel: 0.6,
        socialIntensity: 0.5,
        noiseLevel: 0.5,
        intimacyScore: 0.6,
        aestheticFocus: 0.4,
        priceRange: 0.5,
      ),
      compatibleVibes: ['adventurous', 'authentic', 'cozy'],
      conflictingVibes: ['trending', 'luxurious', 'aesthetic'],
    ),

    VibeDefinition(
      id: 'trending',
      name: 'Trending Now',
      emoji: '🔥',
      description: 'Viral hotspots and must-visit destinations',
      keyAttributes: [
        'New openings',
        'Viral places',
        'Must-try spots',
        'Social media buzz',
        'Popular destinations',
        'Current favorites',
      ],
      venueTypes: ['new_restaurant', 'pop_up', 'viral_cafe', 'influencer_spot', 'buzz_worthy'],
      timeContexts: ['weekend', 'social_media_worthy', 'trendy_scene'],
      attributes: VibeAttributes(
        energyLevel: 0.8,
        socialIntensity: 0.8,
        noiseLevel: 0.7,
        intimacyScore: 0.3,
        aestheticFocus: 0.9,
        priceRange: 0.7,
      ),
      compatibleVibes: ['aesthetic', 'social', 'active'],
      conflictingVibes: ['hiddenGem', 'chill', 'cozy'],
    ),

    VibeDefinition(
      id: 'outdoor',
      name: 'Outdoor Vibes',
      emoji: '🌿',
      description: 'Al fresco dining and nature-connected experiences',
      keyAttributes: [
        'Al fresco dining',
        'Beach/waterfront',
        'Garden settings',
        'Fresh air',
        'Natural lighting',
        'Scenic views',
      ],
      venueTypes: ['rooftop_bar', 'beachside_cafe', 'garden_restaurant', 'terrace_dining', 'park_cafe'],
      timeContexts: ['sunny_day', 'summer', 'nice_weather', 'sunset'],
      attributes: VibeAttributes(
        energyLevel: 0.6,
        socialIntensity: 0.7,
        noiseLevel: 0.5,
        intimacyScore: 0.5,
        aestheticFocus: 0.8,
        priceRange: 0.6,
      ),
      compatibleVibes: ['chill', 'aesthetic', 'wellness'],
      conflictingVibes: ['coworking', 'business'],
    ),

    VibeDefinition(
      id: 'coworking',
      name: 'Remote Working',
      emoji: '💻',
      description: 'Digital nomad-friendly spaces with work essentials',
      keyAttributes: [
        'High-speed WiFi',
        'Ample power outlets',
        'Comfortable seating',
        'Quiet work zones',
        'Long-stay friendly',
        'Professional atmosphere',
        'Good lighting',
        'Meeting spaces',
      ],
      venueTypes: ['coworking_cafe', 'business_lounge', 'hotel_lobby', 'library_cafe', 'work_friendly_restaurant'],
      timeContexts: ['work_hours', 'remote_work', 'digital_nomad', 'study_session'],
      attributes: VibeAttributes(
        energyLevel: 0.5,
        socialIntensity: 0.4,
        noiseLevel: 0.3,
        intimacyScore: 0.3,
        aestheticFocus: 0.6,
        priceRange: 0.6,
      ),
      compatibleVibes: ['business', 'chill', 'aesthetic'],
      conflictingVibes: ['active', 'social', 'lateNight'],
    ),

    VibeDefinition(
      id: 'wellness',
      name: 'Wellness Focus',
      emoji: '🧘',
      description: 'Health-conscious spaces for mindful living',
      keyAttributes: [
        'Healthy options',
        'Mindful spaces',
        'Clean eating',
        'Organic ingredients',
        'Calming atmosphere',
        'Wellness-focused',
      ],
      venueTypes: ['juice_bar', 'organic_cafe', 'vegan_restaurant', 'meditation_cafe', 'wellness_center'],
      timeContexts: ['health_journey', 'detox_mode', 'mindful_eating', 'self_care'],
      attributes: VibeAttributes(
        energyLevel: 0.5,
        socialIntensity: 0.5,
        noiseLevel: 0.3,
        intimacyScore: 0.5,
        aestheticFocus: 0.7,
        priceRange: 0.7,
      ),
      compatibleVibes: ['fitness', 'outdoor', 'cozy'],
      conflictingVibes: ['lateNight', 'luxurious', 'active'],
    ),

    VibeDefinition(
      id: 'budgetFriend',
      name: 'Budget Friendly',
      emoji: '💰',
      description: 'Great value spots that don\'t break the bank',
      keyAttributes: [
        'Great value',
        'Student deals',
        'Affordable luxury',
        'Happy hour specials',
        'Generous portions',
        'Local pricing',
      ],
      venueTypes: ['local_diner', 'student_cafe', 'happy_hour_spot', 'food_truck', 'ethnic_restaurant'],
      timeContexts: ['student_life', 'budget_conscious', 'everyday_dining', 'value_seeking'],
      attributes: VibeAttributes(
        energyLevel: 0.6,
        socialIntensity: 0.7,
        noiseLevel: 0.6,
        intimacyScore: 0.4,
        aestheticFocus: 0.4,
        priceRange: 0.2,
      ),
      compatibleVibes: ['chill', 'social', 'hiddenGem'],
      conflictingVibes: ['luxurious', 'aesthetic', 'business'],
    ),
  ];

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  static final Map<String, VibeDefinition> _vibeDefinitions = {
    for (var vibe in [
      ..._coreVibeDefinitions,
      ..._diningVibeDefinitions,
      ..._experienceVibeDefinitions,
    ]) vibe.id: vibe,
  };

  static VibeDefinition _getDefaultDefinition(String vibeId) {
    return VibeDefinition(
      id: vibeId,
      name: vibeId.toUpperCase(),
      emoji: '🎯',
      description: 'Custom vibe definition',
      keyAttributes: [],
      venueTypes: [],
      timeContexts: [],
      attributes: VibeAttributes(
        energyLevel: 0.5,
        socialIntensity: 0.5,
        noiseLevel: 0.5,
        intimacyScore: 0.5,
        aestheticFocus: 0.5,
        priceRange: 0.5,
      ),
      compatibleVibes: [],
      conflictingVibes: [],
    );
  }
}

// ============================================================================
// VIBE DEFINITION CLASSES
// ============================================================================

class VibeDefinition {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final List<String> keyAttributes;
  final List<String> venueTypes;
  final List<String> timeContexts;
  final VibeAttributes attributes;
  final List<String> compatibleVibes;
  final List<String> conflictingVibes;

  VibeDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.keyAttributes,
    required this.venueTypes,
    required this.timeContexts,
    required this.attributes,
    required this.compatibleVibes,
    required this.conflictingVibes,
  });
}

class VibeAttributes {
  final double energyLevel;      // 0.0 (low energy) to 1.0 (high energy)
  final double socialIntensity;  // 0.0 (solo-friendly) to 1.0 (highly social)
  final double noiseLevel;       // 0.0 (quiet) to 1.0 (loud)
  final double intimacyScore;    // 0.0 (public/open) to 1.0 (intimate/private)
  final double aestheticFocus;   // 0.0 (function over form) to 1.0 (highly aesthetic)
  final double priceRange;       // 0.0 (budget) to 1.0 (luxury)

  VibeAttributes({
    required this.energyLevel,
    required this.socialIntensity,
    required this.noiseLevel,
    required this.intimacyScore,
    required this.aestheticFocus,
    required this.priceRange,
  });

  /// Calculate compatibility score between two sets of vibe attributes
  double calculateCompatibility(VibeAttributes other) {
    final energyDiff = (energyLevel - other.energyLevel).abs();
    final socialDiff = (socialIntensity - other.socialIntensity).abs();
    final noiseDiff = (noiseLevel - other.noiseLevel).abs();
    final intimacyDiff = (intimacyScore - other.intimacyScore).abs();
    final aestheticDiff = (aestheticFocus - other.aestheticFocus).abs();
    final priceDiff = (priceRange - other.priceRange).abs();

    // Calculate weighted compatibility (lower differences = higher compatibility)
    final compatibility = 1.0 - (
      (energyDiff * 0.2) +
      (socialDiff * 0.2) +
      (noiseDiff * 0.15) +
      (intimacyDiff * 0.15) +
      (aestheticDiff * 0.15) +
      (priceDiff * 0.15)
    );

    return compatibility.clamp(0.0, 1.0);
  }
}