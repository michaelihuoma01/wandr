// lib/services/circle_service.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/models.dart';
import '../models/visit_models.dart';
import '../models/circle_models.dart';
import 'auth_service.dart';

class CircleService {
  static final CircleService _instance = CircleService._internal();
  factory CircleService() => _instance;
  CircleService._internal();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  String? get _userId => _auth.currentUser?.uid;

  // Circle Management
  Future<CircleResult> createCircle({
    required String name,
    required String description,
    required CircleCategory category,
    required List<String> vibePreferences,
    required bool isPublic,
    bool requiresApproval = false,
    bool allowMemberInvites = true,
    bool showMemberVisits = true,
    int? memberLimit,
    String? imageUrl,
  }) async {
    if (_userId == null) {
      return CircleResult(success: false, error: 'User not authenticated');
    }

    try {
      final userName = await _authService.getDisplayName();
      final circleRef = firestore.collection('circles').doc();
      
      // Generate invite code for private circles
      String? inviteCode;
      if (!isPublic) {
        inviteCode = _generateInviteCode();
      }

      final circle = VibeCircle(
        id: circleRef.id,
        name: name,
        description: description,
        creatorId: _userId!,
        creatorName: userName,
        imageUrl: imageUrl,
        isPublic: isPublic,
        vibePreferences: vibePreferences,
        category: category,
        memberCount: 1,
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        requiresApproval: requiresApproval,
        allowMemberInvites: allowMemberInvites,
        showMemberVisits: showMemberVisits,
        inviteCode: inviteCode,
        memberLimit: memberLimit,
      );

      // Create circle document
      await circleRef.set(circle.toFirestore());

      // Add creator as admin member
      final membership = CircleMembership(
        userId: _userId!,
        userName: userName,
        userPhotoUrl: _auth.currentUser?.photoURL,
        circleId: circleRef.id,
        role: MemberRole.admin,
        joinedAt: DateTime.now(),
      );

      await circleRef.collection('members').doc(_userId).set(membership.toFirestore());

      // Add circle reference to user's circles
      await firestore
          .collection('users')
          .doc(_userId)
          .collection('circles')
          .doc(circleRef.id)
          .set({
        'joinedAt': FieldValue.serverTimestamp(),
        'role': MemberRole.admin.name,
      });

      // Create initial activity
      await _addActivity(
        circleId: circleRef.id,
        type: ActivityType.milestone,
        data: {
          'message': 'Circle created!',
          'circleName': name,
        },
      );

      return CircleResult(success: true, circleId: circleRef.id);
    } catch (e) {
      return CircleResult(success: false, error: e.toString());
    }
  }

  Future<CircleResult> joinCircleWithCode(String circleId, {String? inviteCode}) async {
    if (_userId == null) {
      return CircleResult(success: false, error: 'User not authenticated');
    }

    try {
      final circleDoc = await firestore.collection('circles').doc(circleId).get();
      if (!circleDoc.exists) {
        return CircleResult(success: false, error: 'Circle not found');
      }

      final circle = VibeCircle.fromFirestore(circleDoc);

      // Check if already a member
      final memberDoc = await firestore
          .collection('circles')
          .doc(circleId)
          .collection('members')
          .doc(_userId)
          .get();

      if (memberDoc.exists) {
        return CircleResult(success: false, error: 'Already a member of this circle');
      }

      // Check if circle is public or invite code matches
      if (!circle.isPublic && circle.inviteCode != inviteCode) {
        return CircleResult(success: false, error: 'Invalid invite code');
      }

      // Check member limit
      if (circle.memberLimit != null && circle.memberCount >= circle.memberLimit!) {
        return CircleResult(success: false, error: 'Circle is full');
      }

      // Check if approval required
      if (circle.requiresApproval && circle.isPublic) {
        // Create join request
        await firestore
            .collection('circles')
            .doc(circleId)
            .collection('joinRequests')
            .doc(_userId)
            .set({
          'userId': _userId,
          'userName': await _authService.getDisplayName(),
          'userPhotoUrl': _auth.currentUser?.photoURL,
          'requestedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
        });

        return CircleResult(
          success: true,
          message: 'Join request sent. Waiting for approval.',
        );
      }

      // Add member
      await addMemberToCircle(circleId, _userId!);

      return CircleResult(success: true, message: 'Successfully joined circle');
    } catch (e) {
      return CircleResult(success: false, error: e.toString());
    }
  }

