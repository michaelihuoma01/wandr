import 'package:json_annotation/json_annotation.dart';

part 'vibe_tag_models.g.dart';

// ============================================================================
// UNIFIED VIBE TAG SYSTEM
// ============================================================================

@JsonSerializable()
class VibeTag {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String category;
  final List<String> synonyms;
  final String color; // Hex color for visual consistency
  final String icon; // Icon name for UI
  final double popularity; // 0.0-1.0 how popular this vibe is
  final Map<String, double> contextWeights; // How relevant in different contexts
  final DateTime createdAt;
  final DateTime lastUsed;
  final int usageCount;

  const VibeTag({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.category,
    required this.synonyms,
    required this.color,
    required this.icon,
    required this.popularity,
    required this.contextWeights,
    required this.createdAt,
    required this.lastUsed,
    required this.usageCount,
  });

  factory VibeTag.fromJson(Map<String, dynamic> json) => _$VibeTagFromJson(json);
  Map<String, dynamic> toJson() => _$VibeTagToJson(this);

  VibeTag copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    String? category,
    List<String>? synonyms,
    String? color,
    String? icon,
    double? popularity,
    Map<String, double>? contextWeights,
    DateTime? createdAt,
    DateTime? lastUsed,
    int? usageCount,
  }) {
    return VibeTag(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      category: category ?? this.category,
      synonyms: synonyms ?? this.synonyms,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      popularity: popularity ?? this.popularity,
      contextWeights: contextWeights ?? this.contextWeights,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

// ============================================================================
// VIBE TAG ASSOCIATIONS (How entities connect to vibe tags)
// ============================================================================

@JsonSerializable()
class VibeTagAssociation {
  final String entityId; // ID of user, place, board, circle, etc.
  final String entityType; // 'user', 'place', 'board', 'circle', 'checkin'
  final String vibeTagId;
  final double strength; // 0.0-1.0 how strongly this entity relates to this vibe
  final String source; // 'user_selected', 'ai_detected', 'community_voted'
  final DateTime createdAt;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata; // Additional context data

  const VibeTagAssociation({
    required this.entityId,
    required this.entityType,
    required this.vibeTagId,
    required this.strength,
    required this.source,
    required this.createdAt,
    required this.lastUpdated,
    required this.metadata,
  });

  factory VibeTagAssociation.fromJson(Map<String, dynamic> json) => _$VibeTagAssociationFromJson(json);
  Map<String, dynamic> toJson() => _$VibeTagAssociationToJson(this);
}

// ============================================================================
// VIBE COMPATIBILITY & MATCHING
// ============================================================================

@JsonSerializable()
class VibeCompatibilityScore {
  final String entityId1;
  final String entityType1;
  final String entityId2;
  final String entityType2;
  final double overallScore; // 0.0-1.0 overall compatibility
  final Map<String, double> tagScores; // Per-tag compatibility scores
  final List<String> sharedVibes; // Common vibe tags
  final List<String> complementaryVibes; // Vibes that complement each other
  final DateTime calculatedAt;

  const VibeCompatibilityScore({
    required this.entityId1,
    required this.entityType1,
    required this.entityId2,
    required this.entityType2,
    required this.overallScore,
    required this.tagScores,
    required this.sharedVibes,
    required this.complementaryVibes,
    required this.calculatedAt,
  });

  factory VibeCompatibilityScore.fromJson(Map<String, dynamic> json) => _$VibeCompatibilityScoreFromJson(json);
  Map<String, dynamic> toJson() => _$VibeCompatibilityScoreToJson(this);
}

// ============================================================================
// VIBE CATEGORIES (Organize vibe tags)
// ============================================================================

@JsonSerializable()
class VibeCategory {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String color;
  final String icon;
  final int sortOrder;
  final List<String> vibeTagIds;

  const VibeCategory({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.color,
    required this.icon,
    required this.sortOrder,
    required this.vibeTagIds,
  });

  factory VibeCategory.fromJson(Map<String, dynamic> json) => _$VibeCategoryFromJson(json);
  Map<String, dynamic> toJson() => _$VibeCategoryToJson(this);
}

// ============================================================================
// PREDEFINED VIBE TAGS (Seed data)
// ============================================================================

class PredefinedVibeTags {
  static const Map<String, Map<String, dynamic>> coreTags = {
    // ENERGY VIBES
    'cozy': {
      'displayName': 'Cozy',
      'description': 'Warm, comfortable, intimate atmosphere',
      'category': 'energy',
      'synonyms': ['comfortable', 'snug', 'homey', 'intimate'],
      'color': '#D4A574',
      'icon': 'fireplace',
      'contextWeights': {'evening': 0.9, 'winter': 0.9, 'date': 0.8, 'rain': 0.9}
    },
    'energetic': {
      'displayName': 'Energetic',
      'description': 'High energy, lively, vibrant atmosphere',
      'category': 'energy',
      'synonyms': ['lively', 'vibrant', 'dynamic', 'buzzing'],
      'color': '#E74C3C',
      'icon': 'flash',
      'contextWeights': {'weekend': 0.9, 'evening': 0.8, 'group': 0.9}
    },
    'chill': {
      'displayName': 'Chill',
      'description': 'Relaxed, laid-back, peaceful vibe',
      'category': 'energy',
      'synonyms': ['relaxed', 'laid-back', 'mellow', 'peaceful'],
      'color': '#58D68D',
      'icon': 'leaf',
      'contextWeights': {'morning': 0.8, 'afternoon': 0.9, 'solo': 0.8}
    },

    // AESTHETIC VIBES  
    'aesthetic': {
      'displayName': 'Aesthetic',
      'description': 'Instagram-worthy, visually beautiful',
      'category': 'aesthetic',
      'synonyms': ['beautiful', 'photogenic', 'stunning', 'picture-perfect'],
      'color': '#E91E63',
      'icon': 'camera',
      'contextWeights': {'date': 0.9, 'weekend': 0.8, 'selfie': 1.0}
    },
    'minimalist': {
      'displayName': 'Minimalist',
      'description': 'Clean, simple, uncluttered design',
      'category': 'aesthetic',
      'synonyms': ['clean', 'simple', 'modern', 'sleek'],
      'color': '#95A5A6',
      'icon': 'square',
      'contextWeights': {'work': 0.8, 'focus': 0.9, 'zen': 0.8}
    },
    'vintage': {
      'displayName': 'Vintage',
      'description': 'Classic, retro, nostalgic charm',
      'category': 'aesthetic',
      'synonyms': ['retro', 'classic', 'nostalgic', 'timeless'],
      'color': '#B8860B',
      'icon': 'time',
      'contextWeights': {'date': 0.8, 'discovery': 0.7, 'unique': 0.9}
    },

    // SOCIAL VIBES
    'social': {
      'displayName': 'Social',
      'description': 'Great for meeting people and socializing',
      'category': 'social',
      
      'synonyms': ['friendly', 'welcoming', 'community', 'people-focused'],
      'color': '#3498DB',
      'icon': 'people',
      'contextWeights': {'weekend': 0.9, 'group': 1.0, 'networking': 0.9}
    },
    'intimate': {
      'displayName': 'Intimate',
      'description': 'Perfect for close conversations and connection',
      'category': 'social',
      'synonyms': ['romantic', 'private', 'personal', 'quiet'],
      'color': '#F1948A',
      'icon': 'heart',
      'contextWeights': {'date': 1.0, 'evening': 0.8, 'couple': 1.0}
    },
    'community': {
      'displayName': 'Community',
      'description': 'Local hub where neighbors gather',
      'category': 'social',
      'synonyms': ['local', 'neighborhood', 'gathering', 'inclusive'],
      'color': '#52C41A',
      'icon': 'home',
      'contextWeights': {'daily': 0.9, 'local': 1.0, 'regular': 0.8}
    },

    // EXPERIENCE VIBES
    'adventurous': {
      'displayName': 'Adventurous',
      'description': 'For trying new things and exploring',
      'category': 'experience',
      'synonyms': ['exciting', 'bold', 'daring', 'exploratory'],
      'color': '#27AE60',
      'icon': 'compass',
      'contextWeights': {'weekend': 0.8, 'discovery': 1.0, 'solo': 0.7}
    },
    'luxurious': {
      'displayName': 'Luxurious',
      'description': 'High-end, premium, indulgent experience',
      'category': 'experience',
      'synonyms': ['premium', 'high-end', 'exclusive', 'indulgent'],
      'color': '#AF7AC5',
      'icon': 'diamond',
      'contextWeights': {'celebration': 1.0, 'date': 0.9, 'special': 1.0}
    },
    'authentic': {
      'displayName': 'Authentic',
      'description': 'Genuine, traditional, real local experience',
      'category': 'experience',
      'synonyms': ['genuine', 'traditional', 'real', 'original'],
      'color': '#D35400',
      'icon': 'star',
      'contextWeights': {'cultural': 1.0, 'local': 0.9, 'discovery': 0.8}
    },

    // MOOD VIBES
    'romantic': {
      'displayName': 'Romantic',
      'description': 'Perfect for dates and romantic moments',
      'category': 'mood',
      'synonyms': ['dreamy', 'enchanting', 'lovely', 'charming'],
      'color': '#FF69B4',
      'icon': 'heart-outline',
      'contextWeights': {'date': 1.0, 'evening': 0.9, 'anniversary': 1.0}
    },
    'inspiring': {
      'displayName': 'Inspiring',
      'description': 'Motivating, uplifting, creativity-boosting',
      'category': 'mood',
      'synonyms': ['motivating', 'uplifting', 'creative', 'stimulating'],
      'color': '#FF6B35',
      'icon': 'bulb',
      'contextWeights': {'work': 0.8, 'creative': 1.0, 'solo': 0.8}
    },
    'peaceful': {
      'displayName': 'Peaceful',
      'description': 'Calm, serene, stress-relieving atmosphere',
      'category': 'mood',
      'synonyms': ['calm', 'serene', 'tranquil', 'zen'],
      'color': '#40E0D0',
      'icon': 'leaf-outline',
      'contextWeights': {'morning': 0.9, 'meditation': 1.0, 'solo': 0.9}
    },
  };

  static const Map<String, Map<String, dynamic>> categories = {
    'energy': {
      'displayName': 'Energy',
      'description': 'How does this place make you feel?',
      'color': '#E74C3C',
      'icon': 'flash',
      'sortOrder': 1,
    },
    'aesthetic': {
      'displayName': 'Aesthetic',
      'description': 'What does this place look like?',
      'color': '#E91E63',
      'icon': 'camera',
      'sortOrder': 2,
    },
    'social': {
      'displayName': 'Social',
      'description': 'Who is this place good for?',
      'color': '#3498DB',
      'icon': 'people',
      'sortOrder': 3,
    },
    'experience': {
      'displayName': 'Experience',
      'description': 'What kind of experience is this?',
      'color': '#27AE60',
      'icon': 'compass',
      'sortOrder': 4,
    },
    'mood': {
      'displayName': 'Mood',
      'description': 'What mood does this create?',
      'color': '#AF7AC5',
      'icon': 'happy',
      'sortOrder': 5,
    },
  };
}