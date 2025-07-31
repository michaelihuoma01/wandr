import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../models/circle_models.dart';
import '../models/vibe_tag_models.dart';
import 'search_service.dart';
import 'vibe_tag_service.dart';
import 'auth_service.dart';

// ============================================================================
// UNIFIED SEARCH SERVICE - ONE SEARCH BAR FOR EVERYTHING
// ============================================================================

class UnifiedSearchService {
  final SearchService _searchService = SearchService();
  final VibeTagService _vibeTagService = VibeTagService();
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search intent detection
  static const Map<String, List<String>> _intentKeywords = {
    'vibe': ['vibe', 'mood', 'feeling', 'atmosphere', 'aesthetic', 'cozy', 'energetic', 'chill', 'social'],
    'circle': ['circle', 'group', 'community', 'friends', 'people', 'join'],
    'board': ['board', 'list', 'collection', 'saved', 'curated'],
    'user': ['user', 'person', 'friend', '@'],
    'place': ['place', 'restaurant', 'cafe', 'bar', 'food', 'near', 'location'],
  };

  // ============================================================================
  // UNIFIED SEARCH ENTRY POINT
  // ============================================================================

  /// One search method to rule them all - handles AI, vibe, entity searches
  Future<UnifiedSearchResult> unifiedSearch({
    String? query,
    String? imageUrl,
    required double latitude,
    required double longitude,
    required double radiusKm,
    List<String>? entityTypes, // ['place', 'circle', 'board', 'user']
    Map<String, dynamic>? filters,
    int page = 0,
    int limitPerType = 10,
  }) async {
    try {
      final isImageSearch = imageUrl != null && imageUrl.isNotEmpty;
      final isTextSearch = query != null && query.isNotEmpty;

      if (!isImageSearch && !isTextSearch) {
        return UnifiedSearchResult(
          success: false,
          error: 'Please provide either text or image for search',
        );
      }

      // Detect search intent and target entities
      final searchIntent = _detectSearchIntent(query);
      final targetEntities = entityTypes ?? _getTargetEntitiesFromIntent(searchIntent);

      final results = <String, List<dynamic>>{};
      final errors = <String>[];

      // Execute searches based on intent and entities
      for (final entityType in targetEntities) {
        try {
          switch (entityType) {
            case 'place':
              final placeResults = await _searchPlaces(
                query: query,
                imageUrl: imageUrl,
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm,
                page: page,
                limit: limitPerType,
              );
              results['places'] = placeResults;
              break;

            case 'circle':
              final circleResults = await _searchCircles(
                query: query,
                latitude: latitude,
                longitude: longitude,
                radiusKm: radiusKm,
                limit: limitPerType,
              );
              results['circles'] = circleResults;
              break;

            case 'board':
              final boardResults = await _searchBoards(
                query: query,
                limit: limitPerType,
              );
              results['boards'] = boardResults;
              break;

            case 'user':
              final userResults = await _searchUsers(
                query: query,
                latitude: latitude,
                longitude: longitude,
                limit: limitPerType,
              );
              results['users'] = userResults;
              break;
          }
        } catch (e) {
          errors.add('$entityType search failed: $e');
        }
      }

      // Save to history if successful
      if (results.isNotEmpty && isTextSearch) {
        final totalResults = results.values.fold(0, (sum, list) => sum + list.length);
        await _searchService.saveToHistory(
          query!,
          totalResults,
          latitude,
          longitude,
          isImageSearch: isImageSearch,
        );
      }

      return UnifiedSearchResult(
        success: true,
        searchIntent: searchIntent,
        results: results,
        totalResults: results.values.fold(0, (sum, list) => sum + list.length),
        errors: errors.isEmpty ? null : errors,
      );
    } catch (e) {
      return UnifiedSearchResult(
        success: false,
        error: 'Unified search failed: ${e.toString()}',
      );
    }
  }

  // ============================================================================
  // SEARCH INTENT DETECTION
  // ============================================================================

