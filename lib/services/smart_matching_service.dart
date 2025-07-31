// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/circle_models.dart';
// import '../models/models.dart';
// import '../models/vibe_tag_models.dart';
// import 'comprehensive_vibe_system.dart';
// import 'vibe_tag_service.dart';
// import 'shared_utilities_service.dart';

// // ============================================================================
// // SMART MATCHING SERVICE - AI-Powered Recommendations
// // Matches users with circles, boards, places, and other users based on vibes
// // ============================================================================

// class SmartMatchingService {
//   static final SmartMatchingService _instance = SmartMatchingService._internal();
//   factory SmartMatchingService() => _instance;
//   SmartMatchingService._internal();

//   final ComprehensiveVibeSystem _vibeSystem = ComprehensiveVibeSystem();
//   final VibeTagService _vibeTagService = VibeTagService();
//   final SharedUtilitiesService _utils = SharedUtilitiesService();

//   // ============================================================================
//   // COMPREHENSIVE MATCHING ALGORITHM
//   // ============================================================================

//   /// Get personalized recommendations for circles, users, places, and boards
//   Future<Map<String, List<Map<String, dynamic>>>> getPersonalizedRecommendations({
//     required String userId,
//     DateTime? currentTime,
//     String? location,
//     Map<String, dynamic>? context, // mood, activity, etc.
//     int limitPerType = 10,
//   }) async {
//     try {
//       final userVibes = await _vibeTagService.getEntityVibeAssociations(userId, 'user');
//       if (userVibes.isEmpty) {
//         return {
//           'circles': [],
//           'users': [],
//           'places': [],
//           'boards': [],
//         };
//       }

//       // Get contextual weights based on current situation
//       final contextWeights = _calculateContextualWeights(
//         userVibes,
//         currentTime ?? DateTime.now(),
//         location,
//         context,
//       );

//       // Run parallel matching for all entity types
//       final results = await Future.wait([
//         _matchCircles(userId, userVibes, contextWeights, limitPerType),
//         _matchUsers(userId, userVibes, contextWeights, limitPerType),
//         _matchPlaces(userId, userVibes, contextWeights, limitPerType),
//         _matchBoards(userId, userVibes, contextWeights, limitPerType),
//       ]);

//       return {
//         'circles': results[0],
//         'users': results[1],
//         'places': results[2],
//         'boards': results[3],
//       };
//     } catch (e) {
//       print('Error getting personalized recommendations: $e');
//       return {
//         'circles': [],
//         'users': [],
//         'places': [],
//         'boards': [],
//       };
//     }
//   }

//   /// Enhanced circle matching with activity analysis
//   Future<List<Map<String, dynamic>>> _matchCircles(
//     String userId,
//     List<VibeTagAssociation> userVibes,
//     Map<String, double> contextWeights,
//     int limit,
//   ) async {
//     try {
//       // Get all circles with vibe associations
//       final circleVibes = await _getAllEntityVibes('circle');
//       final matchedCircles = <Map<String, dynamic>>[];

//       for (final circleVibe in circleVibes) {
//         final circleId = circleVibe['entityId'] as String;
        
//         // Skip if user is already a member
//         if (await _isUserMemberOfCircle(userId, circleId)) continue;

//         // Calculate compatibility
//         final compatibility = await _vibeTagService.calculateVibeCompatibility(
//           entityId1: userId,
//           entityType1: 'user',
//           entityId2: circleId,
//           entityType2: 'circle',
//         );

//         if (compatibility.overallScore < 0.3) continue; // Minimum threshold

//         // Get circle details
//         final circleDoc = await _utils.circlesCollection.doc(circleId).get();
//         if (!circleDoc.exists) continue;

//         final circle = VibeCircle.fromJson({
//           'id': circleDoc.id,
//           ...circleDoc.data() as Map<String, dynamic>,
//         });

//         // Calculate enhanced score with context
//         final enhancedScore = _calculateEnhancedScore(
//           compatibility.overallScore,
//           circle,
//           contextWeights,
//           userVibes,
//         );

//         matchedCircles.add({
//           'circle': circle,
//           'compatibilityScore': compatibility.overallScore,
//           'enhancedScore': enhancedScore,
//           'sharedVibes': compatibility.sharedVibes,
//           'complementaryVibes': compatibility.complementaryVibes,
//           'matchReason': _generateMatchReason(compatibility, circle),
//           'activityLevel': await _getCircleActivityLevel(circleId),
//           'memberVibeDistribution': await _getCircleMemberVibeDistribution(circleId),
//         });
//       }

