// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceDetails _$PlaceDetailsFromJson(Map<String, dynamic> json) => PlaceDetails(
      placeId: json['placeId'] as String?,
      dataSource: json['dataSource'] as String?,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: json['type'] as String,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      rating: (json['rating'] as num?)?.toDouble(),
      priceLevel: json['priceLevel'] as String?,
      reviewTexts: (json['reviewTexts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      websiteUrl: json['websiteUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      menuUrl: json['menuUrl'] as String?,
      socialLinks: (json['socialLinks'] as List<dynamic>?)
          ?.map((e) => SocialLink.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlaceDetailsToJson(PlaceDetails instance) =>
    <String, dynamic>{
      'placeId': instance.placeId,
      'dataSource': instance.dataSource,
      'name': instance.name,
      'description': instance.description,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'type': instance.type,
      'imageUrls': instance.imageUrls,
      'rating': instance.rating,
      'priceLevel': instance.priceLevel,
      'reviewTexts': instance.reviewTexts,
      'tags': instance.tags,
      'websiteUrl': instance.websiteUrl,
      'phoneNumber': instance.phoneNumber,
      'menuUrl': instance.menuUrl,
      'socialLinks': instance.socialLinks,
    };

SocialLink _$SocialLinkFromJson(Map<String, dynamic> json) => SocialLink(
      platform: json['platform'] as String,
      url: json['url'] as String,
    );

Map<String, dynamic> _$SocialLinkToJson(SocialLink instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'url': instance.url,
    };

AnalyzeInputAndSuggestLocationsOutput
    _$AnalyzeInputAndSuggestLocationsOutputFromJson(
            Map<String, dynamic> json) =>
        AnalyzeInputAndSuggestLocationsOutput(
          locations: (json['locations'] as List<dynamic>)
              .map((e) => PlaceDetails.fromJson(e as Map<String, dynamic>))
              .toList(),
        );

Map<String, dynamic> _$AnalyzeInputAndSuggestLocationsOutputToJson(
        AnalyzeInputAndSuggestLocationsOutput instance) =>
    <String, dynamic>{
      'locations': instance.locations,
    };