  SearchIntent _detectSearchIntent(String? query) {
    if (query == null || query.isEmpty) {
      return SearchIntent(type: 'general', confidence: 1.0, detectedVibes: []);
    }

    final lowerQuery = query.toLowerCase();
    final intentScores = <String, double>{};

    // Calculate intent scores based on keywords
    for (final intentEntry in _intentKeywords.entries) {
      final intent = intentEntry.key;
      final keywords = intentEntry.value;
      
      double score = 0.0;
      for (final keyword in keywords) {
        if (lowerQuery.contains(keyword)) {
          score += 1.0;
          // Boost score if keyword appears early in query
          if (lowerQuery.indexOf(keyword) < lowerQuery.length / 2) {
            score += 0.5;
          }
        }
      }
      
      if (score > 0) {
        intentScores[intent] = score / keywords.length;
      }
    }

    // Detect vibe-related keywords
    final detectedVibes = <String>[];
    final vibeKeywords = {
      'cozy': ['cozy', 'intimate', 'warm', 'comfortable'],
      'energetic': ['energetic', 'lively', 'vibrant', 'busy'],
      'aesthetic': ['aesthetic', 'beautiful', 'instagrammable', 'pretty'],
      'chill': ['chill', 'relaxed', 'calm', 'peaceful'],
      'social': ['social', 'friendly', 'meeting', 'groups'],
      'romantic': ['romantic', 'date', 'couples', 'intimate'],
      'adventurous': ['adventure', 'new', 'exciting', 'unique'],
      'luxurious': ['luxury', 'high-end', 'premium', 'expensive'],
    };

    for (final vibeEntry in vibeKeywords.entries) {
      final vibe = vibeEntry.key;
      final keywords = vibeEntry.value;
      
      for (final keyword in keywords) {
        if (lowerQuery.contains(keyword)) {
          detectedVibes.add(vibe);
          intentScores['vibe'] = (intentScores['vibe'] ?? 0) + 1.0;
          break;
        }
      }
    }

    // Determine primary intent
    String primaryIntent = 'general';
    double maxScore = 0.0;
    
    intentScores.forEach((intent, score) {
      if (score > maxScore) {
        maxScore = score;
        primaryIntent = intent;
      }
    });

    return SearchIntent(
      type: primaryIntent,
      confidence: maxScore,
      detectedVibes: detectedVibes,
      secondaryIntents: intentScores.keys.where((k) => k != primaryIntent).toList(),
    );
  }

  List<String> _getTargetEntitiesFromIntent(SearchIntent intent) {
    switch (intent.type) {
      case 'vibe':
        return ['place', 'circle', 'board']; // Vibe searches include all vibe-tagged entities
      case 'circle':
        return ['circle'];
      case 'board':
        return ['board'];
      case 'user':
        return ['user'];
      case 'place':
        return ['place'];
      default:
        return ['place', 'circle', 'board']; // General search excludes users
    }
  }

  // ============================================================================
  // ENTITY-SPECIFIC SEARCH METHODS
  // ============================================================================

  /// Search places using existing AI/NLP + vibe filtering
  Future<List<PlaceDetails>> _searchPlaces({
    String? query,
    String? imageUrl,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int page = 0,
    int limit = 10,
  }) async {
    // Use existing AI-powered search
    final searchResult = await _searchService.searchPlaces(
      query: query,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      page: page,
    );

    if (!searchResult.success) {
      throw Exception(searchResult.error ?? 'Place search failed');
    }

    List<PlaceDetails> places = searchResult.locations;

    // Apply vibe filtering if vibes were detected
    if (query != null) {
      final intent = _detectSearchIntent(query);
      if (intent.detectedVibes.isNotEmpty) {
        places = await _filterPlacesByVibes(places, intent.detectedVibes);
      }
    }

    return places.take(limit).toList();
  }

