// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vibe_tag_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VibeTag _$VibeTagFromJson(Map<String, dynamic> json) => VibeTag(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      synonyms: (json['synonyms'] as List<dynamic>).map((e) => e as String).toList(),
      color: json['color'] as String,
      icon: json['icon'] as String,
      popularity: (json['popularity'] as num).toDouble(),
      contextWeights: Map<String, double>.from(json['contextWeights'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
      usageCount: json['usageCount'] as int,
    );

Map<String, dynamic> _$VibeTagToJson(VibeTag instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'displayName': instance.displayName,
      'description': instance.description,
      'category': instance.category,
      'synonyms': instance.synonyms,
      'color': instance.color,
      'icon': instance.icon,
      'popularity': instance.popularity,
      'contextWeights': instance.contextWeights,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUsed': instance.lastUsed.toIso8601String(),
      'usageCount': instance.usageCount,
    };

VibeTagAssociation _$VibeTagAssociationFromJson(Map<String, dynamic> json) =>
    VibeTagAssociation(
      entityId: json['entityId'] as String,
      entityType: json['entityType'] as String,
      vibeTagId: json['vibeTagId'] as String,
      strength: (json['strength'] as num).toDouble(),
      source: json['source'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$VibeTagAssociationToJson(VibeTagAssociation instance) =>
    <String, dynamic>{
      'entityId': instance.entityId,
      'entityType': instance.entityType,
      'vibeTagId': instance.vibeTagId,
      'strength': instance.strength,
      'source': instance.source,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'metadata': instance.metadata,
    };

VibeCompatibilityScore _$VibeCompatibilityScoreFromJson(
        Map<String, dynamic> json) =>
    VibeCompatibilityScore(
      entityId1: json['entityId1'] as String,
      entityType1: json['entityType1'] as String,
      entityId2: json['entityId2'] as String,
      entityType2: json['entityType2'] as String,
      overallScore: (json['overallScore'] as num).toDouble(),
      tagScores: Map<String, double>.from(json['tagScores'] as Map),
      sharedVibes: (json['sharedVibes'] as List<dynamic>).map((e) => e as String).toList(),
      complementaryVibes: (json['complementaryVibes'] as List<dynamic>).map((e) => e as String).toList(),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
    );

Map<String, dynamic> _$VibeCompatibilityScoreToJson(
        VibeCompatibilityScore instance) =>
    <String, dynamic>{
      'entityId1': instance.entityId1,
      'entityType1': instance.entityType1,
      'entityId2': instance.entityId2,
      'entityType2': instance.entityType2,
      'overallScore': instance.overallScore,
      'tagScores': instance.tagScores,
      'sharedVibes': instance.sharedVibes,
      'complementaryVibes': instance.complementaryVibes,
      'calculatedAt': instance.calculatedAt.toIso8601String(),
    };

VibeCategory _$VibeCategoryFromJson(Map<String, dynamic> json) => VibeCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
      sortOrder: json['sortOrder'] as int,
      vibeTagIds: (json['vibeTagIds'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$VibeCategoryToJson(VibeCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'displayName': instance.displayName,
      'description': instance.description,
      'color': instance.color,
      'icon': instance.icon,
      'sortOrder': instance.sortOrder,
      'vibeTagIds': instance.vibeTagIds,
    };