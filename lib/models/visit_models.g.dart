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
    };