  /// Search circles by name, description, or vibe compatibility
  Future<List<Map<String, dynamic>>> _searchCircles({
    String? query,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 10,
  }) async {
    try {
      Query<Map<String, dynamic>> circleQuery = _firestore.collection('circles');

      // Text search in name and description
      if (query != null && query.isNotEmpty) {
        final searchTerms = query.toLowerCase().split(' ');
        
        // Use array-contains for basic text search (Firestore limitation)
        // In production, you'd use Algolia or Elasticsearch for better text search
        circleQuery = circleQuery.where('isPrivate', isEqualTo: false);
      } else {
        circleQuery = circleQuery.where('isPrivate', isEqualTo: false);
      }

      circleQuery = circleQuery.orderBy('memberCount', descending: true).limit(limit * 2);

      final snapshot = await circleQuery.get();
      final circles = snapshot.docs.map((doc) => {
        'circle': VibeCircle.fromJson({'id': doc.id, ...doc.data()}),
        'distance': _calculateDistance(
          latitude,
          longitude,
          (doc.data()['latitude'] as num?)?.toDouble() ?? latitude,
          (doc.data()['longitude'] as num?)?.toDouble() ?? longitude,
        ),
      }).toList();

      // Filter by search query if provided
      List<Map<String, dynamic>> filteredCircles = circles;
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        filteredCircles = circles.where((item) {
          final circle = item['circle'] as VibeCircle;
          return circle.name.toLowerCase().contains(lowerQuery) ||
                 circle.description.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      // Sort by distance and member count
      filteredCircles.sort((a, b) {
        final circleA = a['circle'] as VibeCircle;
        final circleB = b['circle'] as VibeCircle;
        
        // Primary sort: distance (closer is better)
        final distanceComparison = (a['distance'] as double).compareTo(b['distance'] as double);
        if (distanceComparison != 0) return distanceComparison;
        
        // Secondary sort: member count (more members is better)
        return circleB.memberCount.compareTo(circleA.memberCount);
      });

      return filteredCircles.take(limit).toList();
    } catch (e) {
      print('Error searching circles: $e');
      return [];
    }
  }

  /// Search boards by name, description, or vibe tags
  Future<List<Map<String, dynamic>>> _searchBoards({
    String? query,
    int limit = 10,
  }) async {
    try {
      Query<Map<String, dynamic>> boardQuery = _firestore
          .collection('boards')
          .where('isPublic', isEqualTo: true)
          .orderBy('followerCount', descending: true)
          .limit(limit * 2);

      final snapshot = await boardQuery.get();
      final boards = snapshot.docs.map((doc) => Board.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();

      // Filter by search query if provided
      List<Board> filteredBoards = boards;
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        filteredBoards = boards.where((board) {
          return board.name.toLowerCase().contains(lowerQuery) ||
                 board.description.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      // Get vibe associations for each board
      final boardResults = <Map<String, dynamic>>[];
      for (final board in filteredBoards.take(limit)) {
        final vibeAssociations = await _vibeTagService.getEntityVibeAssociations(board.id, 'board');
        boardResults.add({
          'board': board,
          'vibes': vibeAssociations.map((v) => v.vibeTagId).toList(),
        });
      }

      return boardResults;
    } catch (e) {
      print('Error searching boards: $e');
      return [];
    }
  }

  /// Search users by name or vibe compatibility
  Future<List<Map<String, dynamic>>> _searchUsers({
    String? query,
    required double latitude,
    required double longitude,
    int limit = 10,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return [];

      Query<Map<String, dynamic>> userQuery = _firestore.collection('users');

      // Basic query setup
      userQuery = userQuery.limit(limit * 2);

      final snapshot = await userQuery.get();
      final users = snapshot.docs
          .where((doc) => doc.id != currentUser.uid) // Exclude current user
          .map((doc) => EnhancedUser.fromJson({
            'id': doc.id,
            ...doc.data(),
          }))
          .toList();

      // Filter by search query if provided
      List<EnhancedUser> filteredUsers = users;
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        filteredUsers = users.where((user) {
          return user.name.toLowerCase().contains(lowerQuery) ||
                 (user.bio?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }

      // Calculate vibe compatibility for each user
      final userResults = <Map<String, dynamic>>[];
      for (final user in filteredUsers.take(limit)) {
        final compatibility = await _vibeTagService.calculateVibeCompatibility(
          entityId1: currentUser.uid,
          entityType1: 'user',
          entityId2: user.id,
          entityType2: 'user',
        );

        userResults.add({
          'user': user,
          'compatibility': compatibility,
        });
      }

      // Sort by compatibility score
      userResults.sort((a, b) {
        final scoreA = (a['compatibility'] as VibeCompatibilityScore).overallScore;
        final scoreB = (b['compatibility'] as VibeCompatibilityScore).overallScore;
        return scoreB.compareTo(scoreA);
      });

      return userResults;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // ============================================================================
  // VIBE-BASED FILTERING
  // ============================================================================

  /// Filter places by detected vibe tags
  Future<List<PlaceDetails>> _filterPlacesByVibes(List<PlaceDetails> places, List<String> vibeTagIds) async {
    final filteredPlaces = <PlaceDetails>[];

    for (final place in places) {
      // Get vibe associations for this place
      final vibeAssociations = await _vibeTagService.getEntityVibeAssociations(place.placeId!, 'place');
      
      // Check if place has any of the detected vibes
      final placeVibes = vibeAssociations.map((v) => v.vibeTagId).toSet();
      final hasMatchingVibe = vibeTagIds.any((vibe) => placeVibes.contains(vibe));
      
      if (hasMatchingVibe || vibeAssociations.isEmpty) {
        // Include if it has matching vibes OR if it has no vibe tags yet (new places)
        filteredPlaces.add(place);
      }
    }

    return filteredPlaces;
  }

  // ============================================================================
  // SUGGESTION & AUTOCOMPLETE
  // ============================================================================

  /// Get search suggestions based on partial query
  Future<List<SearchSuggestion>> getSearchSuggestions(String partialQuery) async {
    final suggestions = <SearchSuggestion>[];
    final lowerQuery = partialQuery.toLowerCase();

    if (partialQuery.length < 2) return suggestions;

    try {
      // Vibe tag suggestions
      final vibeTags = await _vibeTagService.getAllVibeTags();
      for (final tag in vibeTags) {
        if (tag.displayName.toLowerCase().contains(lowerQuery) ||
            tag.synonyms.any((s) => s.toLowerCase().contains(lowerQuery))) {
          suggestions.add(SearchSuggestion(
            text: '${tag.displayName} vibes',
            type: 'vibe',
            icon: tag.icon,
            subtitle: tag.description,
          ));
        }
      }

      // Popular search terms
      final popularSearches = [
        'coffee shops near me',
        'aesthetic cafes',
        'cozy restaurants',
        'rooftop bars',
        'brunch spots',
        'date night restaurants',
      ];

      for (final search in popularSearches) {
        if (search.toLowerCase().contains(lowerQuery)) {
          suggestions.add(SearchSuggestion(
            text: search,
            type: 'popular',
            icon: 'search',
            subtitle: 'Popular search',
          ));
        }
      }

      // Limit to 8 suggestions
      return suggestions.take(8).toList();
    } catch (e) {
      print('Error getting search suggestions: $e');
      return suggestions;
    }
  }

  // ============================================================================
  // UTILITIES
  // ============================================================================

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);
}

// ============================================================================
// UNIFIED SEARCH MODELS
// ============================================================================

class UnifiedSearchResult {
  final bool success;
  final SearchIntent? searchIntent;
  final Map<String, List<dynamic>> results;
  final int totalResults;
  final List<String>? errors;
  final String? error;

  UnifiedSearchResult({
    required this.success,
    this.searchIntent,
    this.results = const {},
    this.totalResults = 0,
    this.errors,
    this.error,
  });
}

class SearchIntent {
  final String type; // 'general', 'vibe', 'circle', 'board', 'user', 'place'
  final double confidence; // 0.0 - 1.0
  final List<String> detectedVibes;
  final List<String> secondaryIntents;

  SearchIntent({
    required this.type,
    required this.confidence,
    required this.detectedVibes,
    this.secondaryIntents = const [],
  });
}

class SearchSuggestion {
  final String text;
  final String type; // 'vibe', 'popular', 'recent'
  final String icon;
  final String? subtitle;

  SearchSuggestion({
    required this.text,
    required this.type,
    required this.icon,
    this.subtitle,
  });
}