import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vibe_tag_models.dart';
import '../models/models.dart';
import '../models/circle_models.dart';

class VibeTagService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, VibeTag> _vibeTagCache = {};
  static final Map<String, List<VibeTagAssociation>> _associationCache = {};
  static bool _initialized = false;

  // ============================================================================
  // INITIALIZATION & CORE MANAGEMENT
  // ============================================================================

  /// Initialize the vibe tag system with predefined tags
  Future<void> initializeVibeSystem() async {
    if (_initialized) return;

    try {
      // Create categories first
      for (final categoryEntry in PredefinedVibeTags.categories.entries) {
        final categoryData = categoryEntry.value;
        final category = VibeCategory(
          id: categoryEntry.key,
          name: categoryEntry.key,
          displayName: categoryData['displayName'],
          description: categoryData['description'],
          color: categoryData['color'],
          icon: categoryData['icon'],
          sortOrder: categoryData['sortOrder'],
          vibeTagIds: [],
        );

        await _firestore.collection('vibe_categories').doc(categoryEntry.key).set(category.toJson(), SetOptions(merge: true));
      }

      // Create core vibe tags
      for (final tagEntry in PredefinedVibeTags.coreTags.entries) {
        final tagData = tagEntry.value;
        final vibeTag = VibeTag(
          id: tagEntry.key,
          name: tagEntry.key,
          displayName: tagData['displayName'],
          description: tagData['description'],
          category: tagData['category'],
          synonyms: List<String>.from(tagData['synonyms']),
          color: tagData['color'],
          icon: tagData['icon'],
          popularity: 0.5, // Start with neutral popularity
          contextWeights: Map<String, double>.from(tagData['contextWeights']),
          createdAt: DateTime.now(),
          lastUsed: DateTime.now(),
          usageCount: 0,
        );

        await _firestore.collection('vibe_tags').doc(tagEntry.key).set(vibeTag.toJson(), SetOptions(merge: true));
        _vibeTagCache[tagEntry.key] = vibeTag;
      }

      // Update category vibe tag lists
      for (final categoryEntry in PredefinedVibeTags.categories.entries) {
        final categoryId = categoryEntry.key;
        final vibeTagIds = PredefinedVibeTags.coreTags.entries
            .where((tag) => tag.value['category'] == categoryId)
            .map((tag) => tag.key)
            .toList();

        await _firestore.collection('vibe_categories').doc(categoryId).update({
          'vibeTagIds': vibeTagIds,
        });
      }

      _initialized = true;
      print('Vibe tag system initialized successfully');
    } catch (e) {
      print('Error initializing vibe tag system: $e');
    }
  }

  /// Get all available vibe tags
  Future<List<VibeTag>> getAllVibeTags() async {
    await initializeVibeSystem();
    
    if (_vibeTagCache.isNotEmpty) {
      return _vibeTagCache.values.toList();
    }

    try {
      final snapshot = await _firestore.collection('vibe_tags').get();
      final tags = snapshot.docs.map((doc) => VibeTag.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();

      // Update cache
      for (final tag in tags) {
        _vibeTagCache[tag.id] = tag;
      }

      return tags;
    } catch (e) {
      print('Error getting vibe tags: $e');
      return [];
    }
  }

  /// Get vibe tags by category
  Future<List<VibeTag>> getVibeTagsByCategory(String categoryId) async {
    final allTags = await getAllVibeTags();
    return allTags.where((tag) => tag.category == categoryId).toList();
  }

  /// Search vibe tags by name or synonym
  Future<List<VibeTag>> searchVibeTags(String query) async {
    final allTags = await getAllVibeTags();
    final lowerQuery = query.toLowerCase();
    
    return allTags.where((tag) {
      return tag.name.toLowerCase().contains(lowerQuery) ||
             tag.displayName.toLowerCase().contains(lowerQuery) ||
             tag.synonyms.any((synonym) => synonym.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // ============================================================================
  // ENTITY-VIBE ASSOCIATIONS
  // ============================================================================

  /// Associate vibe tags with any entity (user, place, board, circle, checkin)
  Future<void> associateVibesWithEntity({
    required String entityId,
    required String entityType,
    required List<String> vibeTagIds,
    String source = 'user_selected',
    Map<String, double>? customStrengths,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final batch = _firestore.batch();
      final now = DateTime.now();

      for (final vibeTagId in vibeTagIds) {
        final strength = customStrengths?[vibeTagId] ?? 1.0;
        
        final association = VibeTagAssociation(
          entityId: entityId,
          entityType: entityType,
          vibeTagId: vibeTagId,
          strength: strength,
          source: source,
          createdAt: now,
          lastUpdated: now,
          metadata: metadata ?? {},
        );

        final docRef = _firestore.collection('vibe_associations').doc('${entityType}_${entityId}_$vibeTagId');
        batch.set(docRef, association.toJson(), SetOptions(merge: true));

        // Update vibe tag usage
        final vibeTagRef = _firestore.collection('vibe_tags').doc(vibeTagId);
        batch.update(vibeTagRef, {
          'lastUsed': FieldValue.serverTimestamp(),
          'usageCount': FieldValue.increment(1),
        });
      }

      await batch.commit();
      
      // Clear cache for this entity
      _associationCache.remove('${entityType}_$entityId');
      
      print('Associated ${vibeTagIds.length} vibes with $entityType $entityId');
    } catch (e) {
      print('Error associating vibes with entity: $e');
    }
  }

  /// Get vibe associations for an entity
  Future<List<VibeTagAssociation>> getEntityVibeAssociations(String entityId, String entityType) async {
    final cacheKey = '${entityType}_$entityId';
    
    if (_associationCache.containsKey(cacheKey)) {
      return _associationCache[cacheKey]!;
    }

    try {
      final snapshot = await _firestore
          .collection('vibe_associations')
          .where('entityId', isEqualTo: entityId)
          .where('entityType', isEqualTo: entityType)
          .get();

      final associations = snapshot.docs.map((doc) => VibeTagAssociation.fromJson(doc.data())).toList();
      
      _associationCache[cacheKey] = associations;
      return associations;
    } catch (e) {
      print('Error getting entity vibe associations: $e');
      return [];
    }
  }

  /// Get entities that have specific vibe tags
  Future<List<String>> getEntitiesWithVibes(List<String> vibeTagIds, String entityType, {double minStrength = 0.5}) async {
    try {
      final results = <String>[];
      
      for (final vibeTagId in vibeTagIds) {
        final snapshot = await _firestore
            .collection('vibe_associations')
            .where('vibeTagId', isEqualTo: vibeTagId)
            .where('entityType', isEqualTo: entityType)
            .where('strength', isGreaterThanOrEqualTo: minStrength)
            .get();

        final entityIds = snapshot.docs.map((doc) => doc.data()['entityId'] as String).toList();
        results.addAll(entityIds);
      }

      return results.toSet().toList(); // Remove duplicates
    } catch (e) {
      print('Error getting entities with vibes: $e');
      return [];
    }
  }

  // ============================================================================
  // VIBE COMPATIBILITY & MATCHING
  // ============================================================================

  /// Calculate vibe compatibility between two entities
  Future<VibeCompatibilityScore> calculateVibeCompatibility({
    required String entityId1,
    required String entityType1,
    required String entityId2,
    required String entityType2,
  }) async {
    try {
      final vibes1 = await getEntityVibeAssociations(entityId1, entityType1);
      final vibes2 = await getEntityVibeAssociations(entityId2, entityType2);

      if (vibes1.isEmpty || vibes2.isEmpty) {
        return VibeCompatibilityScore(
          entityId1: entityId1,
          entityType1: entityType1,
          entityId2: entityId2,
          entityType2: entityType2,
          overallScore: 0.0,
          tagScores: {},
          sharedVibes: [],
          complementaryVibes: [],
          calculatedAt: DateTime.now(),
        );
      }

      // Create vibe maps for easier calculation
      final vibeMap1 = Map<String, double>.fromEntries(
        vibes1.map((v) => MapEntry(v.vibeTagId, v.strength))
      );
      final vibeMap2 = Map<String, double>.fromEntries(
        vibes2.map((v) => MapEntry(v.vibeTagId, v.strength))
      );

      // Calculate shared vibes
      final sharedVibes = vibeMap1.keys.where((vibeId) => vibeMap2.containsKey(vibeId)).toList();
      
      // Calculate per-tag compatibility scores
      final tagScores = <String, double>{};
      double totalScore = 0.0;
      int scoreCount = 0;

      for (final vibeId in sharedVibes) {
        final strength1 = vibeMap1[vibeId]!;
        final strength2 = vibeMap2[vibeId]!;
        
        // Use harmonic mean for compatibility (rewards mutual high scores)
        final compatibility = 2 * strength1 * strength2 / (strength1 + strength2);
        tagScores[vibeId] = compatibility;
        totalScore += compatibility;
        scoreCount++;
      }

      // Find complementary vibes (vibes that work well together)
      final complementaryVibes = await _findComplementaryVibes(vibeMap1.keys.toList(), vibeMap2.keys.toList());

      final overallScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;

      return VibeCompatibilityScore(
        entityId1: entityId1,
        entityType1: entityType1,
        entityId2: entityId2,
        entityType2: entityType2,
        overallScore: overallScore,
        tagScores: tagScores,
        sharedVibes: sharedVibes,
        complementaryVibes: complementaryVibes,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error calculating vibe compatibility: $e');
      return VibeCompatibilityScore(
        entityId1: entityId1,
        entityType1: entityType1,
        entityId2: entityId2,
        entityType2: entityType2,
        overallScore: 0.0,
        tagScores: {},
        sharedVibes: [],
        complementaryVibes: [],
        calculatedAt: DateTime.now(),
      );
    }
  }

  /// Get entities ranked by vibe compatibility
  Future<List<Map<String, dynamic>>> getCompatibleEntities({
    required String sourceEntityId,
    required String sourceEntityType,
    required String targetEntityType,
    int limit = 20,
    double minCompatibility = 0.3,
  }) async {
    try {
      // Get all potential target entities with vibes
      final targetEntityIds = await _getAllEntitiesWithVibes(targetEntityType);
      
      final compatibilityResults = <Map<String, dynamic>>[];

      for (final targetEntityId in targetEntityIds) {
        if (targetEntityId == sourceEntityId) continue; // Skip self

        final compatibility = await calculateVibeCompatibility(
          entityId1: sourceEntityId,
          entityType1: sourceEntityType,
          entityId2: targetEntityId,
          entityType2: targetEntityType,
        );

        if (compatibility.overallScore >= minCompatibility) {
          compatibilityResults.add({
            'entityId': targetEntityId,
            'entityType': targetEntityType,
            'compatibilityScore': compatibility,
          });
        }
      }

      // Sort by compatibility score (descending)
      compatibilityResults.sort((a, b) {
        final scoreA = (a['compatibilityScore'] as VibeCompatibilityScore).overallScore;
        final scoreB = (b['compatibilityScore'] as VibeCompatibilityScore).overallScore;
        return scoreB.compareTo(scoreA);
      });

      return compatibilityResults.take(limit).toList();
    } catch (e) {
      print('Error getting compatible entities: $e');
      return [];
    }
  }

  // ============================================================================
  // SMART RECOMMENDATIONS
  // ============================================================================

  /// Get personalized vibe-based recommendations for a user
  Future<Map<String, List<String>>> getPersonalizedRecommendations(String userId, {
    List<String>? entityTypes,
    String? context,
    int limitPerType = 10,
  }) async {
    try {
      final targetTypes = entityTypes ?? ['place', 'board', 'circle', 'user'];
      final recommendations = <String, List<String>>{};

      for (final entityType in targetTypes) {
        final compatible = await getCompatibleEntities(
          sourceEntityId: userId,
          sourceEntityType: 'user',
          targetEntityType: entityType,
          limit: limitPerType,
        );

        recommendations[entityType] = compatible.map((item) => item['entityId'] as String).toList();
      }

      return recommendations;
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      return {};
    }
  }

  /// Auto-detect vibes from various signals (place data, user behavior, etc.)
  Future<List<String>> autoDetectVibes({
    required Map<String, dynamic> entityData,
    required String entityType,
  }) async {
    try {
      final allTags = await getAllVibeTags();
      final detectedVibes = <String>[];

      // Different detection logic based on entity type
      switch (entityType) {
        case 'place':
          detectedVibes.addAll(await _detectPlaceVibes(entityData, allTags));
          break;
        case 'user':
          detectedVibes.addAll(await _detectUserVibes(entityData, allTags));
          break;
        case 'checkin':
          detectedVibes.addAll(await _detectCheckinVibes(entityData, allTags));
          break;
        case 'board':
          detectedVibes.addAll(await _detectBoardVibes(entityData, allTags));
          break;
      }

      return detectedVibes.take(5).toList(); // Limit to top 5 detected vibes
    } catch (e) {
      print('Error auto-detecting vibes: $e');
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<List<String>> _findComplementaryVibes(List<String> vibes1, List<String> vibes2) async {
    // Define complementary vibe pairs
    const complementaryPairs = {
      'cozy': ['aesthetic', 'intimate'],
      'energetic': ['social', 'adventurous'],
      'aesthetic': ['cozy', 'luxurious'],
      'social': ['energetic', 'community'],
      'adventurous': ['authentic', 'inspiring'],
      'luxurious': ['aesthetic', 'romantic'],
      'chill': ['peaceful', 'inspiring'],
      'intimate': ['romantic', 'cozy'],
    };

    final complementary = <String>[];
    
    for (final vibe1 in vibes1) {
      final complements = complementaryPairs[vibe1] ?? [];
      for (final complement in complements) {
        if (vibes2.contains(complement) && !complementary.contains(complement)) {
          complementary.add(complement);
        }
      }
    }

    return complementary;
  }

  Future<List<String>> _getAllEntitiesWithVibes(String entityType) async {
    try {
      final snapshot = await _firestore
          .collection('vibe_associations')
          .where('entityType', isEqualTo: entityType)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['entityId'] as String)
          .toSet()
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<String>> _detectPlaceVibes(Map<String, dynamic> placeData, List<VibeTag> allTags) async {
    final detected = <String>[];
    
    // Keywords in name/description detection
    final text = '${placeData['name'] ?? ''} ${placeData['description'] ?? ''}'.toLowerCase();
    
    for (final tag in allTags) {
      for (final synonym in tag.synonyms) {
        if (text.contains(synonym.toLowerCase())) {
          detected.add(tag.id);
          break;
        }
      }
    }

    // Price range detection
    final priceLevel = placeData['priceLevel'] as int? ?? 1;
    if (priceLevel >= 4) detected.add('luxurious');
    else if (priceLevel <= 1) detected.add('authentic');

    // Rating detection
    final rating = placeData['rating'] as double? ?? 0.0;
    if (rating >= 4.5) detected.add('aesthetic');

    // Category-based detection
    final types = placeData['types'] as List<dynamic>? ?? [];
    for (final type in types) {
      final typeStr = type.toString().toLowerCase();
      if (typeStr.contains('cafe') || typeStr.contains('coffee')) {
        detected.addAll(['cozy', 'chill']);
      } else if (typeStr.contains('bar') || typeStr.contains('nightlife')) {
        detected.addAll(['energetic', 'social']);
      } else if (typeStr.contains('restaurant') && typeStr.contains('fine')) {
        detected.addAll(['luxurious', 'romantic']);
      }
    }

    return detected.toSet().toList();
  }

  Future<List<String>> _detectUserVibes(Map<String, dynamic> userData, List<VibeTag> allTags) async {
    final detected = <String>[];
    
    // Analyze user's interests
    final interests = userData['interests'] as List<dynamic>? ?? [];
    for (final interest in interests) {
      final interestStr = interest.toString().toLowerCase();
      
      // Map interests to vibes
      if (interestStr.contains('art') || interestStr.contains('photo')) {
        detected.add('aesthetic');
      } else if (interestStr.contains('sport') || interestStr.contains('fitness')) {
        detected.add('energetic');
      } else if (interestStr.contains('music') || interestStr.contains('dance')) {
        detected.addAll(['energetic', 'social']);
      }
    }

    // Analyze bio for vibe keywords
    final bio = userData['bio'] as String? ?? '';
    for (final tag in allTags) {
      for (final synonym in tag.synonyms) {
        if (bio.toLowerCase().contains(synonym.toLowerCase())) {
          detected.add(tag.id);
          break;
        }
      }
    }

    return detected.toSet().toList();
  }

  Future<List<String>> _detectCheckinVibes(Map<String, dynamic> checkinData, List<VibeTag> allTags) async {
    final detected = <String>[];
    
    // Time-based detection
    final timestamp = checkinData['timestamp'] as Timestamp?;
    if (timestamp != null) {
      final dateTime = timestamp.toDate();
      final hour = dateTime.hour;
      
      if (hour >= 6 && hour < 11) {
        detected.addAll(['chill', 'peaceful']);
      } else if (hour >= 20 || hour < 2) {
        detected.addAll(['energetic', 'social']);
      }
      
      if (dateTime.weekday >= 6) {
        detected.add('social');
      }
    }

    // Mood/notes analysis
    final notes = checkinData['notes'] as String? ?? '';
    final mood = checkinData['mood'] as String? ?? '';
    
    for (final tag in allTags) {
      for (final synonym in tag.synonyms) {
        if (notes.toLowerCase().contains(synonym.toLowerCase()) ||
            mood.toLowerCase().contains(synonym.toLowerCase())) {
          detected.add(tag.id);
          break;
        }
      }
    }

    return detected.toSet().toList();
  }

  Future<List<String>> _detectBoardVibes(Map<String, dynamic> boardData, List<VibeTag> allTags) async {
    final detected = <String>[];
    
    // Analyze board name and description
    final text = '${boardData['name'] ?? ''} ${boardData['description'] ?? ''}'.toLowerCase();
    
    for (final tag in allTags) {
      if (text.contains(tag.name.toLowerCase()) || 
          text.contains(tag.displayName.toLowerCase())) {
        detected.add(tag.id);
      }
      
      for (final synonym in tag.synonyms) {
        if (text.contains(synonym.toLowerCase())) {
          detected.add(tag.id);
          break;
        }
      }
    }

    return detected.toSet().toList();
  }

  // ============================================================================
  // ANALYTICS METHODS
  // ============================================================================

  /// Get vibe usage analytics for a user
  Future<Map<String, int>> getVibeAnalytics({
    required String entityId,
    required String entityType,
    required String timeRange,
  }) async {
    try {
      final associations = await getEntityVibeAssociations(entityId, entityType);
      final analytics = <String, int>{};

      for (final association in associations) {
        analytics[association.vibeTagId] = (analytics[association.vibeTagId] ?? 0) + 1;
      }

      return analytics;
    } catch (e) {
      print('Error getting vibe analytics: $e');
      return {};
    }
  }

  /// Get compatibility analytics for a user
  Future<Map<String, double>> getCompatibilityAnalytics({
    required String userId,
    required String period,
  }) async {
    try {
      // Simulate compatibility analytics
      // In a real implementation, this would query actual compatibility data
      return {
        'average_compatibility': 0.75,
        'high_matches': 0.85,
        'medium_matches': 0.65,
        'low_matches': 0.45,
      };
    } catch (e) {
      print('Error getting compatibility analytics: $e');
      return {};
    }
  }

  /// Get vibe recommendations for a user
  Future<Map<String, List<String>>> getVibeRecommendations({
    required String userId,
    required List<String> categories,
  }) async {
    try {
      final userVibes = await getEntityVibeAssociations(userId, 'user');
      final allVibes = await getAllVibeTags();
      
      final recommendations = <String, List<String>>{};
      
      for (final category in categories) {
        final categoryVibes = allVibes
            .where((vibe) => vibe.category == category)
            .where((vibe) => !userVibes.any((uv) => uv.vibeTagId == vibe.id))
            .take(5)
            .map((vibe) => vibe.id)
            .toList();
        
        if (categoryVibes.isNotEmpty) {
          recommendations[category] = categoryVibes;
        }
      }

      return recommendations;
    } catch (e) {
      print('Error getting vibe recommendations: $e');
      return {};
    }
  }


  // Helper method to create mock entities for demonstration
  dynamic _createMockEntity(String entityType) {
    switch (entityType) {
      case 'user':
        return EnhancedUser(
          id: 'mock_user_${Random().nextInt(1000)}',
          name: 'Mock User',
          email: 'mock@example.com',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          vibeProfile: VibeProfile(
            primaryVibes: ['social', 'aesthetic'],
            vibeScores: {},
            vibeEvolution: [],
            contextualVibes: ContextualVibes(
              contextVibeMap: {},
              lastUpdated: DateTime.now(),
            ),
            lastUpdated: DateTime.now(),
          ),
          tasteSignature: TasteSignature(
            venuePreferences: {},
            priceRangeAffinity: {},
            socialPreference: 0.7,
            discoveryQuotient: 0.5,
            timePatterns: {},
            lastCalculated: DateTime.now(),
          ),
          behavioralSignals: BehavioralSignals(
            vibeConsistencyScore: 0.5,
            explorationRadius: 0.6,
            influenceScore: 0.4,
            activityPatterns: {},
            lastCalculated: DateTime.now(),
          ),
          onboardingData: OnboardingData(
            completedSteps: ['completed'],
            quizResponses: {},
            initialMatches: [],
            onboardingVersion: '1.0',
            completionTimestamp: DateTime.now(),
            engagementScore: 0.8,
          ),
          privacySettings: PrivacySettings(),
          notificationPreferences: NotificationPreferences(),
          interests: [],
          vibeTitle: 'Mock User',
          trustScore: 50,
          achievements: [],
          profileLastUpdated: DateTime.now(),
          appVersion: '1.0.0',
        );
      case 'circle':
        return VibeCircle(
          id: 'mock_circle_${Random().nextInt(1000)}',
          name: 'Mock Circle',
          description: 'A mock circle for testing',
          creatorId: 'mock_user',
          isPublic: true,
          vibePreferences: ['social', 'energetic'],
          category: CircleCategory.other,
          memberCount: Random().nextInt(50) + 5,
          createdAt: DateTime.now(),
          lastActivityAt: DateTime.now(),
        );
      default:
        return null;
    }
  }
}