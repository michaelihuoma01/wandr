import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart'; // This file will be generated

@JsonSerializable()
class PlaceDetails {
  final String? placeId;
  final String? dataSource;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String type;
  final List<String>? imageUrls;
  final double? rating;
  final String? priceLevel;
  final List<String>? reviewTexts;
  final List<String>? tags;
  final String? websiteUrl;
  final String? phoneNumber;
  final String? menuUrl;
  final List<SocialLink>? socialLinks;

  PlaceDetails({
    this.placeId,
    this.dataSource,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.imageUrls,
    this.rating,
    this.priceLevel,
    this.reviewTexts,
    this.tags,
    this.websiteUrl,
    this.phoneNumber,
    this.menuUrl,
    this.socialLinks,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) => _$PlaceDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$PlaceDetailsToJson(this);
}

@JsonSerializable()
class SocialLink {
  final String platform;
  final String url;

  SocialLink({required this.platform, required this.url});

  factory SocialLink.fromJson(Map<String, dynamic> json) => _$SocialLinkFromJson(json);
  Map<String, dynamic> toJson() => _$SocialLinkToJson(this);
}

@JsonSerializable()
class AnalyzeInputAndSuggestLocationsOutput {
  final List<PlaceDetails> locations;

  AnalyzeInputAndSuggestLocationsOutput({required this.locations});

  factory AnalyzeInputAndSuggestLocationsOutput.fromJson(Map<String, dynamic> json) => _$AnalyzeInputAndSuggestLocationsOutputFromJson(json);
  Map<String, dynamic> toJson() => _$AnalyzeInputAndSuggestLocationsOutputToJson(this);
}
