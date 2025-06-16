// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'circle_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VibeCircle _$VibeCircleFromJson(Map<String, dynamic> json) => VibeCircle(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isPublic: json['isPublic'] as bool,
      vibePreferences: (json['vibePreferences'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      category: $enumDecode(_$CircleCategoryEnumMap, json['category']),
      memberCount: (json['memberCount'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      requiresApproval: json['requiresApproval'] as bool? ?? false,
      allowMemberInvites: json['allowMemberInvites'] as bool? ?? true,
      showMemberVisits: json['showMemberVisits'] as bool? ?? true,
      inviteCode: json['inviteCode'] as String?,
      memberLimit: (json['memberLimit'] as num?)?.toInt(),
      settings: json['settings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$VibeCircleToJson(VibeCircle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'creatorId': instance.creatorId,
      'creatorName': instance.creatorName,
      'imageUrl': instance.imageUrl,
      'isPublic': instance.isPublic,
      'vibePreferences': instance.vibePreferences,
      'category': _$CircleCategoryEnumMap[instance.category]!,
      'memberCount': instance.memberCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActivityAt': instance.lastActivityAt.toIso8601String(),
      'requiresApproval': instance.requiresApproval,
      'allowMemberInvites': instance.allowMemberInvites,
      'showMemberVisits': instance.showMemberVisits,
      'inviteCode': instance.inviteCode,
      'memberLimit': instance.memberLimit,
      'settings': instance.settings,
    };

const _$CircleCategoryEnumMap = {
  CircleCategory.foodies: 'foodies',
  CircleCategory.nightlife: 'nightlife',
  CircleCategory.culture: 'culture',
  CircleCategory.adventure: 'adventure',
  CircleCategory.wellness: 'wellness',
  CircleCategory.shopping: 'shopping',
  CircleCategory.family: 'family',
  CircleCategory.business: 'business',
  CircleCategory.creative: 'creative',
  CircleCategory.other: 'other',
};

CircleMembership _$CircleMembershipFromJson(Map<String, dynamic> json) =>
    CircleMembership(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      circleId: json['circleId'] as String,
      role: $enumDecode(_$MemberRoleEnumMap, json['role']),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      contributionScore: (json['contributionScore'] as num?)?.toInt() ?? 0,
      checkInsShared: (json['checkInsShared'] as num?)?.toInt() ?? 0,
      boardsCreated: (json['boardsCreated'] as num?)?.toInt() ?? 0,
      reviewsWritten: (json['reviewsWritten'] as num?)?.toInt() ?? 0,
      lastActivityAt: json['lastActivityAt'] == null
          ? null
          : DateTime.parse(json['lastActivityAt'] as String),
    );

Map<String, dynamic> _$CircleMembershipToJson(CircleMembership instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userName': instance.userName,
      'userPhotoUrl': instance.userPhotoUrl,
      'circleId': instance.circleId,
      'role': _$MemberRoleEnumMap[instance.role]!,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'notificationsEnabled': instance.notificationsEnabled,
      'contributionScore': instance.contributionScore,
      'checkInsShared': instance.checkInsShared,
      'boardsCreated': instance.boardsCreated,
      'reviewsWritten': instance.reviewsWritten,
      'lastActivityAt': instance.lastActivityAt?.toIso8601String(),
    };

const _$MemberRoleEnumMap = {
  MemberRole.admin: 'admin',
  MemberRole.moderator: 'moderator',
  MemberRole.member: 'member',
};

CircleActivity _$CircleActivityFromJson(Map<String, dynamic> json) =>
    CircleActivity(
      id: json['id'] as String,
      circleId: json['circleId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => ActivityComment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CircleActivityToJson(CircleActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'circleId': instance.circleId,
      'userId': instance.userId,
      'userName': instance.userName,
      'userPhotoUrl': instance.userPhotoUrl,
      'type': _$ActivityTypeEnumMap[instance.type]!,
      'data': instance.data,
      'timestamp': instance.timestamp.toIso8601String(),
      'likedBy': instance.likedBy,
      'comments': instance.comments,
    };

const _$ActivityTypeEnumMap = {
  ActivityType.memberJoined: 'memberJoined',
  ActivityType.placeShared: 'placeShared',
  ActivityType.boardCreated: 'boardCreated',
  ActivityType.microReview: 'microReview',
  ActivityType.checkIn: 'checkIn',
  ActivityType.milestone: 'milestone',
};

ActivityComment _$ActivityCommentFromJson(Map<String, dynamic> json) =>
    ActivityComment(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ActivityCommentToJson(ActivityComment instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userName': instance.userName,
      'text': instance.text,
      'timestamp': instance.timestamp.toIso8601String(),
    };

VibeBoard _$VibeBoardFromJson(Map<String, dynamic> json) => VibeBoard(
      id: json['id'] as String,
      circleId: json['circleId'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      places: (json['places'] as List<dynamic>)
          .map((e) => BoardPlace.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      coverImageUrl: json['coverImageUrl'] as String?,
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      saveCount: (json['saveCount'] as num?)?.toInt() ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      savedBy: (json['savedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$VibeBoardToJson(VibeBoard instance) => <String, dynamic>{
      'id': instance.id,
      'circleId': instance.circleId,
      'creatorId': instance.creatorId,
      'creatorName': instance.creatorName,
      'title': instance.title,
      'description': instance.description,
      'places': instance.places,
      'tags': instance.tags,
      'coverImageUrl': instance.coverImageUrl,
      'likeCount': instance.likeCount,
      'saveCount': instance.saveCount,
      'likedBy': instance.likedBy,
      'savedBy': instance.savedBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

BoardPlace _$BoardPlaceFromJson(Map<String, dynamic> json) => BoardPlace(
      placeId: json['placeId'] as String,
      placeName: json['placeName'] as String,
      placeType: json['placeType'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      customNote: json['customNote'] as String?,
      vibes:
          (json['vibes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      imageUrl: json['imageUrl'] as String?,
      orderIndex: (json['orderIndex'] as num).toInt(),
    );

Map<String, dynamic> _$BoardPlaceToJson(BoardPlace instance) =>
    <String, dynamic>{
      'placeId': instance.placeId,
      'placeName': instance.placeName,
      'placeType': instance.placeType,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'customNote': instance.customNote,
      'vibes': instance.vibes,
      'imageUrl': instance.imageUrl,
      'orderIndex': instance.orderIndex,
    };

MicroReview _$MicroReviewFromJson(Map<String, dynamic> json) => MicroReview(
      id: json['id'] as String,
      placeId: json['placeId'] as String,
      placeName: json['placeName'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      circleId: json['circleId'] as String,
      quickTake: json['quickTake'] as String,
      vibes:
          (json['vibes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      quickRating: (json['quickRating'] as num?)?.toInt(),
      photoUrls: (json['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: (json['likedBy'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MicroReviewToJson(MicroReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'placeId': instance.placeId,
      'placeName': instance.placeName,
      'userId': instance.userId,
      'userName': instance.userName,
      'userPhotoUrl': instance.userPhotoUrl,
      'circleId': instance.circleId,
      'quickTake': instance.quickTake,
      'vibes': instance.vibes,
      'quickRating': instance.quickRating,
      'photoUrls': instance.photoUrls,
      'createdAt': instance.createdAt.toIso8601String(),
      'likeCount': instance.likeCount,
      'likedBy': instance.likedBy,
    };

CircleNotification _$CircleNotificationFromJson(Map<String, dynamic> json) =>
    CircleNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      circleId: json['circleId'] as String,
      circleName: json['circleName'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$CircleNotificationToJson(CircleNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'circleId': instance.circleId,
      'circleName': instance.circleName,
      'title': instance.title,
      'body': instance.body,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'data': instance.data,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.newMember: 'newMember',
  NotificationType.newCheckIn: 'newCheckIn',
  NotificationType.newBoard: 'newBoard',
  NotificationType.newReview: 'newReview',
  NotificationType.mention: 'mention',
  NotificationType.invite: 'invite',
  NotificationType.milestone: 'milestone',
};