//       // Sort by enhanced score and return top matches
//       matchedCircles.sort((a, b) => b['enhancedScore'].compareTo(a['enhancedScore']));
//       return matchedCircles.take(limit).toList();
//     } catch (e) {
//       print('Error matching circles: $e');
//       return [];
//     }
//   }

//   /// Enhanced user matching for potential connections
//   Future<List<Map<String, dynamic>>> _matchUsers(
//     String userId,
//     List<VibeTagAssociation> userVibes,
//     Map<String, double> contextWeights,
//     int limit,
//   ) async {
//     try {
//       // Get users with similar vibes
//       final userVibeIds = userVibes.map((v) => v.vibeTagId).toList();
//       final potentialMatches = await _vibeTagService.getEntitiesWithVibes(
//         userVibeIds,
//         'user',
//         minStrength: 0.4,
//       );

//       final matchedUsers = <Map<String, dynamic>>[];

//       for (final matchUserId in potentialMatches) {
//         if (matchUserId == userId) continue; // Skip self

//         // Calculate compatibility
//         final compatibility = await _vibeTagService.calculateVibeCompatibility(
//           entityId1: userId,
//           entityType1: 'user',
//           entityId2: matchUserId,
//           entityType2: 'user',
//         );

//         if (compatibility.overallScore < 0.4) continue; // Higher threshold for users

//         // Get user details (simplified - you'd fetch from users collection)
//         final userDetails = await _getUserDetails(matchUserId);
//         if (userDetails == null) continue;

//         // Check for mutual connections/circles
//         final mutualConnections = await _getMutualConnections(userId, matchUserId);

//         matchedUsers.add({
//           'user': userDetails,
//           'compatibilityScore': compatibility.overallScore,
//           'sharedVibes': compatibility.sharedVibes,
//           'complementaryVibes': compatibility.complementaryVibes,
//           'mutualConnections': mutualConnections,
//           'matchReason': _generateUserMatchReason(compatibility, mutualConnections),
//           'connectionStrength': _calculateConnectionStrength(compatibility, mutualConnections),
//         });
//       }

//       // Sort by connection strength
//       matchedUsers.sort((a, b) => b['connectionStrength'].compareTo(a['connectionStrength']));
//       return matchedUsers.take(limit).toList();
//     } catch (e) {
//       print('Error matching users: $e');
//       return [];
//     }
//   }

//   /// Enhanced place matching with contextual relevance
//   Future<List<Map<String, dynamic>>> _matchPlaces(
//     String userId,
//     List<VibeTagAssociation> userVibes,
//     Map<String, double> contextWeights,
//     int limit,
//   ) async {
//     try {
//       // Get places with vibe associations
//       final placeVibes = await _getAllEntityVibes('place');
//       final matchedPlaces = <Map<String, dynamic>>[];

//       for (final placeVibe in placeVibes) {
//         final placeId = placeVibe['entityId'] as String;

//         // Calculate compatibility
//         final compatibility = await _vibeTagService.calculateVibeCompatibility(
//           entityId1: userId,
//           entityType1: 'user',
//           entityId2: placeId,
//           entityType2: 'place',
//         );

//         if (compatibility.overallScore < 0.3) continue;

//         // Get place details (you'd fetch from places collection)
//         final placeDetails = await _getPlaceDetails(placeId);
//         if (placeDetails == null) continue;

//         // Apply contextual scoring
//         final contextualScore = _applyPlaceContextualScoring(
//           compatibility.overallScore,
//           placeDetails,
//           contextWeights,
//         );

//         matchedPlaces.add({
//           'place': placeDetails,
//           'compatibilityScore': compatibility.overallScore,
//           'contextualScore': contextualScore,
//           'sharedVibes': compatibility.sharedVibes,
//           'matchReason': _generatePlaceMatchReason(compatibility, placeDetails),
//           'bestTimeToVisit': _predictBestTimeToVisit(placeDetails, userVibes),
//           'crowdLevel': await _predictCrowdLevel(placeId),
//         });
//       }

//       // Sort by contextual score
//       matchedPlaces.sort((a, b) => b['contextualScore'].compareTo(a['contextualScore']));
//       return matchedPlaces.take(limit).toList();
//     } catch (e) {
//       print('Error matching places: $e');
//       return [];
//     }
//   }

