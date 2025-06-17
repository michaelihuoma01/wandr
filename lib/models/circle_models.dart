// lib/models/circle_models.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'circle_models.g.dart';

@JsonSerializable()
class VibeCircle {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final String? creatorName;
  final String? imageUrl;
  final bool isPublic;
  final List<String> vibePreferences;
  final CircleCategory category;
  final int memberCount;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  
  // Privacy settings
  final bool requiresApproval;
  final bool allowMemberInvites;
  final bool showMemberVisits;
  
  // Additional settings
  final String? inviteCode;
  final int? memberLimit;
  final Map<String, dynamic>? settings;

  VibeCircle({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    this.creatorName,
    this.imageUrl,
    required this.isPublic,
    required this.vibePreferences,
    required this.category,
    required this.memberCount,
    required this.createdAt,
    required this.lastActivityAt,
    this.requiresApproval = false,
    this.allowMemberInvites = true,
    this.showMemberVisits = true,
    this.inviteCode,
    this.memberLimit,
    this.settings,
  });

  factory VibeCircle.fromJson(Map<String, dynamic> json) => _$VibeCircleFromJson(json);
  Map<String, dynamic> toJson() => _$VibeCircleToJson(this);

  factory VibeCircle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VibeCircle(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'],
      imageUrl: data['imageUrl'],
      isPublic: data['isPublic'] ?? true,
      vibePreferences: List<String>.from(data['vibePreferences'] ?? []),
      category: CircleCategory.fromString(data['category']),
      memberCount: data['memberCount'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp).toDate(),
      requiresApproval: data['requiresApproval'] ?? false,
      allowMemberInvites: data['allowMemberInvites'] ?? true,
      showMemberVisits: data['showMemberVisits'] ?? true,
      inviteCode: data['inviteCode'],
      memberLimit: data['memberLimit'],
      settings: data['settings'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'imageUrl': imageUrl,
      'isPublic': isPublic,
      'vibePreferences': vibePreferences,
      'category': category.name,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivityAt': Timestamp.fromDate(lastActivityAt),
      'requiresApproval': requiresApproval,
      'allowMemberInvites': allowMemberInvites,
      'showMemberVisits': showMemberVisits,
      'inviteCode': inviteCode,
      'memberLimit': memberLimit,
      'settings': settings,
    };
  }
}

enum CircleCategory {
  foodies('Foodies', '🍽️', 'Food & Dining enthusiasts'),
  nightlife('Nightlife', '🎉', 'Clubs, bars, and late-night spots'),
  culture('Culture', '🎭', 'Museums, galleries, and cultural sites'),
  adventure('Adventure', '🏔️', 'Outdoor activities and exploration'),
  wellness('Wellness', '🧘', 'Health, fitness, and relaxation'),
  shopping('Shopping', '🛍️', 'Retail therapy and markets'),
  family('Family', '👨‍👩‍👧‍👦', 'Family-friendly activities'),
  business('Business', '💼', 'Professional networking spots'),
  creative('Creative', '🎨', 'Art, design, and inspiration'),
  other('Other', '✨', 'Everything else');

  final String displayName;
  final String emoji;
  final String description;
  
  const CircleCategory(this.displayName, this.emoji, this.description);
  
  static CircleCategory fromString(String? value) {
    if (value == null) return CircleCategory.other;
    try {
      return CircleCategory.values.firstWhere(
        (cat) => cat.name == value.toLowerCase(),
        orElse: () => CircleCategory.other,
      );
    } catch (e) {
      return CircleCategory.other;
    }
  }
}

@JsonSerializable()
class CircleMembership {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String circleId;
  final MemberRole role;
  final DateTime joinedAt;
  final bool notificationsEnabled;
  final int contributionScore;
  final int checkInsShared;
  final int boardsCreated;
  final int reviewsWritten;
  final DateTime? lastActivityAt;

  CircleMembership({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.circleId,
    required this.role,
    required this.joinedAt,
    this.notificationsEnabled = true,
    this.contributionScore = 0,
    this.checkInsShared = 0,
    this.boardsCreated = 0,
    this.reviewsWritten = 0,
    this.lastActivityAt,
  });

  factory CircleMembership.fromJson(Map<String, dynamic> json) => _$CircleMembershipFromJson(json);
  Map<String, dynamic> toJson() => _$CircleMembershipToJson(this);

  factory CircleMembership.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CircleMembership(
      userId: doc.id,
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      circleId: data['circleId'] ?? '',
      role: MemberRole.fromString(data['role']),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      contributionScore: data['contributionScore'] ?? 0,
      checkInsShared: data['checkInsShared'] ?? 0,
      boardsCreated: data['boardsCreated'] ?? 0,
      reviewsWritten: data['reviewsWritten'] ?? 0,
      lastActivityAt: data['lastActivityAt'] != null 
          ? (data['lastActivityAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'circleId': circleId,
      'role': role.name,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'notificationsEnabled': notificationsEnabled,
      'contributionScore': contributionScore,
      'checkInsShared': checkInsShared,
      'boardsCreated': boardsCreated,
      'reviewsWritten': reviewsWritten,
      'lastActivityAt': lastActivityAt != null 
          ? Timestamp.fromDate(lastActivityAt!) 
          : null,
    };
  }
}

enum MemberRole {
  admin('Admin', 'Full control'),
  moderator('Moderator', 'Can manage content'),
  member('Member', 'Regular member');

