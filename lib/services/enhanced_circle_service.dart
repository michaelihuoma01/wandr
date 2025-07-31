import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/circle_models.dart';
import '../models/models.dart';
import 'vibe_tag_service.dart';
import 'auth_service.dart';

class EnhancedCircleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final VibeTagService _vibeTagService = VibeTagService();
  final AuthService _authService = AuthService();

  // ============================================================================
  // ENHANCED CIRCLES WITH VIBE-BASED BOARDS
  // ============================================================================

  /// Create a new circle with automatic vibe detection and board suggestions
  Future<VibeCircle?> createEnhancedCircle({
    required String name,
    required String description,
    required List<String> selectedVibes,
    bool isPrivate = false,
    String? coverImageUrl,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final circleId = _firestore.collection('circles').doc().id;
      final now = DateTime.now();

      // Create the circle
      final circle = VibeCircle(
        id: circleId,
        name: name,
        description: description,
        creatorId: currentUser.uid,
        isPublic: !isPrivate,
        imageUrl: coverImageUrl,
        vibePreferences: selectedVibes,
        category: CircleCategory.other,
        memberCount: 1,
        createdAt: now,
        lastActivityAt: now,
      );

      // Save circle to Firestore
      await _firestore.collection('circles').doc(circleId).set(circle.toJson());

      // Associate vibe tags with the circle
      await _vibeTagService.associateVibesWithEntity(
        entityId: circleId,
        entityType: 'circle',
        vibeTagIds: selectedVibes,
        source: 'user_selected',
        metadata: {
          'created_at': now.toIso8601String(),
          'creator_id': currentUser.uid,
        },
      );

      // Add creator as first member
      await _addCircleMember(circleId, currentUser.uid, 'admin');

      // Create default vibe-based boards for the circle
      await _createDefaultVibeBoards(circleId, selectedVibes, currentUser.uid);

      print('Enhanced circle created: $circleId with vibes: $selectedVibes');
      return circle;
    } catch (e) {
      print('Error creating enhanced circle: $e');
      return null;
    }
  }

  /// Get vibe-compatible circles for a user
  Future<List<Map<String, dynamic>>> getVibeCompatibleCircles(String userId, {int limit = 20}) async {
    try {
      final compatibleCircles = await _vibeTagService.getCompatibleEntities(
        sourceEntityId: userId,
        sourceEntityType: 'user',
        targetEntityType: 'circle',
        limit: limit,
        minCompatibility: 0.4, // 40% minimum vibe match
      );

      final results = <Map<String, dynamic>>[];

      for (final item in compatibleCircles) {
        final circleId = item['entityId'] as String;
        final compatibility = item['compatibilityScore'];
        
        // Get circle data
        final circleDoc = await _firestore.collection('circles').doc(circleId).get();
        if (circleDoc.exists) {
          final circle = VibeCircle.fromJson({
            'id': circleDoc.id,
            ...circleDoc.data()!,
          });

          results.add({
            'circle': circle,
            'compatibility': compatibility,
            'matchReasons': _generateMatchReasons(compatibility),
          });
        }
      }

      return results;
    } catch (e) {
      print('Error getting vibe compatible circles: $e');
      return [];
    }
  }

  /// Get all boards within a circle organized by vibe themes
  Future<Map<String, List<VibeBoard>>> getCircleBoardsByVibe(String circleId) async {
    try {
      // Get all boards in this circle
      final boardsSnapshot = await _firestore
          .collection('boards')
          .where('circleId', isEqualTo: circleId)
          .orderBy('createdAt', descending: true)
          .get();

      final boards = boardsSnapshot.docs.map((doc) => VibeBoard.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();

      // Group boards by their primary vibe
      final vibeBoards = <String, List<VibeBoard>>{};
      
      for (final board in boards) {
        // Get board's vibe associations
        final vibeAssociations = await _vibeTagService.getEntityVibeAssociations(board.id, 'board');
        
        if (vibeAssociations.isNotEmpty) {
          // Find strongest vibe association
          vibeAssociations.sort((a, b) => b.strength.compareTo(a.strength));
          final primaryVibe = vibeAssociations.first.vibeTagId;
          
          if (!vibeBoards.containsKey(primaryVibe)) {
            vibeBoards[primaryVibe] = [];
          }
          vibeBoards[primaryVibe]!.add(board);
        } else {
          // Default category for boards without vibe tags
          if (!vibeBoards.containsKey('general')) {
            vibeBoards['general'] = [];
          }
          vibeBoards['general']!.add(board);
        }
      }

      return vibeBoards;
    } catch (e) {
      print('Error getting circle boards by vibe: $e');
      return {};
    }
  }

  /// Create a new vibe-themed board in a circle
  Future<VibeBoard?> createVibeBoard({
    required String circleId,
    required String name,
    required String description,
    required List<String> vibeTagIds,
    String? coverImageUrl,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return null;

      final boardId = _firestore.collection('boards').doc().id;
      final now = DateTime.now();

      final board = VibeBoard(
        id: boardId,
        circleId: circleId,
        creatorId: currentUser.uid,
        creatorName: currentUser.displayName ?? 'Unknown',
        title: name,
        description: description,
        places: [],
        tags: vibeTagIds,
        coverImageUrl: coverImageUrl,
        createdAt: now,
        updatedAt: now,
      );

      // Save board
      await _firestore.collection('boards').doc(boardId).set(board.toJson());

      // Associate vibe tags with the board
      await _vibeTagService.associateVibesWithEntity(
        entityId: boardId,
        entityType: 'board',
        vibeTagIds: vibeTagIds,
        source: 'user_selected',
        metadata: {
          'circle_id': circleId,
          'created_at': now.toIso8601String(),
        },
      );

      print('Vibe board created: $boardId in circle $circleId with vibes: $vibeTagIds');
      return board;
    } catch (e) {
      print('Error creating vibe board: $e');
      return null;
    }
  }

  /// Get personalized board recommendations for a circle member
  Future<List<Map<String, dynamic>>> getPersonalizedBoardRecommendations(String userId, String circleId) async {
    try {
      // Get user's vibe preferences
      final userVibes = await _vibeTagService.getEntityVibeAssociations(userId, 'user');
      if (userVibes.isEmpty) return [];

      // Get circle's vibe boards
      final circleBoards = await getCircleBoardsByVibe(circleId);
      
      final recommendations = <Map<String, dynamic>>[];

      // Score boards based on user's vibe compatibility
      for (final vibeCategory in circleBoards.entries) {
        final vibe = vibeCategory.key;
        final boards = vibeCategory.value;

        // Check if user has this vibe preference
        final userVibeStrength = userVibes
            .where((v) => v.vibeTagId == vibe)
            .map((v) => v.strength)
            .fold(0.0, (a, b) => a > b ? a : b);

        if (userVibeStrength > 0.3) { // 30% minimum interest
          for (final board in boards) {
            recommendations.add({
              'board': board,
              'vibe': vibe,
              'relevanceScore': userVibeStrength,
              'reason': 'Matches your $vibe vibe (${(userVibeStrength * 100).round()}%)',
            });
          }
        }
      }

      // Sort by relevance score
      recommendations.sort((a, b) => 
        (b['relevanceScore'] as double).compareTo(a['relevanceScore'] as double));

      return recommendations.take(10).toList();
    } catch (e) {
      print('Error getting personalized board recommendations: $e');
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<void> _addCircleMember(String circleId, String userId, String roleName) async {
    try {
      final role = roleName == 'admin' ? MemberRole.admin : MemberRole.member;
      final membership = CircleMembership(
        userId: userId,
        userName: _authService.currentUser?.displayName ?? 'Unknown',
        circleId: circleId,
        role: role,
        joinedAt: DateTime.now(),
      );

      await _firestore
          .collection('circle_memberships')
          .doc('${circleId}_$userId')
          .set(membership.toJson());
    } catch (e) {
      print('Error adding circle member: $e');
    }
  }

  Future<void> _createDefaultVibeBoards(String circleId, List<String> vibeTagIds, String creatorId) async {
    try {
      // Create a board for each selected vibe
      for (final vibeTagId in vibeTagIds) {
        // Get vibe tag details
        final allTags = await _vibeTagService.getAllVibeTags();
        final vibeTag = allTags.firstWhere((tag) => tag.id == vibeTagId);

        await createVibeBoard(
          circleId: circleId,
          name: '${vibeTag.displayName} Spots',
          description: 'Places that match our ${vibeTag.displayName.toLowerCase()} vibe',
          vibeTagIds: [vibeTagId],
        );
      }

      // Create a general "Must-Try" board
      await createVibeBoard(
        circleId: circleId,
        name: 'Must-Try Places',
        description: 'Places everyone in the circle should visit',
        vibeTagIds: vibeTagIds, // Combines all circle vibes
      );
    } catch (e) {
      print('Error creating default vibe boards: $e');
    }
  }

  List<String> _generateMatchReasons(dynamic compatibility) {
    // This would generate human-readable reasons for the match
    // Based on the compatibility score data
    return [
      'Shared love for cozy vibes',
      'Similar social preferences',
      'Compatible discovery styles',
    ];
  }
}

