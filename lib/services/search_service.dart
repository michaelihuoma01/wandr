// lib/services/search_service.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class SearchService {
  static const String _cloudFunctionUrl = 'https://searchplaces-sk572tzuuq-uc.a.run.app';
  static const String _photoProxyUrl = 'https://proxyplacephoto-sk572tzuuq-uc.a.run.app';
  
  static const int _resultsPerPage = 10;
  
  // Cache for search results
  final Map<String, SearchCache> _searchCache = {};
  
  // Search with pagination support
  Future<SearchResult> searchPlaces({
    required String query,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int page = 0,
  }) async {
    try {
      // Check cache first
      final cacheKey = '$query-$latitude-$longitude-$radiusKm';
      if (_searchCache.containsKey(cacheKey) && page == 0) {
        final cached = _searchCache[cacheKey]!;
        if (DateTime.now().difference(cached.timestamp).inMinutes < 5) {
          return SearchResult(
            success: true,
            locations: cached.locations.take(_resultsPerPage).toList(),
            totalResults: cached.locations.length,
            hasMore: cached.locations.length > _resultsPerPage,
          );
        }
      }

      // Make API call
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'textInput': query,
          'inputType': 'text',
          'latitude': latitude,
          'longitude': longitude,
          'searchRadius': radiusKm * 1000, // Convert to meters
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final output = AnalyzeInputAndSuggestLocationsOutput.fromJson(jsonResponse);
        
        // Sort by distance
        final sortedLocations = output.locations..sort((a, b) {
          final distA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
          final distB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });

        // Cache results
        _searchCache[cacheKey] = SearchCache(
          locations: sortedLocations,
          timestamp: DateTime.now(),
        );

        // Return paginated results
        final startIndex = page * _resultsPerPage;
        final endIndex = startIndex + _resultsPerPage;
        final paginatedResults = sortedLocations.sublist(
          startIndex,
          endIndex > sortedLocations.length ? sortedLocations.length : endIndex,
        );

        return SearchResult(
          success: true,
          locations: paginatedResults,
          totalResults: sortedLocations.length,
          hasMore: endIndex < sortedLocations.length,
        );
      } else {
        final errorBody = jsonDecode(response.body);
        return SearchResult(
          success: false,
          error: errorBody['error'] ?? 'Unknown error occurred',
        );
      }
    } catch (e) {
      return SearchResult(
        success: false,
        error: 'Search failed: ${e.toString()}',
      );
    }
  }

  // Process image URLs for proxy
  String processImageUrl(String? imageUrl) {
    if (imageUrl == null) return '';
    
    // If it's a Google Places photo URL with a photo reference
    if (imageUrl.contains('photoreference=')) {
      final uri = Uri.parse(imageUrl);
      final photoReference = uri.queryParameters['photoreference'];
      if (photoReference != null) {
        return '$_photoProxyUrl?photoReference=$photoReference&maxWidth=800';
      }
    }
    
    return imageUrl;
  }

  // Load more results
  Future<SearchResult> loadMoreResults(String query, double latitude, double longitude, double radiusKm, int currentPage) async {
    return searchPlaces(
      query: query,
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      page: currentPage + 1,
    );
  }

  // Search history management
  Future<List<SearchHistory>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('search_history') ?? [];
    return historyJson
        .map((json) => SearchHistory.fromJson(jsonDecode(json)))
        .toList()
        .reversed
        .take(10)
        .toList();
  }

  Future<void> saveToHistory(String query, int resultCount, double latitude, double longitude) async {
    final prefs = await SharedPreferences.getInstance();
    final history = SearchHistory(
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
      latitude: latitude,
      longitude: longitude,
    );
    
    final historyJson = prefs.getStringList('search_history') ?? [];
    historyJson.add(jsonEncode(history.toJson()));
    
    // Keep only last 50 searches
    if (historyJson.length > 50) {
      historyJson.removeRange(0, historyJson.length - 50);
    }
    
    await prefs.setStringList('search_history', historyJson);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
  }

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

// Cache class
class SearchCache {
  final List<PlaceDetails> locations;
  final DateTime timestamp;

  SearchCache({required this.locations, required this.timestamp});
}

// Result class
class SearchResult {
  final bool success;
  final List<PlaceDetails> locations;
  final int totalResults;
  final bool hasMore;
  final String? error;

  SearchResult({
    required this.success,
    this.locations = const [],
    this.totalResults = 0,
    this.hasMore = false,
    this.error,
  });
}

// Add to models.dart or keep here
class SearchHistory {
  final String query;
  final DateTime timestamp;
  final int resultCount;
  final double latitude;
  final double longitude;

  SearchHistory({
    required this.query,
    required this.timestamp,
    required this.resultCount,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() => {
    'query': query,
    'timestamp': timestamp.toIso8601String(),
    'resultCount': resultCount,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory SearchHistory.fromJson(Map<String, dynamic> json) => SearchHistory(
    query: json['query'],
    timestamp: DateTime.parse(json['timestamp']),
    resultCount: json['resultCount'],
    latitude: json['latitude'],
    longitude: json['longitude'],
  );
}