  Future<bool> leaveCircle(String circleId) async {
    if (_userId == null) return false;

    try {
      // Remove from circle members
      await firestore
          .collection('circles')
          .doc(circleId)
          .collection('members')
          .doc(_userId)
          .delete();

      // Remove from user's circles
      await firestore
          .collection('users')
          .doc(_userId)
          .collection('circles')
          .doc(circleId)
          .delete();

      // Update member count
      await firestore.collection('circles').doc(circleId).update({
        'memberCount': FieldValue.increment(-1),
      });

      return true;
    } catch (e) {
      print('Error leaving circle: $e');
      return false;
    }
  }

  // Discovery
  Future<List<VibeCircle>> discoverCircles({
    List<String>? vibePreferences,
    CircleCategory? category,
    String? searchQuery,
    bool publicOnly = true,
  }) async {
    try {
      Query<Map<String, dynamic>> query = firestore.collection('circles');

      if (publicOnly) {
        query = query.where('isPublic', isEqualTo: true);
      }

      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }

      if (vibePreferences != null && vibePreferences.isNotEmpty) {
        query = query.where('vibePreferences', arrayContainsAny: vibePreferences);
      }

      final snapshot = await query.limit(20).get();
      
      var circles = snapshot.docs
          .map((doc) => VibeCircle.fromFirestore(doc))
          .toList();

      // Apply search filter locally if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        circles = circles.where((circle) =>
            circle.name.toLowerCase().contains(lowerQuery) ||
            circle.description.toLowerCase().contains(lowerQuery)
        ).toList();
      }

      return circles;
    } catch (e) {
      print('Error discovering circles: $e');
      return [];
    }
  }

  Future<List<VibeCircle>> getUserCircles([String? userId]) async {
    final targetUserId = userId ?? _userId;
    if (targetUserId == null) return [];

    try {
      final userCircles = await firestore
          .collection('users')
          .doc(targetUserId)
          .collection('circles')
          .get();

      final circleIds = userCircles.docs.map((doc) => doc.id).toList();
      
      if (circleIds.isEmpty) return [];

      final circles = <VibeCircle>[];
      
      // Fetch each circle (Firestore doesn't support 'in' queries with more than 10 items)
      for (final batch in _batchList(circleIds, 10)) {
        final snapshot = await firestore
            .collection('circles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        circles.addAll(
          snapshot.docs.map((doc) => VibeCircle.fromFirestore(doc))
        );
      }

      return circles;
    } catch (e) {
      print('Error getting user circles: $e');
      return [];
    }
  }

  Future<List<VibeCircle>> getPublicCircles({int limit = 20}) async {
    try {
      final snapshot = await firestore
          .collection('circles')
          .where('isPublic', isEqualTo: true)
          .orderBy('memberCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => VibeCircle.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting public circles: $e');
      return [];
    }
  }

  Future<CircleResult> joinCircle(String circleId, String userId) async {
    try {
      final circleDoc = await firestore.collection('circles').doc(circleId).get();
      if (!circleDoc.exists) {
        return CircleResult(success: false, error: 'Circle not found');
      }

      final circle = VibeCircle.fromFirestore(circleDoc);

      // Check if already a member
      final memberDoc = await firestore
          .collection('circles')
          .doc(circleId)
          .collection('members')
          .doc(userId)
          .get();

      if (memberDoc.exists) {
        return CircleResult(success: false, error: 'Already a member of this circle');
      }

      // Check member limit
      if (circle.memberLimit != null && circle.memberCount >= circle.memberLimit!) {
        return CircleResult(success: false, error: 'Circle is full');
      }

      // Add member
      await addMemberToCircle(circleId, userId);

      return CircleResult(success: true, message: 'Successfully joined circle');
    } catch (e) {
      return CircleResult(success: false, error: e.toString());
    }
  }

  Future<List<SuggestedCircle>> getCircleSuggestions() async {
    if (_userId == null) return [];

    try {
      // Get user's vibe preferences from their visit history
      final userVibes = await _analyzeUserVibePreferences();
      
      if (userVibes.isEmpty) {
        // Return popular circles if no vibe history
        final popularCircles = await firestore
            .collection('circles')
            .where('isPublic', isEqualTo: true)
            .orderBy('memberCount', descending: true)
            .limit(10)
            .get();

        return popularCircles.docs.map((doc) {
          final circle = VibeCircle.fromFirestore(doc);
          return SuggestedCircle(
            circle: circle,
            compatibilityScore: 0.5,
            matchingVibes: [],
            reason: 'Popular circle with ${circle.memberCount} members',
          );
        }).toList();
      }

      // Find circles with matching vibes
      final suggestedCircles = await firestore
          .collection('circles')
          .where('isPublic', isEqualTo: true)
          .where('vibePreferences', arrayContainsAny: userVibes.take(5).toList())
          .limit(20)
          .get();

      // Calculate compatibility scores
      final suggestions = suggestedCircles.docs.map((doc) {
        final circle = VibeCircle.fromFirestore(doc);
        final matchingVibes = circle.vibePreferences
            .where((vibe) => userVibes.contains(vibe))
            .toList();
        
        final score = matchingVibes.length / circle.vibePreferences.length;
        
        return SuggestedCircle(
          circle: circle,
          compatibilityScore: score,
          matchingVibes: matchingVibes,
          reason: 'Matches ${matchingVibes.length} of your favorite vibes',
        );
      }).toList();

      // Sort by compatibility score
      suggestions.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));

      return suggestions.take(10).toList();
    } catch (e) {
      print('Error getting circle suggestions: $e');
      return [];
    }
  }

  // Activity & Sharing
  Future<void> shareCheckIn({
    required String circleId,
    required PlaceVisit visit,
    String? note,
  }) async {
    if (_userId == null) return;

    try {
      await _addActivity(
        circleId: circleId,
        type: ActivityType.checkIn,
        data: {
          'placeId': visit.placeId,
          'placeName': visit.placeName,
          'placeType': visit.placeType,
          'latitude': visit.latitude,
          'longitude': visit.longitude,
          'vibes': visit.vibes,
          'rating': visit.rating,
          'note': note ?? visit.userNote,
          'visitTime': visit.visitTime.toIso8601String(),
          'photoUrls': visit.photoUrls,
        },
      );

      // Update member contribution score
      await _updateContributionScore(circleId, _userId!, 'checkInsShared');
    } catch (e) {
      print('Error sharing check-in: $e');
    }
  }

  Future<void> sharePlace({
    required String circleId,
    required PlaceDetails place,
    required String note,
    List<String>? vibes,
  }) async {
    if (_userId == null) return;

    try {
      await _addActivity(
        circleId: circleId,
        type: ActivityType.placeShared,
        data: {
          'placeId': place.placeId,
          'placeName': place.name,
          'placeType': place.type,
          'description': place.description,
          'latitude': place.latitude,
          'longitude': place.longitude,
          'note': note,
          'vibes': vibes ?? [],
          'imageUrl': place.imageUrls?.isNotEmpty == true ? place.imageUrls!.first : null,
          'rating': place.rating,
          'priceLevel': place.priceLevel,
        },
      );
    } catch (e) {
      print('Error sharing place: $e');
    }
  }

  Stream<List<CircleActivity>> getCircleFeed(String circleId) {
    return firestore
        .collection('circles')
        .doc(circleId)
        .collection('activity')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CircleActivity.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  // Vibe Boards
  Future<String?> createVibeBoard({
    required String circleId,
    required String title,
    String? description,
    required List<BoardPlace> places,
    List<String>? tags,
  }) async {
    if (_userId == null) return null;

    try {
      final userName = await _authService.getDisplayName();
      final boardRef = firestore
          .collection('circles')
          .doc(circleId)
          .collection('boards')
          .doc();

   final board = VibeBoard(
        id: boardRef.id,
        circleId: circleId,
        creatorId: _userId!,
        creatorName: userName,
        title: title,
        description: description,
        places: places,
        tags: tags ?? [],
        coverImageUrl: places.isNotEmpty ? places.first.imageUrl : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        likedBy: [],
        savedBy: [],
        likeCount: 0,
        saveCount: 0,
      );

      // Convert BoardPlace objects to JSON
      final boardJson = board.toJson();
      boardJson['places'] = places.map((place) => place.toJson()).toList();

      await boardRef.set(boardJson);

      // Add activity
      await _addActivity(
        circleId: circleId,
        type: ActivityType.boardCreated,
        data: {
          'boardId': boardRef.id,
          'boardTitle': title,
          'placeCount': places.length,
          'coverImageUrl': board.coverImageUrl,
        },
      );

      // Update contribution score
      await _updateContributionScore(circleId, _userId!, 'boardsCreated');

      return boardRef.id;
    } catch (e) {
      print('Error creating vibe board: $e');
      return null;
    }
  }

  Future<List<VibeBoard>> getCircleBoards(String circleId) async {
    try {
      final snapshot = await firestore
          .collection('circles')
          .doc(circleId)
          .collection('boards')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => VibeBoard.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      print('Error getting circle boards: $e');
      return [];
    }
  }

  // Members
  Future<List<CircleMembership>> getCircleMembers(String circleId) async {
    try {
      final snapshot = await firestore
          .collection('circles')
          .doc(circleId)
          .collection('members')
          .orderBy('contributionScore', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CircleMembership.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting circle members: $e');
      return [];
    }
  }

  // Micro Reviews
  Future<void> createMicroReview({
    required String circleId,
    required String placeId,
    required String placeName,
    required String quickTake,
    List<String>? vibes,
    int? rating,
    List<String>? photoUrls,
  }) async {
    if (_userId == null) return;

    try {
      final userName = await _authService.getDisplayName();
      final reviewRef = firestore
          .collection('circles')
          .doc(circleId)
          .collection('microReviews')
          .doc();

      final review = MicroReview(
        id: reviewRef.id,
        placeId: placeId,
        placeName: placeName,
        userId: _userId!,
        userName: userName,
        userPhotoUrl: _auth.currentUser?.photoURL,
        circleId: circleId,
        quickTake: quickTake,
        vibes: vibes ?? [],
        quickRating: rating,
        photoUrls: photoUrls,
        createdAt: DateTime.now(),
      );

      await reviewRef.set(review.toJson());

      // Add activity
      await _addActivity(
        circleId: circleId,
        type: ActivityType.microReview,
        data: {
          'reviewId': reviewRef.id,
          'placeId': placeId,
          'placeName': placeName,
          'quickTake': quickTake,
          'rating': rating,
          'photoUrl': photoUrls?.isNotEmpty == true ? photoUrls!.first : null,
        },
      );

      // Update contribution score
      await _updateContributionScore(circleId, _userId!, 'reviewsWritten');
    } catch (e) {
      print('Error creating micro review: $e');
    }
  }

  // Notifications
  Stream<List<CircleNotification>> getCircleNotifications() {
    if (_userId == null) return Stream.value([]);

    return firestore
        .collection('notifications')
        .doc(_userId)
        .collection('circle_notifications')
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CircleNotification.fromJson({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (_userId == null) return;

    await firestore
        .collection('notifications')
        .doc(_userId)
        .collection('circle_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Helper methods
  Future<void> addMemberToCircle(String circleId, String userId) async {
    final userName = await _authService.getDisplayName();
    
    final membership = CircleMembership(
      userId: userId,
      userName: userName,
      userPhotoUrl: _auth.currentUser?.photoURL,
      circleId: circleId,
      role: MemberRole.member,
      joinedAt: DateTime.now(),
    );

    // Add to circle members
    await firestore
        .collection('circles')
        .doc(circleId)
        .collection('members')
        .doc(userId)
        .set(membership.toFirestore());

    // Add to user's circles
    await firestore
        .collection('users')
        .doc(userId)
        .collection('circles')
        .doc(circleId)
        .set({
      'joinedAt': FieldValue.serverTimestamp(),
      'role': MemberRole.member.name,
    });

    // Update member count
    await firestore.collection('circles').doc(circleId).update({
      'memberCount': FieldValue.increment(1),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // Add join activity
    await _addActivity(
      circleId: circleId,
      type: ActivityType.memberJoined,
      data: {'newMemberId': userId},
    );
  }

  Future<void> _addActivity({
    required String circleId,
    required ActivityType type,
    required Map<String, dynamic> data,
  }) async {
    if (_userId == null) return;

    final userName = await _authService.getDisplayName();
    
    final activityRef = firestore
        .collection('circles')
        .doc(circleId)
        .collection('activity')
        .doc();

    final activity = CircleActivity(
      id: activityRef.id,
      circleId: circleId,
      userId: _userId!,
      userName: userName,
      userPhotoUrl: _auth.currentUser?.photoURL,
      type: type,
      data: data,
      timestamp: DateTime.now(),
    );

    await activityRef.set(activity.toJson());

    // Update circle last activity
    await firestore.collection('circles').doc(circleId).update({
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updateContributionScore(
    String circleId,
    String userId,
    String field,
  ) async {
    await firestore
        .collection('circles')
        .doc(circleId)
        .collection('members')
        .doc(userId)
        .update({
      field: FieldValue.increment(1),
      'contributionScore': FieldValue.increment(10),
      'lastActivityAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> _analyzeUserVibePreferences() async {
    if (_userId == null) return [];

    try {
      // Get user's recent visits
      final visits = await firestore
          .collection('visits')
          .where('userId', isEqualTo: _userId)
          .orderBy('visitTime', descending: true)
          .limit(50)
          .get();

      // Count vibe occurrences
      final vibeCount = <String, int>{};
      
      for (final doc in visits.docs) {
        final vibes = List<String>.from(doc.data()['vibes'] ?? []);
        for (final vibe in vibes) {
          vibeCount[vibe] = (vibeCount[vibe] ?? 0) + 1;
        }
      }

      // Sort by frequency
      final sortedVibes = vibeCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedVibes.map((e) => e.key).toList();
    } catch (e) {
      print('Error analyzing user vibes: $e');
      return [];
    }
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = math.Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  List<List<T>> _batchList<T>(List<T> list, int batchSize) {
    final batches = <List<T>>[];
    for (var i = 0; i < list.length; i += batchSize) {
      final end = (i + batchSize < list.length) ? i + batchSize : list.length;
      batches.add(list.sublist(i, end));
    }
    return batches;
  }

  // Reactions Management
  Future<bool> toggleReaction({
    required String circleId,
    required String activityId,
    required String emoji,
  }) async {
    if (_userId == null) return false;

    try {
      final activityRef = firestore
          .collection('circles')
          .doc(circleId)
          .collection('activity')
          .doc(activityId);

      final doc = await activityRef.get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final reactions = Map<String, List<dynamic>>.from(data['reactions'] ?? {});
      
      // Check if user already reacted
      String? existingReaction;
      for (final entry in reactions.entries) {
        if (entry.value.contains(_userId)) {
          existingReaction = entry.key;
          break;
        }
      }

      // Remove existing reaction if any
      if (existingReaction != null) {
        reactions[existingReaction]!.remove(_userId);
        if (reactions[existingReaction]!.isEmpty) {
          reactions.remove(existingReaction);
        }
      }

      // Add new reaction if different from existing
      if (existingReaction != emoji) {
        if (!reactions.containsKey(emoji)) {
          reactions[emoji] = [];
        }
        reactions[emoji]!.add(_userId);
      }

      await activityRef.update({'reactions': reactions});
      return true;
    } catch (e) {
      print('Error toggling reaction: $e');
      return false;
    }
  }

  // Comments Management
  Future<bool> addComment({
    required String circleId,
    required String activityId,
    required String text,
  }) async {
    if (_userId == null) return false;

    try {
      final userName = await _authService.getDisplayName();
      final comment = ActivityComment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _userId!,
        userName: userName,
        userPhotoUrl: _auth.currentUser?.photoURL,
        text: text,
        timestamp: DateTime.now(),
      );

      await firestore
          .collection('circles')
          .doc(circleId)
          .collection('activity')
          .doc(activityId)
          .update({
        'comments': FieldValue.arrayUnion([comment.toJson()]),
      });

      // Send notification to activity creator if not self
      final activityDoc = await firestore
          .collection('circles')
          .doc(circleId)
          .collection('activity')
          .doc(activityId)
          .get();
      
      if (activityDoc.exists && activityDoc.data()!['userId'] != _userId) {
        await _sendCommentNotification(
          circleId: circleId,
          activityId: activityId,
          activityUserId: activityDoc.data()!['userId'],
          commenterName: userName,
        );
      }

      return true;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  // Legacy like functionality (can coexist with reactions)
  Future<bool> toggleLike({
    required String circleId,
    required String activityId,
  }) async {
    if (_userId == null) return false;

    try {
      final activityRef = firestore
          .collection('circles')
          .doc(circleId)
          .collection('activity')
          .doc(activityId);

      final doc = await activityRef.get();
      if (!doc.exists) return false;

      final likedBy = List<String>.from(doc.data()!['likedBy'] ?? []);
      
      if (likedBy.contains(_userId)) {
        likedBy.remove(_userId);
      } else {
        likedBy.add(_userId!);
      }

      await activityRef.update({'likedBy': likedBy});
      return true;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Push Notification Setup
  Future<void> updateFCMToken(String token) async {
    if (_userId == null) return;

    try {
      await firestore.collection('users').doc(_userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<void> removeFCMToken(String token) async {
    if (_userId == null) return;

    try {
      await firestore.collection('users').doc(_userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  // Private notification helper
  Future<void> _sendCommentNotification({
    required String circleId,
    required String activityId,
    required String activityUserId,
    required String commenterName,
  }) async {
    try {
      await firestore
          .collection('notifications')
          .doc(activityUserId)
          .collection('circle_notifications')
          .add({
        'type': 'comment',
        'circleId': circleId,
        'activityId': activityId,
        'title': 'New Comment',
        'body': '$commenterName commented on your post',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending comment notification: $e');
    }
  }
}

// Result class
class CircleResult {
  final bool success;
  final String? circleId;
  final String? message;
  final String? error;

  CircleResult({
    required this.success,
    this.circleId,
    this.message,
    this.error,
  });
}