//   /// Enhanced board matching for curated collections
//   Future<List<Map<String, dynamic>>> _matchBoards(
//     String userId,
//     List<VibeTagAssociation> userVibes,
//     Map<String, double> contextWeights,
//     int limit,
//   ) async {
//     try {
//       // Get boards with vibe associations
//       final boardVibes = await _getAllEntityVibes('board');
//       final matchedBoards = <Map<String, dynamic>>[];

//       for (final boardVibe in boardVibes) {
//         final boardId = boardVibe['entityId'] as String;

//         // Calculate compatibility
//         final compatibility = await _vibeTagService.calculateVibeCompatibility(
//           entityId1: userId,
//           entityType1: 'user',
//           entityId2: boardId,
//           entityType2: 'board',
//         );

//         if (compatibility.overallScore < 0.4) continue;

//         // Get board details
//         final boardDetails = await _getBoardDetails(boardId);
//         if (boardDetails == null) continue;

//         matchedBoards.add({
//           'board': boardDetails,
//           'compatibilityScore': compatibility.overallScore,
//           'sharedVibes': compatibility.sharedVibes,
//           'matchReason': _generateBoardMatchReason(compatibility, boardDetails),
//           'curatorMatch': await _getCuratorCompatibility(userId, boardDetails['creatorId']),
//           'placeCount': boardDetails['placeCount'] ?? 0,
//           'lastUpdated': boardDetails['lastUpdated'],
//         });
//       }

//       // Sort by compatibility score
//       matchedBoards.sort((a, b) => b['compatibilityScore'].compareTo(a['compatibilityScore']));
//       return matchedBoards.take(limit).toList();
//     } catch (e) {
//       print('Error matching boards: $e');
//       return [];
//     }
//   }

//   // ============================================================================
//   // CONTEXTUAL SCORING & INTELLIGENCE
//   // ============================================================================

//   Map<String, double> _calculateContextualWeights(
//     List<VibeTagAssociation> userVibes,
//     DateTime currentTime,
//     String? location,
//     Map<String, dynamic>? context,
//   ) {
//     final weights = <String, double>{};
//     final hour = currentTime.hour;
//     final dayOfWeek = currentTime.weekday;
//     final isWeekend = dayOfWeek >= 6;

//     // Time-based weights
//     if (hour >= 6 && hour < 12) {
//       weights['morning'] = 1.2;
//       weights['breakfast'] = 1.3;
//       weights['coffee'] = 1.1;
//     } else if (hour >= 12 && hour < 17) {
//       weights['lunch'] = 1.3;
//       weights['work'] = 1.1;
//       weights['productive'] = 1.1;
//     } else if (hour >= 17 && hour < 22) {
//       weights['evening'] = 1.2;
//       weights['social'] = 1.1;
//       weights['dinner'] = 1.3;
//     } else {
//       weights['nightlife'] = 1.3;
//       weights['party'] = 1.2;
//       weights['late_night'] = 1.3;
//     }

//     // Weekend boost
//     if (isWeekend) {
//       weights['weekend'] = 1.2;
//       weights['adventure'] = 1.1;
//       weights['social'] = 1.1;
//     } else {
//       weights['weekday'] = 1.1;
//       weights['work'] = 1.1;
//     }

//     // Context-based weights
//     if (context != null) {
//       final mood = context['mood'] as String?;
//       if (mood != null) {
//         switch (mood) {
//           case 'energetic':
//             weights['active'] = 1.3;
//             weights['gym'] = 1.2;
//             break;
//           case 'social':
//             weights['group'] = 1.3;
//             weights['friends'] = 1.2;
//             break;
//           case 'romantic':
//             weights['date'] = 1.3;
//             weights['intimate'] = 1.2;
//             break;
//         }
//       }
//     }

//     return weights;
//   }

//   double _calculateEnhancedScore(
//     double baseScore,
//     VibeCircle circle,
//     Map<String, double> contextWeights,
//     List<VibeTagAssociation> userVibes,
//   ) {
//     double enhancedScore = baseScore;

//     // Activity level boost
//     if (circle.lastActivityAt != null) {
//       final daysSinceActivity = DateTime.now().difference(circle.lastActivityAt!).inDays;
//       if (daysSinceActivity < 7) enhancedScore += 0.1; // Active circles get boost
//     }

//     // Member count sweet spot (not too small, not too large)
//     final memberCount = circle.memberCount;
//     if (memberCount >= 5 && memberCount <= 50) {
//       enhancedScore += 0.05;
//     }

//     // Public circles get slight boost for discoverability
//     if (circle.isPublic) {
//       enhancedScore += 0.02;
//     }

//     return enhancedScore.clamp(0.0, 1.0);
//   }

