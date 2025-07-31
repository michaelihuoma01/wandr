// import 'dart:async';
// import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import '../models/models.dart';
// import '../models/visit_models.dart';
// import '../models/circle_models.dart';
// import 'auth_service.dart';
// import 'vibe_tag_service.dart';
// import 'shared_utilities_service.dart';

// // ============================================================================
// // UNIFIED CIRCLE SERVICE - Consolidates circle_service.dart and enhanced_circle_service.dart
// // ============================================================================

// class UnifiedCircleService {
//   static final UnifiedCircleService _instance = UnifiedCircleService._internal();
//   factory UnifiedCircleService() => _instance;
//   UnifiedCircleService._internal();

//   final SharedUtilitiesService _utils = SharedUtilitiesService();
//   final VibeTagService _vibeTagService = VibeTagService();
//   final AuthService _authService = AuthService();

//   // Use shared utilities for common operations
//   FirebaseFirestore get _firestore => FirebaseFirestore.instance;
//   String? get _userId => _utils.currentUserId;
//   User? get _currentUser => _utils.currentUser;

//   // ============================================================================
//   // CIRCLE CREATION - Unified approach with optional vibe enhancement
//   // ============================================================================

//   /// Create a new circle with optional vibe enhancement
//   Future<CircleResult> createCircle({
//     required String name,
//     required String description,
//     required CircleCategory category,
//     required List<String> vibePreferences,
//     required bool isPublic,
//     bool requiresApproval = false,
//     bool allowMemberInvites = true,
//     bool showMemberVisits = true,
//     int? memberLimit,
//     String? imageUrl,
//     bool enableVibeFeatures = true, // New: Enable enhanced vibe features
//   }) async {
//     return await _utils.executeWithErrorHandling(() async {
//       if (!_utils.isAuthenticated) {
//         return CircleResult(success: false, error: 'User not authenticated');
//       }

//       final userName = await _authService.getDisplayName();
//       final circleRef = _utils.circlesCollection.doc();
//       final now = DateTime.now();
      
//       // Generate invite code for private circles
//       String? inviteCode;
//       if (!isPublic) {
//         inviteCode = _generateInviteCode();
//       }

//       final circle = VibeCircle(
//         id: circleRef.id,
//         name: name,
//         description: description,
//         creatorId: _userId!,
//         creatorName: userName,
//         imageUrl: imageUrl,
//         isPublic: isPublic,
//         vibePreferences: vibePreferences,
//         category: category,
//         memberCount: 1,
//         createdAt: now,
//         lastActivityAt: now,
//         requiresApproval: requiresApproval,
//         allowMemberInvites: allowMemberInvites,
//         showMemberVisits: showMemberVisits,
//         inviteCode: inviteCode,
//         memberLimit: memberLimit,
//       );

//       // Create circle document
//       await circleRef.set(circle.toFirestore());

//       // Enhanced vibe features
//       if (enableVibeFeatures && vibePreferences.isNotEmpty) {
//         await _associateVibesWithCircle(circleRef.id, vibePreferences, now);
//         await _createDefaultVibeBoards(circleRef.id, vibePreferences, _userId!);
//       }

//       // Add creator as admin member
//       await _addCircleMember(circleRef.id, _userId!, userName, MemberRole.admin);

//       // Create initial activity
//       await _addActivity(
//         circleId: circleRef.id,
//         type: ActivityType.milestone,
//         data: {
//           'message': 'Circle created!',
//           'circleName': name,
//         },
//       );

//       return CircleResult(success: true, circleId: circleRef.id);
//     }, 'createCircle') ?? CircleResult(success: false, error: 'Failed to create circle');
//   }

//   // ============================================================================
//   // VIBE-BASED CIRCLE DISCOVERY - Enhanced functionality
//   // ============================================================================

