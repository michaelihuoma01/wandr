import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../models/circle_models.dart';

class VibeMatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheCollection = 'vibe_match_cache';
  static const Duration _cacheExpiry = Duration(hours: 6);

  // ============================================================================
  // CORE VIBE MATCHING ALGORITHMS
  // ============================================================================

  /// Calculate cosine similarity between two vibe vectors
  /// Returns a score between 0.0 (no similarity) and 1.0 (perfect match)
  double calculateCosineSimilarity(
    Map<String, double> vectorA,
    Map<String, double> vectorB,
  ) {
    final allVibes = {...vectorA.keys, ...vectorB.keys};
    
    double dotProduct = 0.0;
    double magnitudeA = 0.0;
    double magnitudeB = 0.0;

    for (final vibe in allVibes) {
      final scoreA = vectorA[vibe] ?? 0.0;
      final scoreB = vectorB[vibe] ?? 0.0;
      
      dotProduct += scoreA * scoreB;
      magnitudeA += scoreA * scoreA;
      magnitudeB += scoreB * scoreB;
    }

    magnitudeA = sqrt(magnitudeA);
    magnitudeB = sqrt(magnitudeB);

    if (magnitudeA == 0.0 || magnitudeB == 0.0) return 0.0;
    
    return dotProduct / (magnitudeA * magnitudeB);
  }

  /// Calculate Euclidean distance between vibe vectors (for diversity matching)
  double calculateEuclideanDistance(
    Map<String, double> vectorA,
    Map<String, double> vectorB,
  ) {
    final allVibes = {...vectorA.keys, ...vectorB.keys};
    double sumSquares = 0.0;

    for (final vibe in allVibes) {
      final scoreA = vectorA[vibe] ?? 0.0;
      final scoreB = vectorB[vibe] ?? 0.0;
      sumSquares += pow(scoreA - scoreB, 2);
    }

    return sqrt(sumSquares);
  }

  /// Convert VibeProfile to normalized vector for matching
  Map<String, double> vibeProfileToVector(VibeProfile profile) {
    final vector = <String, double>{};
    
    // Convert vibe scores to normalized vector
    profile.vibeScores.forEach((vibeId, vibeScore) {
      vector[vibeId] = vibeScore.score;
    });

    // Boost primary vibes
    for (final primaryVibe in profile.primaryVibes) {
      vector[primaryVibe] = (vector[primaryVibe] ?? 0.0) * 1.2;
      if (vector[primaryVibe]! > 1.0) vector[primaryVibe] = 1.0;
    }

    return _normalizeVector(vector);
  }

  /// Normalize vector to unit length
  Map<String, double> _normalizeVector(Map<String, double> vector) {
    final magnitude = sqrt(vector.values.map((v) => v * v).reduce((a, b) => a + b));
    if (magnitude == 0.0) return vector;
    
    return vector.map((key, value) => MapEntry(key, value / magnitude));
  }

  // ============================================================================
  // USER-TO-USER MATCHING
  // ============================================================================

  /// Find users with similar vibe profiles
  Future<List<UserMatch>> findSimilarUsers(
    String userId,
    {int limit = 10, double minSimilarity = 0.3}
  ) async {
    try {
      // Check cache first
      final cached = await _getCachedMatches(userId, 'user');
      if (cached != null) return cached.cast<UserMatch>();

      final currentUser = await _getEnhancedUser(userId);
      if (currentUser == null) return [];

      final currentVector = vibeProfileToVector(currentUser.vibeProfile);
      final matches = <UserMatch>[];

      // Get potential matches (users with overlapping primary vibes)
      final potentialMatches = await _firestore
          .collection('users')
          .where('vibeProfile.primaryVibes', arrayContainsAny: currentUser.vibeProfile.primaryVibes)
          .where(FieldPath.documentId, isNotEqualTo: userId)
          .limit(100) // Get larger pool for better filtering
          .get();

      for (final doc in potentialMatches.docs) {
        try {
          final user = EnhancedUser.fromJson({
            'id': doc.id,
            ...doc.data(),
          });

          final similarity = _calculateUserCompatibility(currentUser, user);
          
          if (similarity >= minSimilarity) {
            matches.add(UserMatch(
              userId: user.id,
              userName: user.name,
              userPhotoUrl: user.photoUrl,
              vibeTitle: user.vibeTitle,
              compatibilityScore: similarity,
              matchingVibes: _getMatchingVibes(currentUser.vibeProfile, user.vibeProfile),
              trustScore: user.trustScore,
            ));
          }
        } catch (e) {
          print('Error processing user match: $e');
        }
      }

      // Sort by compatibility and return top matches
      matches.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
      final result = matches.take(limit).toList();

      // Cache results
      await _cacheMatches(userId, 'user', result);

      return result;
    } catch (e) {
      print('Error finding similar users: $e');
      return [];
    }
  }

  /// Calculate comprehensive user compatibility score
  double _calculateUserCompatibility(EnhancedUser userA, EnhancedUser userB) {
    // Base vibe similarity (50% weight)
    final vibeVector1 = vibeProfileToVector(userA.vibeProfile);
    final vibeVector2 = vibeProfileToVector(userB.vibeProfile);
    final vibeSimilarity = calculateCosineSimilarity(vibeVector1, vibeVector2);

    // Social preference compatibility (20% weight)
    final socialCompatibility = _calculateSocialCompatibility(
      userA.tasteSignature.socialPreference,
      userB.tasteSignature.socialPreference,
    );

    // Discovery quotient compatibility (15% weight)
    final discoveryCompatibility = _calculateDiscoveryCompatibility(
      userA.tasteSignature.discoveryQuotient,
      userB.tasteSignature.discoveryQuotient,
    );

    // Behavioral signals compatibility (15% weight)
    final behavioralCompatibility = _calculateBehavioralCompatibility(
      userA.behavioralSignals,
      userB.behavioralSignals,
    );

    // Final weighted score
    return (vibeSimilarity * 0.5) +
           (socialCompatibility * 0.2) +
           (discoveryCompatibility * 0.15) +
           (behavioralCompatibility * 0.15);
  }

  double _calculateSocialCompatibility(double pref1, double pref2) {
    // Both high or both low = good match
    // One high, one low = potential complementary match but lower score
    final difference = (pref1 - pref2).abs();
    return 1.0 - (difference * 0.7); // Allow some difference
  }

  double _calculateDiscoveryCompatibility(double disc1, double disc2) {
    final difference = (disc1 - disc2).abs();
    return 1.0 - difference; // Closer discovery preferences = better match
  }

  double _calculateBehavioralCompatibility(
    BehavioralSignals signals1,
    BehavioralSignals signals2,
  ) {
    final consistencyMatch = 1.0 - (signals1.vibeConsistencyScore - signals2.vibeConsistencyScore).abs();
    final explorationMatch = 1.0 - (signals1.explorationRadius - signals2.explorationRadius).abs();
    
    return (consistencyMatch + explorationMatch) / 2;
  }

  List<String> _getMatchingVibes(VibeProfile profile1, VibeProfile profile2) {
    final matching = <String>[];
    for (final vibe in profile1.primaryVibes) {
      if (profile2.primaryVibes.contains(vibe)) {
        matching.add(vibe);
      }
    }
    return matching;
  }

  // ============================================================================
  // USER-TO-CIRCLE MATCHING
  // ============================================================================

  /// Find circles that match user's vibe profile
  Future<List<CircleMatch>> findMatchingCircles(
    String userId,
    {int limit = 10, double minSimilarity = 0.4}
  ) async {
    try {
      final currentUser = await _getEnhancedUser(userId);
      if (currentUser == null) return [];

      final matches = <CircleMatch>[];

      // Get circles with overlapping vibes or similar member profiles
      final circleQuery = await _firestore
          .collection('circles')
          .where('isPublic', isEqualTo: true)
          .where('vibePreferences', arrayContainsAny: currentUser.vibeProfile.primaryVibes)
          .limit(50)
          .get();

      for (final doc in circleQuery.docs) {
        try {
          final circle = VibeCircle.fromJson({
            'id': doc.id,
            ...doc.data(),
          });

          final compatibility = await _calculateCircleCompatibility(currentUser, circle);
          
          if (compatibility >= minSimilarity) {
            matches.add(CircleMatch(
              circleId: circle.id,
              circleName: circle.name,
              circleDescription: circle.description,
              memberCount: circle.memberCount,
              compatibilityScore: compatibility,
              matchingVibes: _getMatchingCircleVibes(currentUser.vibeProfile.primaryVibes, circle.vibePreferences),
              dominantVibe: _calculateDominantCircleVibe(circle),
            ));
          }
        } catch (e) {
          print('Error processing circle match: $e');
        }
      }

      matches.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
      return matches.take(limit).toList();
    } catch (e) {
      print('Error finding matching circles: $e');
      return [];
    }
  }

  /// Calculate user-to-circle compatibility
  Future<double> _calculateCircleCompatibility(EnhancedUser user, VibeCircle circle) async {
    // Direct vibe overlap (40% weight)
    final vibeOverlap = _calculateVibeOverlap(user.vibeProfile.primaryVibes, circle.vibePreferences);

    // Member similarity (30% weight) - sample analysis
    final memberSimilarity = await _calculateMemberSimilarity(user, circle.id);

    // Activity level match (20% weight)
    final activityMatch = _calculateActivityLevelMatch(user, circle);

    // Circle health score (10% weight)
    final healthScore = _calculateCircleHealthScore(circle);

    return (vibeOverlap * 0.4) + (memberSimilarity * 0.3) + (activityMatch * 0.2) + (healthScore * 0.1);
  }

  double _calculateVibeOverlap(List<String> userVibes, List<String> circleVibes) {
    final intersection = userVibes.where((vibe) => circleVibes.contains(vibe)).length;
    final union = {...userVibes, ...circleVibes}.length;
    return union > 0 ? intersection / union : 0.0;
  }

  Future<double> _calculateMemberSimilarity(EnhancedUser user, String circleId) async {
    try {
      // Sample a few active members for similarity analysis
      final memberships = await _firestore
          .collection('circle_memberships')
          .where('circleId', isEqualTo: circleId)
          .orderBy('contributionScore', descending: true)
          .limit(5)
          .get();

      if (memberships.docs.isEmpty) return 0.5; // Default for new circles

      double totalSimilarity = 0.0;
      int validMembers = 0;

      for (final membership in memberships.docs) {
        final memberData = membership.data() as Map<String, dynamic>;
        final memberId = memberData['userId'] as String;
        
        final member = await _getEnhancedUser(memberId);
        if (member != null) {
          final similarity = _calculateUserCompatibility(user, member);
          totalSimilarity += similarity;
          validMembers++;
        }
      }

      return validMembers > 0 ? totalSimilarity / validMembers : 0.5;
    } catch (e) {
      return 0.5; // Default on error
    }
  }

  double _calculateActivityLevelMatch(EnhancedUser user, VibeCircle circle) {
    // Estimate user's activity level from behavioral signals
    final userActivityLevel = user.behavioralSignals.explorationRadius;
    
    // Estimate circle activity level from member count and recent activity
    final now = DateTime.now();
    final daysSinceActivity = now.difference(circle.lastActivityAt).inDays;
    final circleActivityLevel = (circle.memberCount / 100.0).clamp(0.0, 1.0) * 
                              (1.0 - (daysSinceActivity / 30.0).clamp(0.0, 1.0));

    return 1.0 - (userActivityLevel - circleActivityLevel).abs();
  }

  double _calculateCircleHealthScore(VibeCircle circle) {
    final now = DateTime.now();
    final daysSinceActivity = now.difference(circle.lastActivityAt).inDays;
    
    // Healthy circles have recent activity and good member count
    final activityScore = (1.0 - (daysSinceActivity / 7.0).clamp(0.0, 1.0));
    final sizeScore = (circle.memberCount / 50.0).clamp(0.1, 1.0);
    
    return (activityScore + sizeScore) / 2;
  }

  List<String> _getMatchingCircleVibes(List<String> userVibes, List<String> circleVibes) {
    return userVibes.where((vibe) => circleVibes.contains(vibe)).toList();
  }

  String _calculateDominantCircleVibe(VibeCircle circle) {
    return circle.vibePreferences.isNotEmpty ? circle.vibePreferences.first : 'social';
  }

  // ============================================================================
  // USER-TO-BOARD MATCHING
  // ============================================================================

  /// Find boards that match user's taste signature
  Future<List<BoardMatch>> findMatchingBoards(
    String userId,
    {int limit = 20, double minSimilarity = 0.3}
  ) async {
    try {
      final currentUser = await _getEnhancedUser(userId);
      if (currentUser == null) return [];

      final matches = <BoardMatch>[];

      // Get boards with overlapping tags/vibes
      final boardQuery = await _firestore
          .collection('boards')
          .where('isPublic', isEqualTo: true)
          .where('tags', arrayContainsAny: currentUser.vibeProfile.primaryVibes)
          .limit(100)
          .get();

      for (final doc in boardQuery.docs) {
        try {
          final board = Board.fromJson({
            'id': doc.id,
            ...doc.data(),
          });

          final compatibility = await _calculateBoardCompatibility(currentUser, board);
          
          if (compatibility >= minSimilarity) {
            matches.add(BoardMatch(
              boardId: board.id,
              boardName: board.name,
              boardDescription: board.description,
              creatorId: board.createdBy,
              placeCount: board.places.length,
              compatibilityScore: compatibility,
              matchingTags: _getMatchingBoardTags(currentUser.vibeProfile.primaryVibes, board.tags),
              boardType: board.type,
            ));
          }
        } catch (e) {
          print('Error processing board match: $e');
        }
      }

      matches.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
      return matches.take(limit).toList();
    } catch (e) {
      print('Error finding matching boards: $e');
      return [];
    }
  }

  /// Calculate user-to-board compatibility
  Future<double> _calculateBoardCompatibility(EnhancedUser user, Board board) async {
    // Tag/vibe overlap (50% weight)
    final tagOverlap = _calculateVibeOverlap(user.vibeProfile.primaryVibes, board.tags);

    // Creator compatibility (30% weight)
    final creatorCompatibility = await _calculateCreatorCompatibility(user, board.createdBy);

    // Venue type preferences (20% weight)
    final venueMatch = _calculateVenueTypeMatch(user.tasteSignature, board.places);

    return (tagOverlap * 0.5) + (creatorCompatibility * 0.3) + (venueMatch * 0.2);
  }

  Future<double> _calculateCreatorCompatibility(EnhancedUser user, String creatorId) async {
    if (creatorId == user.id) return 1.0; // Perfect match for own boards
    
    try {
      final creator = await _getEnhancedUser(creatorId);
      if (creator == null) return 0.5;
      
      return _calculateUserCompatibility(user, creator);
    } catch (e) {
      return 0.5;
    }
  }

  double _calculateVenueTypeMatch(TasteSignature tasteSignature, List<PlaceDetails> places) {
    if (places.isEmpty) return 0.0;

    double totalMatch = 0.0;
    for (final place in places) {
      final preference = tasteSignature.venuePreferences[place.type] ?? 0.5;
      totalMatch += preference;
    }
    
    return totalMatch / places.length;
  }

  List<String> _getMatchingBoardTags(List<String> userVibes, List<String> boardTags) {
    return userVibes.where((vibe) => boardTags.contains(vibe)).toList();
  }

  // ============================================================================
  // COLLABORATIVE FILTERING
  // ============================================================================

  /// Find recommendations based on similar users' behavior
  Future<List<RecommendationItem>> getCollaborativeRecommendations(
    String userId,
    {int limit = 15}
  ) async {
    try {
      // Find similar users
      final similarUsers = await findSimilarUsers(userId, limit: 10, minSimilarity: 0.4);
      if (similarUsers.isEmpty) return [];

      final recommendations = <RecommendationItem>[];
      final userInteractions = await _getUserInteractions(userId);

      // Analyze what similar users like that current user hasn't tried
      for (final similarUser in similarUsers) {
        final similarUserInteractions = await _getUserInteractions(similarUser.userId);
        
        // Find items similar user liked but current user hasn't interacted with
        for (final interaction in similarUserInteractions) {
          if (!userInteractions.any((ui) => ui.itemId == interaction.itemId && ui.itemType == interaction.itemType)) {
            recommendations.add(RecommendationItem(
              itemId: interaction.itemId,
              itemType: interaction.itemType,
              recommendationScore: interaction.rating * similarUser.compatibilityScore,
              reason: 'Users with similar taste love this',
              sourceUserId: similarUser.userId,
            ));
          }
        }
      }

      // Aggregate and sort recommendations
      final aggregated = _aggregateRecommendations(recommendations);
      aggregated.sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));
      
      return aggregated.take(limit).toList();
    } catch (e) {
      print('Error getting collaborative recommendations: $e');
      return [];
    }
  }

  List<RecommendationItem> _aggregateRecommendations(List<RecommendationItem> recommendations) {
    final Map<String, RecommendationItem> aggregated = {};
    
    for (final rec in recommendations) {
      final key = '${rec.itemType}_${rec.itemId}';
      if (aggregated.containsKey(key)) {
        // Average the scores and combine reasons
        final existing = aggregated[key]!;
        aggregated[key] = RecommendationItem(
          itemId: rec.itemId,
          itemType: rec.itemType,
          recommendationScore: (existing.recommendationScore + rec.recommendationScore) / 2,
          reason: existing.reason,
          sourceUserId: existing.sourceUserId,
        );
      } else {
        aggregated[key] = rec;
      }
    }
    
    return aggregated.values.toList();
  }

  // ============================================================================
  // CACHING SYSTEM
  // ============================================================================

  Future<List<dynamic>?> _getCachedMatches(String userId, String matchType) async {
    try {
      final doc = await _firestore
          .collection(_cacheCollection)
          .doc('${userId}_$matchType')
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        // Cache expired
        await doc.reference.delete();
        return null;
      }

      return List<dynamic>.from(data['matches'] ?? []);
    } catch (e) {
      return null;
    }
  }

  Future<void> _cacheMatches(String userId, String matchType, List<dynamic> matches) async {
    try {
      await _firestore
          .collection(_cacheCollection)
          .doc('${userId}_$matchType')
          .set({
        'matches': matches.map((m) => m.toJson()).toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error caching matches: $e');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<EnhancedUser?> _getEnhancedUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      
      return EnhancedUser.fromJson({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });
    } catch (e) {
      print('Error getting enhanced user: $e');
      return null;
    }
  }

  Future<List<UserInteraction>> _getUserInteractions(String userId) async {
    try {
      // Get user's visits, board saves, circle joins, etc.
      final interactions = <UserInteraction>[];
      
      // Add visit data
      final visits = await _firestore
          .collection('visits')
          .where('userId', isEqualTo: userId)
          .orderBy('visitTime', descending: true)
          .limit(50)
          .get();

      for (final visit in visits.docs) {
        final data = visit.data();
        interactions.add(UserInteraction(
          itemId: data['placeId'] as String,
          itemType: 'place',
          rating: 1.0, // Implicit positive rating for visiting
          timestamp: (data['visitTime'] as Timestamp).toDate(),
        ));
      }

      return interactions;
    } catch (e) {
      print('Error getting user interactions: $e');
      return [];
    }
  }
}

// ============================================================================
// MATCHING RESULT CLASSES
// ============================================================================

class UserMatch {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String? vibeTitle;
  final double compatibilityScore;
  final List<String> matchingVibes;
  final int trustScore;

  UserMatch({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    this.vibeTitle,
    required this.compatibilityScore,
    required this.matchingVibes,
    required this.trustScore,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'vibeTitle': vibeTitle,
    'compatibilityScore': compatibilityScore,
    'matchingVibes': matchingVibes,
    'trustScore': trustScore,
  };
}

class CircleMatch {
  final String circleId;
  final String circleName;
  final String circleDescription;
  final int memberCount;
  final double compatibilityScore;
  final List<String> matchingVibes;
  final String dominantVibe;

  CircleMatch({
    required this.circleId,
    required this.circleName,
    required this.circleDescription,
    required this.memberCount,
    required this.compatibilityScore,
    required this.matchingVibes,
    required this.dominantVibe,
  });

  Map<String, dynamic> toJson() => {
    'circleId': circleId,
    'circleName': circleName,
    'circleDescription': circleDescription,
    'memberCount': memberCount,
    'compatibilityScore': compatibilityScore,
    'matchingVibes': matchingVibes,
    'dominantVibe': dominantVibe,
  };
}

class BoardMatch {
  final String boardId;
  final String boardName;
  final String boardDescription;
  final String creatorId;
  final int placeCount;
  final double compatibilityScore;
  final List<String> matchingTags;
  final BoardType boardType;

  BoardMatch({
    required this.boardId,
    required this.boardName,
    required this.boardDescription,
    required this.creatorId,
    required this.placeCount,
    required this.compatibilityScore,
    required this.matchingTags,
    required this.boardType,
  });

  Map<String, dynamic> toJson() => {
    'boardId': boardId,
    'boardName': boardName,
    'boardDescription': boardDescription,
    'creatorId': creatorId,
    'placeCount': placeCount,
    'compatibilityScore': compatibilityScore,
    'matchingTags': matchingTags,
    'boardType': boardType.toString(),
  };
}

class RecommendationItem {
  final String itemId;
  final String itemType; // 'place', 'board', 'circle'
  final double recommendationScore;
  final String reason;
  final String sourceUserId;

  RecommendationItem({
    required this.itemId,
    required this.itemType,
    required this.recommendationScore,
    required this.reason,
    required this.sourceUserId,
  });

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'itemType': itemType,
    'recommendationScore': recommendationScore,
    'reason': reason,
    'sourceUserId': sourceUserId,
  };
}

class UserInteraction {
  final String itemId;
  final String itemType;
  final double rating;
  final DateTime timestamp;

  UserInteraction({
    required this.itemId,
    required this.itemType,
    required this.rating,
    required this.timestamp,
  });
}