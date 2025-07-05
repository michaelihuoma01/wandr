import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // FOLLOW/UNFOLLOW OPERATIONS
  // ============================================================================

  /// Follow a user
  Future<void> followUser(String followerId, String followeeId) async {
    if (followerId == followeeId) return; // Can't follow yourself

    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    // Add to follower's following list
    final followingRef = _firestore
        .collection('user_relationships')
        .doc(followerId)
        .collection('following')
        .doc(followeeId);

    batch.set(followingRef, {
      'userId': followeeId,
      'followedAt': timestamp,
      'isActive': true,
    });

    // Add to followee's followers list
    final followerRef = _firestore
        .collection('user_relationships')
        .doc(followeeId)
        .collection('followers')
        .doc(followerId);

    batch.set(followerRef, {
      'userId': followerId,
      'followedAt': timestamp,
      'isActive': true,
    });

    // Update follow counts
    batch.update(_firestore.collection('users').doc(followerId), {
      'followingCount': FieldValue.increment(1),
    });

    batch.update(_firestore.collection('users').doc(followeeId), {
      'followersCount': FieldValue.increment(1),
    });

    // Create follow activity
    final activityRef = _firestore.collection('activities').doc();
    batch.set(activityRef, {
      'type': 'follow',
      'actorId': followerId,
      'targetId': followeeId,
      'timestamp': timestamp,
      'data': {
        'action': 'started_following',
      },
    });

    await batch.commit();
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followerId, String followeeId) async {
    if (followerId == followeeId) return;

    final batch = _firestore.batch();

    // Remove from follower's following list
    final followingRef = _firestore
        .collection('user_relationships')
        .doc(followerId)
        .collection('following')
        .doc(followeeId);

    batch.delete(followingRef);

    // Remove from followee's followers list
    final followerRef = _firestore
        .collection('user_relationships')
        .doc(followeeId)
        .collection('followers')
        .doc(followerId);

    batch.delete(followerRef);

    // Update follow counts
    batch.update(_firestore.collection('users').doc(followerId), {
      'followingCount': FieldValue.increment(-1),
    });

    batch.update(_firestore.collection('users').doc(followeeId), {
      'followersCount': FieldValue.increment(-1),
    });

    await batch.commit();
  }

  /// Check if user A is following user B
  Future<bool> isFollowing(String followerId, String followeeId) async {
    try {
      final doc = await _firestore
          .collection('user_relationships')
          .doc(followerId)
          .collection('following')
          .doc(followeeId)
          .get();

      return doc.exists && (doc.data()?['isActive'] ?? false);
    } catch (e) {
      print('Error checking follow status: $e');
      return false;
    }
  }

  // ============================================================================
  // FOLLOW LISTS & STATISTICS
  // ============================================================================

  /// Get follow statistics for a user
  Future<FollowStats> getFollowStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final followersCount = userData['followersCount'] ?? 0;
      final followingCount = userData['followingCount'] ?? 0;

      // Calculate mutual follows (people who follow each other)
      final mutualFollows = await _getMutualFollowsCount(userId);

      return FollowStats(
        followersCount: followersCount,
        followingCount: followingCount,
        mutualFollowsCount: mutualFollows,
      );
    } catch (e) {
      print('Error getting follow stats: $e');
      return FollowStats(
        followersCount: 0,
        followingCount: 0,
        mutualFollowsCount: 0,
      );
    }
  }

  /// Get list of users that follow the given user
  Future<List<FollowUser>> getFollowers(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_relationships')
          .doc(userId)
          .collection('followers')
          .where('isActive', isEqualTo: true)
          .orderBy('followedAt', descending: true)
          .limit(limit)
          .get();

      final followers = <FollowUser>[];
      
      for (final doc in querySnapshot.docs) {
        final followerId = doc.data()['userId'] as String;
        final userProfile = await _getUserProfile(followerId);
        
        if (userProfile != null) {
          followers.add(FollowUser(
            userId: followerId,
            name: userProfile['name'] ?? 'Unknown',
            profilePicture: userProfile['profilePicture'],
            vibeCompatibility: await _calculateVibeCompatibility(userId, followerId),
            followedAt: (doc.data()['followedAt'] as Timestamp?)?.toDate(),
            isVerified: userProfile['isVerified'] ?? false,
          ));
        }
      }

      return followers;
    } catch (e) {
      print('Error getting followers: $e');
      return [];
    }
  }

  /// Get list of users that the given user follows
  Future<List<FollowUser>> getFollowing(String userId, {int limit = 50}) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_relationships')
          .doc(userId)
          .collection('following')
          .where('isActive', isEqualTo: true)
          .orderBy('followedAt', descending: true)
          .limit(limit)
          .get();

      final following = <FollowUser>[];
      
      for (final doc in querySnapshot.docs) {
        final followeeId = doc.data()['userId'] as String;
        final userProfile = await _getUserProfile(followeeId);
        
        if (userProfile != null) {
          following.add(FollowUser(
            userId: followeeId,
            name: userProfile['name'] ?? 'Unknown',
            profilePicture: userProfile['profilePicture'],
            vibeCompatibility: await _calculateVibeCompatibility(userId, followeeId),
            followedAt: (doc.data()['followedAt'] as Timestamp?)?.toDate(),
            isVerified: userProfile['isVerified'] ?? false,
          ));
        }
      }

      return following;
    } catch (e) {
      print('Error getting following: $e');
      return [];
    }
  }

  // ============================================================================
  // USER DISCOVERY & RECOMMENDATIONS
  // ============================================================================

  /// Discover users with similar vibes
  Future<List<FollowUser>> discoverUsers(String currentUserId, {int limit = 20}) async {
    try {
      // Get current user's vibe profile
      final currentUserProfile = await _getUserProfile(currentUserId);
      if (currentUserProfile == null) return [];

      final currentVibes = _extractUserVibes(currentUserProfile);
      if (currentVibes.isEmpty) return [];

      // Find users with similar vibes
      final usersQuery = await _firestore
          .collection('users')
          .where('vibeProfile.primaryVibes', arrayContainsAny: currentVibes.take(3).toList())
          .limit(limit * 2) // Get more to filter out existing follows
          .get();

      final discoveredUsers = <FollowUser>[];
      final alreadyFollowing = await _getFollowingIds(currentUserId);

      for (final doc in usersQuery.docs) {
        final userId = doc.id;
        
        // Skip self and already following
        if (userId == currentUserId || alreadyFollowing.contains(userId)) {
          continue;
        }

        final userData = doc.data();
        final vibeCompatibility = await _calculateVibeCompatibility(currentUserId, userId);

        // Only recommend users with good compatibility
        if (vibeCompatibility >= 0.3) {
          discoveredUsers.add(FollowUser(
            userId: userId,
            name: userData['name'] ?? 'Unknown',
            profilePicture: userData['profilePicture'],
            vibeCompatibility: vibeCompatibility,
            isVerified: userData['isVerified'] ?? false,
          ));
        }

        if (discoveredUsers.length >= limit) break;
      }

      // Sort by compatibility score
      discoveredUsers.sort((a, b) => b.vibeCompatibility.compareTo(a.vibeCompatibility));
      
      return discoveredUsers;
    } catch (e) {
      print('Error discovering users: $e');
      return [];
    }
  }

  /// Get social activity feed (follows and activities from people you follow)
  Future<List<SocialActivity>> getSocialActivityFeed(String userId, {int limit = 50}) async {
    try {
      final followingIds = await _getFollowingIds(userId);
      if (followingIds.isEmpty) return [];

      final activitiesQuery = await _firestore
          .collection('activities')
          .where('actorId', whereIn: followingIds.take(10).toList()) // Firestore limit
          .where('type', whereIn: ['follow', 'check_in', 'vibe_update'])
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final activities = <SocialActivity>[];
      
      for (final doc in activitiesQuery.docs) {
        final data = doc.data();
        final actorProfile = await _getUserProfile(data['actorId']);
        
        if (actorProfile != null) {
          activities.add(SocialActivity(
            id: doc.id,
            type: data['type'],
            actorId: data['actorId'],
            actorName: actorProfile['name'] ?? 'Unknown',
            actorProfilePicture: actorProfile['profilePicture'],
            timestamp: (data['timestamp'] as Timestamp).toDate(),
            data: Map<String, dynamic>.from(data['data'] ?? {}),
          ));
        }
      }

      return activities;
    } catch (e) {
      print('Error getting social activity feed: $e');
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  Future<int> _getMutualFollowsCount(String userId) async {
    try {
      final following = await _getFollowingIds(userId);
      int mutualCount = 0;

      for (final followeeId in following.take(20)) { // Limit to avoid too many queries
        final isFollowingBack = await isFollowing(followeeId, userId);
        if (isFollowingBack) mutualCount++;
      }

      return mutualCount;
    } catch (e) {
      print('Error calculating mutual follows: $e');
      return 0;
    }
  }

  Future<Set<String>> _getFollowingIds(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_relationships')
          .doc(userId)
          .collection('following')
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toSet();
    } catch (e) {
      print('Error getting following IDs: $e');
      return {};
    }
  }

  List<String> _extractUserVibes(Map<String, dynamic> userProfile) {
    try {
      final vibeProfile = userProfile['vibeProfile'] as Map<String, dynamic>?;
      if (vibeProfile == null) return [];

      final primaryVibes = vibeProfile['primaryVibes'] as List<dynamic>?;
      if (primaryVibes == null) return [];

      return primaryVibes.cast<String>();
    } catch (e) {
      print('Error extracting user vibes: $e');
      return [];
    }
  }

  Future<double> _calculateVibeCompatibility(String userId1, String userId2) async {
    try {
      final user1Profile = await _getUserProfile(userId1);
      final user2Profile = await _getUserProfile(userId2);

      if (user1Profile == null || user2Profile == null) return 0.0;

      final user1Vibes = _extractUserVibes(user1Profile).toSet();
      final user2Vibes = _extractUserVibes(user2Profile).toSet();

      if (user1Vibes.isEmpty || user2Vibes.isEmpty) return 0.0;

      final intersection = user1Vibes.intersection(user2Vibes);
      final union = user1Vibes.union(user2Vibes);

      // Jaccard similarity coefficient
      return intersection.length / union.length;
    } catch (e) {
      print('Error calculating vibe compatibility: $e');
      return 0.0;
    }
  }
}

// ============================================================================
// DATA CLASSES
// ============================================================================

class FollowStats {
  final int followersCount;
  final int followingCount;
  final int mutualFollowsCount;

  FollowStats({
    required this.followersCount,
    required this.followingCount,
    required this.mutualFollowsCount,
  });
}

class FollowUser {
  final String userId;
  final String name;
  final String? profilePicture;
  final double vibeCompatibility;
  final DateTime? followedAt;
  final bool isVerified;

  FollowUser({
    required this.userId,
    required this.name,
    this.profilePicture,
    required this.vibeCompatibility,
    this.followedAt,
    this.isVerified = false,
  });
}

class SocialActivity {
  final String id;
  final String type;
  final String actorId;
  final String actorName;
  final String? actorProfilePicture;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  SocialActivity({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.actorProfilePicture,
    required this.timestamp,
    required this.data,
  });
}