//   /// Get vibe-compatible circles for a user
//   Future<List<Map<String, dynamic>>> getVibeCompatibleCircles(
//     String userId, {
//     int limit = 20,
//     double minCompatibility = 0.4,
//   }) async {
//     try {
//       final compatibleCircles = await _vibeTagService.getCompatibleEntities(
//         sourceEntityId: userId,
//         sourceEntityType: 'user',
//         targetEntityType: 'circle',
//         limit: limit,
//         minCompatibility: minCompatibility,
//       );

//       final results = <Map<String, dynamic>>[];

//       for (final item in compatibleCircles) {
//         final circleId = item['entityId'] as String;
//         final compatibility = item['compatibilityScore'];
        
//         // Get circle data
//         final circleDoc = await _utils.circlesCollection.doc(circleId).get();
//         if (circleDoc.exists) {
//           final circle = VibeCircle.fromJson({
//             'id': circleDoc.id,
//             ...circleDoc.data() as Map<String, dynamic>,
//           });

//           results.add({
//             'circle': circle,
//             'compatibilityScore': compatibility,
//             'isJoined': await _isUserMemberOfCircle(userId, circleId),
//           });
//         }
//       }

//       // Sort by compatibility score
//       results.sort((a, b) => b['compatibilityScore'].overallScore
//           .compareTo(a['compatibilityScore'].overallScore));

//       return results;
//     } catch (e) {
//       print('Error getting vibe compatible circles: $e');
//       return [];
//     }
//   }

//   /// Search circles by vibe tags
//   Future<List<VibeCircle>> searchCirclesByVibes(
//     List<String> vibeTagIds, {
//     int limit = 20,
//     bool publicOnly = true,
//   }) async {
//     try {
//       // Get circles that have these vibe tags
//       final circleIds = await _vibeTagService.getEntitiesWithVibes(
//         vibeTagIds, 
//         'circle',
//         minStrength: 0.5,
//       );

//       if (circleIds.isEmpty) return [];

//       final circles = <VibeCircle>[];
      
//       // Batch get circle documents
//       for (int i = 0; i < circleIds.length; i += 10) { // Firestore limit is 10 for 'in' queries
//         final batch = circleIds.skip(i).take(10).toList();
        
//         Query query = _utils.circlesCollection.where(FieldPath.documentId, whereIn: batch);
        
//         if (publicOnly) {
//           query = query.where('isPublic', isEqualTo: true);
//         }
        
//         final snapshot = await query.limit(limit).get();
        
//         for (final doc in snapshot.docs) {
//           final circle = VibeCircle.fromJson({
//             'id': doc.id,
//             ...doc.data() as Map<String, dynamic>,
//           });
//           circles.add(circle);
//         }
//       }

//       return circles.take(limit).toList();
//     } catch (e) {
//       print('Error searching circles by vibes: $e');
//       return [];
//     }
//   }

//   // ============================================================================
//   // CIRCLE MEMBERSHIP - Consolidated methods
//   // ============================================================================

//   /// Join a circle with invite code
//   Future<CircleResult> joinCircleWithCode(String circleId, {String? inviteCode}) async {
//     return await _utils.executeWithErrorHandling(() async {
//       if (!_utils.isAuthenticated) {
//         return CircleResult(success: false, error: 'User not authenticated');
//       }

//       final circleDoc = await _utils.circlesCollection.doc(circleId).get();
//       if (!circleDoc.exists) {
//         return CircleResult(success: false, error: 'Circle not found');
//       }

//       final circle = VibeCircle.fromFirestore(circleDoc);

//       // Check if already a member
//       if (await _isUserMemberOfCircle(_userId!, circleId)) {
//         return CircleResult(success: false, error: 'Already a member of this circle');
//       }

//       // Check if circle is public or invite code matches
//       if (!circle.isPublic && circle.inviteCode != inviteCode) {
//         return CircleResult(success: false, error: 'Invalid invite code');
//       }

//       // Check member limit
//       if (circle.memberLimit != null && circle.memberCount >= circle.memberLimit!) {
//         return CircleResult(success: false, error: 'Circle is full');
//       }

//       final userName = await _authService.getDisplayName();