  final String displayName;
  final String description;
  
  const MemberRole(this.displayName, this.description);
  
  static MemberRole fromString(String? value) {
    if (value == null) return MemberRole.member;
    try {
      return MemberRole.values.firstWhere(
        (role) => role.name == value.toLowerCase(),
        orElse: () => MemberRole.member,
      );
    } catch (e) {
      return MemberRole.member;
    }
  }
}

@JsonSerializable()
class CircleActivity {
  final String id;
  final String circleId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final ActivityType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final List<String> likedBy;
  final List<ActivityComment> comments;

  CircleActivity({
    required this.id,
    required this.circleId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.type,
    required this.data,
    required this.timestamp,
    this.likedBy = const [],
    this.comments = const [],
  });

  factory CircleActivity.fromJson(Map<String, dynamic> json) => _$CircleActivityFromJson(json);
  Map<String, dynamic> toJson() => _$CircleActivityToJson(this);

  String get title {
    switch (type) {
      case ActivityType.memberJoined:
        return '$userName joined the circle';
      case ActivityType.placeShared:
        return '$userName shared a place';
      case ActivityType.boardCreated:
        return '$userName created a vibe board';
      case ActivityType.microReview:
        return '$userName wrote a quick review';
      case ActivityType.checkIn:
        return '$userName checked in';
      case ActivityType.milestone:
        return data['message'] ?? 'Circle milestone!';
    }
  }

  IconData get icon {
    switch (type) {
      case ActivityType.memberJoined:
        return Icons.person_add;
      case ActivityType.placeShared:
        return Icons.share_location;
      case ActivityType.boardCreated:
        return Icons.dashboard;
      case ActivityType.microReview:
        return Icons.rate_review;
      case ActivityType.checkIn:
        return Icons.location_on;
      case ActivityType.milestone:
        return Icons.celebration;
    }
  }
}

enum ActivityType {
  memberJoined,
  placeShared,
  boardCreated,
  microReview,
  checkIn,
  milestone,
}

@JsonSerializable()
class ActivityComment {
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;

  ActivityComment({
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
  });

  factory ActivityComment.fromJson(Map<String, dynamic> json) => _$ActivityCommentFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityCommentToJson(this);
}

@JsonSerializable()
class VibeBoard {
  final String id;
  final String circleId;
  final String creatorId;
  final String creatorName;
  final String title;
  final String? description;
  final List<BoardPlace> places;
  final List<String> tags;
  final String? coverImageUrl;
  final int likeCount;
  final int saveCount;
  final List<String> likedBy;
  final List<String> savedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  VibeBoard({
    required this.id,
    required this.circleId,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    this.description,
    required this.places,
    this.tags = const [],
    this.coverImageUrl,
    this.likeCount = 0,
    this.saveCount = 0,
    this.likedBy = const [],
    this.savedBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory VibeBoard.fromJson(Map<String, dynamic> json) => _$VibeBoardFromJson(json);
  Map<String, dynamic> toJson() => _$VibeBoardToJson(this);
}

@JsonSerializable()
class BoardPlace {
  final String placeId;
  final String placeName;
  final String placeType;
  final double latitude;
  final double longitude;
  final String? customNote;
  final List<String> vibes;
  final String? imageUrl;
  int orderIndex;

  BoardPlace({
    required this.placeId,
    required this.placeName,
    required this.placeType,
    required this.latitude,
    required this.longitude,
    this.customNote,
    this.vibes = const [],
    this.imageUrl,
    required this.orderIndex,
  });

  factory BoardPlace.fromJson(Map<String, dynamic> json) => _$BoardPlaceFromJson(json);
  Map<String, dynamic> toJson() => _$BoardPlaceToJson(this);
}

@JsonSerializable()
class MicroReview {
  final String id;
  final String placeId;
  final String placeName;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String circleId;
  final String quickTake; // 280 character limit
  final List<String> vibes;
  final int? quickRating; // 1-5
  final List<String>? photoUrls;
  final DateTime createdAt;
  final int likeCount;
  final List<String> likedBy;

  MicroReview({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.circleId,
    required this.quickTake,
    this.vibes = const [],
    this.quickRating,
    this.photoUrls,
    required this.createdAt,
    this.likeCount = 0,
    this.likedBy = const [],
  });

  factory MicroReview.fromJson(Map<String, dynamic> json) => _$MicroReviewFromJson(json);
  Map<String, dynamic> toJson() => _$MicroReviewToJson(this);
}

// Notification model for circle activities
@JsonSerializable()
class CircleNotification {
  final String id;
  final String userId;
  final String circleId;
  final String circleName;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  CircleNotification({
    required this.id,
    required this.userId,
    required this.circleId,
    required this.circleName,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory CircleNotification.fromJson(Map<String, dynamic> json) => _$CircleNotificationFromJson(json);
  Map<String, dynamic> toJson() => _$CircleNotificationToJson(this);
}

enum NotificationType {
  newMember,
  newCheckIn,
  newBoard,
  newReview,
  mention,
  invite,
  milestone,
}

// Helper class for circle discovery
class SuggestedCircle {
  final VibeCircle circle;
  final double compatibilityScore;
  final List<String> matchingVibes;
  final String? reason;

  SuggestedCircle({
    required this.circle,
    required this.compatibilityScore,
    required this.matchingVibes,
    this.reason,
  });
}