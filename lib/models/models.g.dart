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

VibeList _$VibeListFromJson(Map<String, dynamic> json) => VibeList(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      places: (json['places'] as List<dynamic>)
          .map((e) => PlaceDetails.fromJson(e as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      vibeType: json['vibeType'] as String,
      estimatedDuration: (json['estimatedDuration'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
      isShared: json['isShared'] as bool? ?? false,
      sharedWithCircles: (json['sharedWithCircles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isMultiStop: json['isMultiStop'] as bool? ?? false,
      itineraryStops: (json['itineraryStops'] as List<dynamic>?)
          ?.map((e) => ItineraryStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      enhancedCategories: (json['enhancedCategories'] as List<dynamic>?)
          ?.map((e) =>
              EnhancedItineraryCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupType: json['groupType'] as String?,
      specialOccasion: json['specialOccasion'] as String?,
    );

Map<String, dynamic> _$VibeListToJson(VibeList instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'places': instance.places,
      'tags': instance.tags,
      'vibeType': instance.vibeType,
      'estimatedDuration': instance.estimatedDuration,
      'createdAt': instance.createdAt.toIso8601String(),
      'createdBy': instance.createdBy,
      'isShared': instance.isShared,
      'sharedWithCircles': instance.sharedWithCircles,
      'isMultiStop': instance.isMultiStop,
      'itineraryStops': instance.itineraryStops,
      'enhancedCategories': instance.enhancedCategories,
      'groupType': instance.groupType,
      'specialOccasion': instance.specialOccasion,
    };

VibePreferences _$VibePreferencesFromJson(Map<String, dynamic> json) =>
    VibePreferences(
      preferredVibes: (json['preferredVibes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      preferredPlaceTypes: (json['preferredPlaceTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      maxDistance: (json['maxDistance'] as num?)?.toInt(),
      maxDuration: (json['maxDuration'] as num?)?.toInt(),
      priceLevel: json['priceLevel'] as String?,
      minRating: (json['minRating'] as num?)?.toDouble(),
      dietaryRestrictions: (json['dietaryRestrictions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      accessibility: (json['accessibility'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      groupType: json['groupType'] as String?,
      spotType: json['spotType'] as String?,
      specialOccasion: json['specialOccasion'] as String?,
      multiSpotCategories: (json['multiSpotCategories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$VibePreferencesToJson(VibePreferences instance) =>
    <String, dynamic>{
      'preferredVibes': instance.preferredVibes,
      'preferredPlaceTypes': instance.preferredPlaceTypes,
      'maxDistance': instance.maxDistance,
      'maxDuration': instance.maxDuration,
      'priceLevel': instance.priceLevel,
      'minRating': instance.minRating,
      'dietaryRestrictions': instance.dietaryRestrictions,
      'accessibility': instance.accessibility,
      'groupType': instance.groupType,
      'spotType': instance.spotType,
      'specialOccasion': instance.specialOccasion,
      'multiSpotCategories': instance.multiSpotCategories,
    };

VibeQuizResponse _$VibeQuizResponseFromJson(Map<String, dynamic> json) =>
    VibeQuizResponse(
      answers: Map<String, String>.from(json['answers'] as Map),
      generatedPreferences: VibePreferences.fromJson(
          json['generatedPreferences'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VibeQuizResponseToJson(VibeQuizResponse instance) =>
    <String, dynamic>{
      'answers': instance.answers,
      'generatedPreferences': instance.generatedPreferences,
    };

ItineraryStop _$ItineraryStopFromJson(Map<String, dynamic> json) =>
    ItineraryStop(
      place: PlaceDetails.fromJson(json['place'] as Map<String, dynamic>),
      timeSlot: json['timeSlot'] as String,
      category: json['category'] as String,
      order: (json['order'] as num).toInt(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ItineraryStopToJson(ItineraryStop instance) =>
    <String, dynamic>{
      'place': instance.place,
      'timeSlot': instance.timeSlot,
      'category': instance.category,
      'order': instance.order,
      'description': instance.description,
    };

EnhancedItineraryCategory _$EnhancedItineraryCategoryFromJson(
        Map<String, dynamic> json) =>
    EnhancedItineraryCategory(
      categoryTitle: json['categoryTitle'] as String,
      categoryDescription: json['categoryDescription'] as String,
      timeSlot: json['timeSlot'] as String,
      places: (json['places'] as List<dynamic>)
          .map((e) => PlaceDetails.fromJson(e as Map<String, dynamic>))
          .toList(),
      order: (json['order'] as num).toInt(),
    );

Map<String, dynamic> _$EnhancedItineraryCategoryToJson(
        EnhancedItineraryCategory instance) =>
    <String, dynamic>{
      'categoryTitle': instance.categoryTitle,
      'categoryDescription': instance.categoryDescription,
      'timeSlot': instance.timeSlot,
      'places': instance.places,
      'order': instance.order,
    };

Board _$BoardFromJson(Map<String, dynamic> json) => Board(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      coverPhotoUrl: json['coverPhotoUrl'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPublic: json['isPublic'] as bool? ?? false,
      type: $enumDecodeNullable(_$BoardTypeEnumMap, json['type']) ??
          BoardType.normal,
      places: (json['places'] as List<dynamic>?)
              ?.map((e) => PlaceDetails.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      itineraryStops: (json['itineraryStops'] as List<dynamic>?)
          ?.map((e) => ItineraryStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      groupType: json['groupType'] as String?,
      specialOccasion: json['specialOccasion'] as String?,
    );

Map<String, dynamic> _$BoardToJson(Board instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'coverPhotoUrl': instance.coverPhotoUrl,
      'tags': instance.tags,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'isPublic': instance.isPublic,
      'type': _$BoardTypeEnumMap[instance.type]!,
      'places': instance.places,
      'itineraryStops': instance.itineraryStops,
      'groupType': instance.groupType,
      'specialOccasion': instance.specialOccasion,
    };

const _$BoardTypeEnumMap = {
  BoardType.normal: 'normal',
  BoardType.itinerary: 'itinerary',
};

EditableItineraryStop _$EditableItineraryStopFromJson(
        Map<String, dynamic> json) =>
    EditableItineraryStop(
      id: json['id'] as String,
      place: PlaceDetails.fromJson(json['place'] as Map<String, dynamic>),
      timeSlot: json['timeSlot'] as String,
      category: json['category'] as String,
      order: (json['order'] as num).toInt(),
      description: json['description'] as String?,
      isCustomCategory: json['isCustomCategory'] as bool? ?? false,
    );

Map<String, dynamic> _$EditableItineraryStopToJson(
        EditableItineraryStop instance) =>
    <String, dynamic>{
      'id': instance.id,
      'place': instance.place,
      'timeSlot': instance.timeSlot,
      'category': instance.category,
      'order': instance.order,
      'description': instance.description,
      'isCustomCategory': instance.isCustomCategory,
    };

VibeScore _$VibeScoreFromJson(Map<String, dynamic> json) => VibeScore(
      vibeId: json['vibeId'] as String,
      score: (json['score'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      interactionCount: (json['interactionCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VibeScoreToJson(VibeScore instance) => <String, dynamic>{
      'vibeId': instance.vibeId,
      'score': instance.score,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'interactionCount': instance.interactionCount,
    };

VibeEvolutionDataPoint _$VibeEvolutionDataPointFromJson(
        Map<String, dynamic> json) =>
    VibeEvolutionDataPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      vibeScores: (json['vibeScores'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      context: json['context'] as String,
    );

Map<String, dynamic> _$VibeEvolutionDataPointToJson(
        VibeEvolutionDataPoint instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'vibeScores': instance.vibeScores,
      'context': instance.context,
    };

ContextualVibes _$ContextualVibesFromJson(Map<String, dynamic> json) =>
    ContextualVibes(
      contextVibeMap: (json['contextVibeMap'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$ContextualVibesToJson(ContextualVibes instance) =>
    <String, dynamic>{
      'contextVibeMap': instance.contextVibeMap,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

TasteSignature _$TasteSignatureFromJson(Map<String, dynamic> json) =>
    TasteSignature(
      venuePreferences: (json['venuePreferences'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      priceRangeAffinity:
          (json['priceRangeAffinity'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      socialPreference: (json['socialPreference'] as num).toDouble(),
      discoveryQuotient: (json['discoveryQuotient'] as num).toDouble(),
      timePatterns: (json['timePatterns'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      lastCalculated: DateTime.parse(json['lastCalculated'] as String),
    );

Map<String, dynamic> _$TasteSignatureToJson(TasteSignature instance) =>
    <String, dynamic>{
      'venuePreferences': instance.venuePreferences,
      'priceRangeAffinity': instance.priceRangeAffinity,
      'socialPreference': instance.socialPreference,
      'discoveryQuotient': instance.discoveryQuotient,
      'timePatterns': instance.timePatterns,
      'lastCalculated': instance.lastCalculated.toIso8601String(),
    };

BehavioralSignals _$BehavioralSignalsFromJson(Map<String, dynamic> json) =>
    BehavioralSignals(
      vibeConsistencyScore: (json['vibeConsistencyScore'] as num).toDouble(),
      explorationRadius: (json['explorationRadius'] as num).toDouble(),
      influenceScore: (json['influenceScore'] as num).toDouble(),
      activityPatterns: Map<String, int>.from(json['activityPatterns'] as Map),
      lastCalculated: DateTime.parse(json['lastCalculated'] as String),
    );

Map<String, dynamic> _$BehavioralSignalsToJson(BehavioralSignals instance) =>
    <String, dynamic>{
      'vibeConsistencyScore': instance.vibeConsistencyScore,
      'explorationRadius': instance.explorationRadius,
      'influenceScore': instance.influenceScore,
      'activityPatterns': instance.activityPatterns,
      'lastCalculated': instance.lastCalculated.toIso8601String(),
    };

VibeProfile _$VibeProfileFromJson(Map<String, dynamic> json) => VibeProfile(
      primaryVibes: (json['primaryVibes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      vibeScores: (json['vibeScores'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, VibeScore.fromJson(e as Map<String, dynamic>)),
      ),
      vibeEvolution: (json['vibeEvolution'] as List<dynamic>)
          .map(
              (e) => VibeEvolutionDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      contextualVibes: ContextualVibes.fromJson(
          json['contextualVibes'] as Map<String, dynamic>),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$VibeProfileToJson(VibeProfile instance) =>
    <String, dynamic>{
      'primaryVibes': instance.primaryVibes,
      'vibeScores': instance.vibeScores,
      'vibeEvolution': instance.vibeEvolution,
      'contextualVibes': instance.contextualVibes,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

OnboardingData _$OnboardingDataFromJson(Map<String, dynamic> json) =>
    OnboardingData(
      completedSteps: (json['completedSteps'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      quizResponses: json['quizResponses'] as Map<String, dynamic>,
      initialMatches: (json['initialMatches'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      onboardingVersion: json['onboardingVersion'] as String,
      completionTimestamp: json['completionTimestamp'] == null
          ? null
          : DateTime.parse(json['completionTimestamp'] as String),
      engagementScore: (json['engagementScore'] as num).toDouble(),
    );

Map<String, dynamic> _$OnboardingDataToJson(OnboardingData instance) =>
    <String, dynamic>{
      'completedSteps': instance.completedSteps,
      'quizResponses': instance.quizResponses,
      'initialMatches': instance.initialMatches,
      'onboardingVersion': instance.onboardingVersion,
      'completionTimestamp': instance.completionTimestamp?.toIso8601String(),
      'engagementScore': instance.engagementScore,
    };

PrivacySettings _$PrivacySettingsFromJson(Map<String, dynamic> json) =>
    PrivacySettings(
      vibeVisibility: json['vibeVisibility'] as bool? ?? true,
      locationSharing: json['locationSharing'] as bool? ?? true,
      activityPrivacyLevel:
          json['activityPrivacyLevel'] as String? ?? 'circles',
      allowVibeMatching: json['allowVibeMatching'] as bool? ?? true,
      showBehavioralInsights: json['showBehavioralInsights'] as bool? ?? false,
    );

Map<String, dynamic> _$PrivacySettingsToJson(PrivacySettings instance) =>
    <String, dynamic>{
      'vibeVisibility': instance.vibeVisibility,
      'locationSharing': instance.locationSharing,
      'activityPrivacyLevel': instance.activityPrivacyLevel,
      'allowVibeMatching': instance.allowVibeMatching,
      'showBehavioralInsights': instance.showBehavioralInsights,
    };

NotificationPreferences _$NotificationPreferencesFromJson(
        Map<String, dynamic> json) =>
    NotificationPreferences(
      boardUpdateAlerts: json['boardUpdateAlerts'] as bool? ?? true,
      circleActivityNotifications:
          json['circleActivityNotifications'] as bool? ?? true,
      vibeMatchAlerts: json['vibeMatchAlerts'] as bool? ?? true,
      discoveryRecommendations:
          json['discoveryRecommendations'] as bool? ?? true,
      weeklyInsights: json['weeklyInsights'] as bool? ?? true,
      mutedCircles: (json['mutedCircles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$NotificationPreferencesToJson(
        NotificationPreferences instance) =>
    <String, dynamic>{
      'boardUpdateAlerts': instance.boardUpdateAlerts,
      'circleActivityNotifications': instance.circleActivityNotifications,
      'vibeMatchAlerts': instance.vibeMatchAlerts,
      'discoveryRecommendations': instance.discoveryRecommendations,
      'weeklyInsights': instance.weeklyInsights,
      'mutedCircles': instance.mutedCircles,
    };

EnhancedUser _$EnhancedUserFromJson(Map<String, dynamic> json) => EnhancedUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: DateTime.parse(json['lastLogin'] as String),
      vibeProfile:
          VibeProfile.fromJson(json['vibeProfile'] as Map<String, dynamic>),
      tasteSignature: TasteSignature.fromJson(
          json['tasteSignature'] as Map<String, dynamic>),
      behavioralSignals: BehavioralSignals.fromJson(
          json['behavioralSignals'] as Map<String, dynamic>),
      onboardingData: OnboardingData.fromJson(
          json['onboardingData'] as Map<String, dynamic>),
      privacySettings: PrivacySettings.fromJson(
          json['privacySettings'] as Map<String, dynamic>),
      notificationPreferences: NotificationPreferences.fromJson(
          json['notificationPreferences'] as Map<String, dynamic>),
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      vibeTitle: json['vibeTitle'] as String?,
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 0,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      profileLastUpdated: DateTime.parse(json['profileLastUpdated'] as String),
      appVersion: json['appVersion'] as String,
    );

Map<String, dynamic> _$EnhancedUserToJson(EnhancedUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastLogin': instance.lastLogin.toIso8601String(),
      'vibeProfile': instance.vibeProfile,
      'tasteSignature': instance.tasteSignature,
      'behavioralSignals': instance.behavioralSignals,
      'onboardingData': instance.onboardingData,
      'privacySettings': instance.privacySettings,
      'notificationPreferences': instance.notificationPreferences,
      'bio': instance.bio,
      'location': instance.location,
      'interests': instance.interests,
      'vibeTitle': instance.vibeTitle,
      'trustScore': instance.trustScore,
      'achievements': instance.achievements,
      'profileLastUpdated': instance.profileLastUpdated.toIso8601String(),
      'appVersion': instance.appVersion,
    };