//   double _applyPlaceContextualScoring(
//     double baseScore,
//     Map<String, dynamic> placeDetails,
//     Map<String, double> contextWeights,
//   ) {
//     double contextualScore = baseScore;

//     // Apply context weights based on place categories
//     final categories = placeDetails['categories'] as List<String>? ?? [];
//     for (final category in categories) {
//       final weight = contextWeights[category.toLowerCase()];
//       if (weight != null) {
//         contextualScore *= weight;
//       }
//     }

//     // Distance penalty (if location available)
//     final distance = placeDetails['distance'] as double?;
//     if (distance != null) {
//       if (distance > 50) contextualScore *= 0.8; // Far places get penalty
//       if (distance < 5) contextualScore *= 1.1; // Close places get boost
//     }

//     // Rating boost
//     final rating = placeDetails['rating'] as double?;
//     if (rating != null && rating >= 4.0) {
//       contextualScore *= 1.05;
//     }

//     return contextualScore.clamp(0.0, 1.0);
//   }

//   // ============================================================================
//   // MATCH REASON GENERATION - Human-Readable Explanations
//   // ============================================================================

//   String _generateMatchReason(VibeCompatibilityScore compatibility, VibeCircle circle) {
//     if (compatibility.sharedVibes.length >= 3) {
//       return 'You share ${compatibility.sharedVibes.length} vibes with this circle';
//     } else if (compatibility.complementaryVibes.isNotEmpty) {
//       return 'Your vibes complement this circle perfectly';
//     } else {
//       return 'Great vibe match with ${(compatibility.overallScore * 100).round()}% compatibility';
//     }
//   }

//   String _generateUserMatchReason(
//     VibeCompatibilityScore compatibility, 
//     List<String> mutualConnections,
//   ) {
//     if (mutualConnections.isNotEmpty) {
//       return 'Similar vibes + ${mutualConnections.length} mutual connections';
//     } else if (compatibility.sharedVibes.length >= 2) {
//       return 'You both love ${compatibility.sharedVibes.take(2).join(' & ')}';
//     } else {
//       return 'Perfect vibe match for new connections';
//     }
//   }

//   String _generatePlaceMatchReason(
//     VibeCompatibilityScore compatibility, 
//     Map<String, dynamic> placeDetails,
//   ) {
//     final sharedVibes = compatibility.sharedVibes;
//     if (sharedVibes.isNotEmpty) {
//       final vibeData = ComprehensiveVibeSystem.comprehensiveVibeTags[sharedVibes.first];
//       if (vibeData != null) {
//         return 'Perfect for your ${vibeData['displayName']} vibe';
//       }
//     }
//     return 'Great match for your vibes';
//   }

//   String _generateBoardMatchReason(
//     VibeCompatibilityScore compatibility, 
//     Map<String, dynamic> boardDetails,
//   ) {
//     return 'Curated collection matching your ${compatibility.sharedVibes.length} favorite vibes';
//   }

//   // ============================================================================
//   // HELPER METHODS & DATA FETCHING
//   // ============================================================================

//   Future<List<Map<String, dynamic>>> _getAllEntityVibes(String entityType) async {
//     try {
//       final snapshot = await _utils.vibeAssociationsCollection
//           .where('entityType', isEqualTo: entityType)
//           .where('strength', isGreaterThan: 0.3) // Only strong associations
//           .get();

//       return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
//     } catch (e) {
//       print('Error getting entity vibes: $e');
//       return [];
//     }
//   }

//   Future<bool> _isUserMemberOfCircle(String userId, String circleId) async {
//     try {
//       final memberDoc = await _utils.circlesCollection
//           .doc(circleId)
//           .collection('members')
//           .doc(userId)
//           .get();
//       return memberDoc.exists;
//     } catch (e) {
//       return false;
//     }
//   }

//   Future<Map<String, dynamic>?> _getUserDetails(String userId) async {
//     try {
//       final userDoc = await _utils.usersCollection.doc(userId).get();
//       if (!userDoc.exists) return null;
      
//       return {
//         'id': userId,
//         'name': userDoc.data()?['name'] ?? 'User',
//         'bio': userDoc.data()?['bio'],
//         'photoUrl': userDoc.data()?['photoUrl'],
//         'joinedAt': userDoc.data()?['createdAt'],
//       };
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
//     try {
//       final placeDoc = await _utils.placesCollection.doc(placeId).get();
//       if (!placeDoc.exists) return null;
      