//       // Add member
//       await _addCircleMember(circleId, _userId!, userName, MemberRole.member);

//       // Update member count
//       await _updateCircleMemberCount(circleId, 1);

//       // Add activity
//       await _addActivity(
//         circleId: circleId,
//         type: ActivityType.memberJoined,
//         data: {
//           'userId': _userId!,
//           'userName': userName,
//         },
//       );

//       return CircleResult(success: true, circleId: circleId);
//     }, 'joinCircleWithCode') ?? CircleResult(success: false, error: 'Failed to join circle');
//   }

//   /// Leave a circle
//   Future<CircleResult> leaveCircle(String circleId) async {
//     return await _utils.executeWithErrorHandling(() async {
//       if (!_utils.isAuthenticated) {
//         return CircleResult(success: false, error: 'User not authenticated');
//       }

//       // Check if user is a member
//       if (!await _isUserMemberOfCircle(_userId!, circleId)) {
//         return CircleResult(success: false, error: 'Not a member of this circle');
//       }

//       // Remove member
//       await _removeMember(circleId, _userId!);

//       return CircleResult(success: true, circleId: circleId);
//     }, 'leaveCircle') ?? CircleResult(success: false, error: 'Failed to leave circle');
//   }

//   // ============================================================================
//   // HELPER METHODS - Consolidated and optimized
//   // ============================================================================

//   /// Associate vibe tags with circle
//   Future<void> _associateVibesWithCircle(
//     String circleId, 
//     List<String> vibeTagIds, 
//     DateTime timestamp,
//   ) async {
//     await _vibeTagService.associateVibesWithEntity(
//       entityId: circleId,
//       entityType: 'circle',
//       vibeTagIds: vibeTagIds,
//       source: 'user_selected',
//       metadata: {
//         'created_at': timestamp.toIso8601String(),
//         'creator_id': _userId!,
//       },
//     );
//   }

//   /// Create default vibe-based boards for circle
//   Future<void> _createDefaultVibeBoards(
//     String circleId, 
//     List<String> vibeTagIds, 
//     String creatorId,
//   ) async {
//     try {
//       final vibeBoards = [
//         {
//           'name': 'Hidden Gems',
//           'description': 'Secret spots that match our vibe',
//           'vibes': vibeTagIds.take(2).toList(),
//         },
//         {
//           'name': 'Weekend Plans',
//           'description': 'Perfect spots for our group hangouts',
//           'vibes': vibeTagIds.take(3).toList(),
//         },
//       ];

//       for (final boardData in vibeBoards) {
//         final boardRef = _firestore.collection('circles').doc(circleId).collection('boards').doc();
        
//         await boardRef.set({
//           'id': boardRef.id,
//           'name': boardData['name'],
//           'description': boardData['description'],
//           'createdBy': creatorId,
//           'createdAt': FieldValue.serverTimestamp(),
//           'vibes': boardData['vibes'],
//           'places': [],
//           'isDefault': true,
//         });
//       }
//     } catch (e) {
//       print('Error creating default vibe boards: $e');
//     }
//   }

//   /// Add member to circle
//   Future<void> _addCircleMember(
//     String circleId, 
//     String userId, 
//     String userName, 
//     MemberRole role,
//   ) async {
//     final membership = CircleMembership(
//       userId: userId,
//       userName: userName,
//       userPhotoUrl: _currentUser?.photoURL,
//       circleId: circleId,
//       role: role,
//       joinedAt: DateTime.now(),
//     );

//     final batch = _utils.createBatch();

//     // Add to circle members
//     batch.set(
//       _utils.circlesCollection.doc(circleId).collection('members').doc(userId),
//       membership.toFirestore(),
//     );

//     // Add to user's circles
//     batch.set(
//       _utils.usersCollection.doc(userId).collection('circles').doc(circleId),
//       {
//         'joinedAt': FieldValue.serverTimestamp(),
//         'role': role.name,
//       },
//     );

//     await batch.commit();
//   }

//   /// Check if user is member of circle
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

