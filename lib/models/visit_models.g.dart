// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visit_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceVisit _$PlaceVisitFromJson(Map<String, dynamic> json) => PlaceVisit(
      id: json['id'] as String,
      userId: json['userId'] as String,
      placeId: json['placeId'] as String,
      placeName: json['placeName'] as String,
      placeType: json['placeType'] as String,
      placeCategory: json['placeCategory'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      visitTime: DateTime.parse(json['visitTime'] as String),
      isManualCheckIn: json['isManualCheckIn'] as bool,
      vibes:
          (json['vibes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      aiGeneratedVibe: json['aiGeneratedVibe'] as String?,
      userNote: json['userNote'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rating: (json['rating'] as num?)?.toInt(),
      address: json['address'] as String?,
      placeDetails: json['placeDetails'] as Map<String, dynamic>?,
      isVerified: json['isVerified'] as bool? ?? false,
      verificationDistance: (json['verificationDistance'] as num?)?.toDouble(),
      actualVisitTime: json['actualVisitTime'] == null
          ? null
          : DateTime.parse(json['actualVisitTime'] as String),
      hasDelayedCheckIn: json['hasDelayedCheckIn'] as bool? ?? false,
      hasVerifiedPhoto: json['hasVerifiedPhoto'] as bool? ?? false,
      photoCredibilityScore:
          (json['photoCredibilityScore'] as num?)?.toDouble(),
      photoAnalysis: json['photoAnalysis'] as String?,
      instantVibeTags: (json['instantVibeTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      storyCaption: json['storyCaption'] as String?,
      isStoryPublic: json['isStoryPublic'] as bool? ?? false,
      vibeCred: (json['vibeCred'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PlaceVisitToJson(PlaceVisit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'placeId': instance.placeId,
      'placeName': instance.placeName,
      'placeType': instance.placeType,
      'placeCategory': instance.placeCategory,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'visitTime': instance.visitTime.toIso8601String(),
      'isManualCheckIn': instance.isManualCheckIn,
      'vibes': instance.vibes,
      'aiGeneratedVibe': instance.aiGeneratedVibe,
      'userNote': instance.userNote,
      'photoUrls': instance.photoUrls,
      'rating': instance.rating,
      'address': instance.address,
      'placeDetails': instance.placeDetails,
      'isVerified': instance.isVerified,
      'verificationDistance': instance.verificationDistance,
      'actualVisitTime': instance.actualVisitTime?.toIso8601String(),
      'hasDelayedCheckIn': instance.hasDelayedCheckIn,
      'hasVerifiedPhoto': instance.hasVerifiedPhoto,
      'photoCredibilityScore': instance.photoCredibilityScore,
      'photoAnalysis': instance.photoAnalysis,
      'instantVibeTags': instance.instantVibeTags,
      'storyCaption': instance.storyCaption,
      'isStoryPublic': instance.isStoryPublic,
      'vibeCred': instance.vibeCred,
    };

UserVibeScore _$UserVibeScoreFromJson(Map<String, dynamic> json) =>
    UserVibeScore(
      userId: json['userId'] as String,
      totalCredPoints: (json['totalCredPoints'] as num).toInt(),
      verifiedCheckIns: (json['verifiedCheckIns'] as num).toInt(),
      photoUploads: (json['photoUploads'] as num).toInt(),
      communityLikes: (json['communityLikes'] as num).toInt(),
      badges:
          (json['badges'] as List<dynamic>).map((e) => e as String).toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      level: (json['level'] as num).toInt(),
      title: json['title'] as String,
    );

Map<String, dynamic> _$UserVibeScoreToJson(UserVibeScore instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'totalCredPoints': instance.totalCredPoints,
      'verifiedCheckIns': instance.verifiedCheckIns,
      'photoUploads': instance.photoUploads,
      'communityLikes': instance.communityLikes,
      'badges': instance.badges,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'level': instance.level,
      'title': instance.title,
    };