//       return {
//         'id': placeId,
//         ...placeDoc.data() as Map<String, dynamic>,
//       };
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<Map<String, dynamic>?> _getBoardDetails(String boardId) async {
//     try {
//       final boardDoc = await _utils.boardsCollection.doc(boardId).get();
//       if (!boardDoc.exists) return null;
      
//       return {
//         'id': boardId,
//         ...boardDoc.data() as Map<String, dynamic>,
//       };
//     } catch (e) {
//       return null;
//     }
//   }

//   Future<List<String>> _getMutualConnections(String userId1, String userId2) async {
//     try {
//       // Get circles both users are members of
//       final user1Circles = await _utils.usersCollection
//           .doc(userId1)
//           .collection('circles')
//           .get();
      
//       final user2Circles = await _utils.usersCollection
//           .doc(userId2)
//           .collection('circles')
//           .get();

//       final user1CircleIds = user1Circles.docs.map((doc) => doc.id).toSet();
//       final user2CircleIds = user2Circles.docs.map((doc) => doc.id).toSet();
      
//       return user1CircleIds.intersection(user2CircleIds).toList();
//     } catch (e) {
//       return [];
//     }
//   }

//   double _calculateConnectionStrength(
//     VibeCompatibilityScore compatibility,
//     List<String> mutualConnections,
//   ) {
//     double strength = compatibility.overallScore;
    
//     // Boost for mutual connections
//     strength += mutualConnections.length * 0.1;
    
//     // Boost for shared vibes
//     strength += compatibility.sharedVibes.length * 0.05;
    
//     return strength.clamp(0.0, 1.0);
//   }

//   Future<String> _getCircleActivityLevel(String circleId) async {
//     try {
//       final activitiesSnapshot = await _utils.circlesCollection
//           .doc(circleId)
//           .collection('activities')
//           .where('createdAt', isGreaterThan: Timestamp.fromDate(
//             DateTime.now().subtract(const Duration(days: 7))
//           ))
//           .get();
      
//       final activityCount = activitiesSnapshot.docs.length;
//       if (activityCount >= 10) return 'very_active';
//       if (activityCount >= 5) return 'active';
//       if (activityCount >= 1) return 'moderate';
//       return 'quiet';
//     } catch (e) {
//       return 'unknown';
//     }
//   }

//   Future<Map<String, int>> _getCircleMemberVibeDistribution(String circleId) async {
//     try {
//       final membersSnapshot = await _utils.circlesCollection
//           .doc(circleId)
//           .collection('members')
//           .get();
      
//       final vibeDistribution = <String, int>{};
      
//       for (final memberDoc in membersSnapshot.docs) {
//         final userId = memberDoc.id;
//         final userVibes = await _vibeTagService.getEntityVibeAssociations(userId, 'user');
        
//         for (final vibe in userVibes) {
//           vibeDistribution[vibe.vibeTagId] = (vibeDistribution[vibe.vibeTagId] ?? 0) + 1;
//         }
//       }
      
//       return vibeDistribution;
//     } catch (e) {
//       return {};
//     }
//   }

//   String _predictBestTimeToVisit(
//     Map<String, dynamic> placeDetails,
//     List<VibeTagAssociation> userVibes,
//   ) {
//     // Simple prediction based on place type and user vibes
//     final categories = placeDetails['categories'] as List<String>? ?? [];
    
//     if (categories.contains('nightlife') || categories.contains('bar')) {
//       return 'Evening (7-11 PM)';
//     } else if (categories.contains('cafe') || categories.contains('breakfast')) {
//       return 'Morning (8-11 AM)';
//     } else if (categories.contains('restaurant')) {
//       return 'Lunch (12-2 PM) or Dinner (6-9 PM)';
//     }
    
//     return 'Anytime';
//   }

//   Future<String> _predictCrowdLevel(String placeId) async {
//     // This would integrate with real-time crowd data APIs
//     // For now, return a mock prediction
//     final random = DateTime.now().millisecond % 3;
//     switch (random) {
//       case 0: return 'Low';
//       case 1: return 'Medium';
//       default: return 'High';
//     }
//   }

//   Future<double> _getCuratorCompatibility(String userId, String curatorId) async {
//     if (userId == curatorId) return 1.0; // Perfect match if same user
    
//     try {
//       final compatibility = await _vibeTagService.calculateVibeCompatibility(
//         entityId1: userId,
//         entityType1: 'user',
//         entityId2: curatorId,
//         entityType2: 'user',
//       );
      
//       return compatibility.overallScore;
//     } catch (e) {
//       return 0.5; // Default neutral compatibility
//     }
//   }
// }