//   /// Update circle member count
//   Future<void> _updateCircleMemberCount(String circleId, int increment) async {
//     await _utils.circlesCollection.doc(circleId).update({
//       'memberCount': FieldValue.increment(increment),
//       'lastActivityAt': FieldValue.serverTimestamp(),
//     });
//   }

//   /// Remove member from circle
//   Future<void> _removeMember(String circleId, String userId) async {
//     final userName = await _authService.getDisplayName();
    
//     final batch = _utils.createBatch();

//     // Remove from circle members
//     batch.delete(_utils.circlesCollection.doc(circleId).collection('members').doc(userId));

//     // Remove from user's circles
//     batch.delete(_utils.usersCollection.doc(userId).collection('circles').doc(circleId));

//     await batch.commit();

//     // Update member count
//     await _updateCircleMemberCount(circleId, -1);

//     // Add activity
//     await _addActivity(
//       circleId: circleId,
//       type: ActivityType.memberLeft,
//       data: {
//         'userId': userId,
//         'userName': userName,
//       },
//     );
//   }

//   /// Add activity to circle
//   Future<void> _addActivity({
//     required String circleId,
//     required ActivityType type,
//     required Map<String, dynamic> data,
//   }) async {
//     try {
//       await _utils.circlesCollection
//           .doc(circleId)
//           .collection('activities')
//           .add({
//         'type': type.name,
//         'data': data,
//         'createdAt': FieldValue.serverTimestamp(),
//         'createdBy': _userId,
//       });
//     } catch (e) {
//       print('Error adding activity: $e');
//     }
//   }

//   /// Generate unique invite code
//   String _generateInviteCode() {
//     const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
//     final random = math.Random();
//     return String.fromCharCodes(
//       Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
//     );
//   }

//   // ============================================================================
//   // PUBLIC API METHODS - Keep existing interface
//   // ============================================================================

//   /// Get user's circles
//   Future<List<VibeCircle>> getUserCircles(String userId) async {
//     try {
//       final userCirclesSnapshot = await _utils.usersCollection
//           .doc(userId)
//           .collection('circles')
//           .get();

//       if (userCirclesSnapshot.docs.isEmpty) return [];

//       final circleIds = userCirclesSnapshot.docs.map((doc) => doc.id).toList();
//       final circles = <VibeCircle>[];

//       // Batch get circle documents
//       for (int i = 0; i < circleIds.length; i += 10) {
//         final batch = circleIds.skip(i).take(10).toList();
//         final snapshot = await _utils.circlesCollection
//             .where(FieldPath.documentId, whereIn: batch)
//             .get();

//         for (final doc in snapshot.docs) {
//           final circle = VibeCircle.fromJson({
//             'id': doc.id,
//             ...doc.data() as Map<String, dynamic>,
//           });
//           circles.add(circle);
//         }
//       }

//       return circles;
//     } catch (e) {
//       print('Error getting user circles: $e');
//       return [];
//     }
//   }

//   /// Get public circles
//   Future<List<VibeCircle>> getPublicCircles({int limit = 20}) async {
//     try {
//       final snapshot = await _utils.circlesCollection
//           .where('isPublic', isEqualTo: true)
//           .orderBy('memberCount', descending: true)
//           .limit(limit)
//           .get();

//       return snapshot.docs.map((doc) {
//         return VibeCircle.fromJson({
//           'id': doc.id,
//           ...doc.data() as Map<String, dynamic>,
//         });
//       }).toList();
//     } catch (e) {
//       print('Error getting public circles: $e');
//       return [];
//     }
//   }
// }

// // ============================================================================
// // RESULT CLASSES - Keep existing interfaces
// // ============================================================================

// class CircleResult {
//   final bool success;
//   final String? error;
//   final String? circleId;

//   CircleResult({required this.success, this.error, this.circleId});
// }

// enum ActivityType {
//   milestone,
//   memberJoined,
//   memberLeft,
//   placeAdded,
//   visitShared,
// }