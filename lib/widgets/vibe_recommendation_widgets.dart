import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../models/circle_models.dart';
import '../models/vibe_tag_models.dart';
import '../services/unified_search_service.dart';
import '../services/vibe_tag_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../screens/discovery/visual_discovery_screen.dart';
import '../screens/circles/circle_detail_screen.dart';
import '../screens/enhanced_profile_screen.dart';

// ============================================================================
// PERSONALIZED PLACE RECOMMENDATIONS
// ============================================================================

class PersonalizedPlaceRecommendations extends StatefulWidget {
  final String title;
  final int maxItems;
  final bool showLoadMore;
  final VoidCallback? onLoadMore;
  final EdgeInsets? padding;

  const PersonalizedPlaceRecommendations({
    super.key,
    this.title = 'Places You\'ll Love',
    this.maxItems = 10,
    this.showLoadMore = true,
    this.onLoadMore,
    this.padding,
  });

  @override
  State<PersonalizedPlaceRecommendations> createState() => _PersonalizedPlaceRecommendationsState();
}

class _PersonalizedPlaceRecommendationsState extends State<PersonalizedPlaceRecommendations> {
  final UnifiedSearchService _searchService = UnifiedSearchService();
  final VibeTagService _vibeTagService = VibeTagService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();

  List<PlaceDetails> _recommendations = [];
  bool _isLoading = true;
  String? _error;
  DateTime? _lastCacheTime;
  static const Duration _cacheExpiry = Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Get user's location
      final locationResult = await _locationService.getCurrentLocation();
      if (!locationResult.success || locationResult.position == null) {
        setState(() {
          _error = 'Location not available';
          _isLoading = false;
        });
        return;
      }

      // Get user's vibe preferences
      final userVibes = await _vibeTagService.getEntityVibeAssociations(
        currentUser.uid,
        'user',
      );

      // If user has no vibes, show trending places
      if (userVibes.isEmpty) {
        final trendingResults = await _searchService.unifiedSearch(
          query: 'trending popular nearby',
          latitude: locationResult.position!.latitude,
          longitude: locationResult.position!.longitude,
          radiusKm: 25.0,
          entityTypes: ['place'],
          limitPerType: widget.maxItems,
        );

        if (trendingResults.success) {
          final places = trendingResults.results['places'] as List<PlaceDetails>? ?? [];
          setState(() {
            _recommendations = places;
            _isLoading = false;
          });
        }
        return;
      }

      // Get personalized recommendations
      final recommendationResults = await _vibeTagService.getPersonalizedRecommendations(
        currentUser.uid,
        entityTypes: ['place'],
        limitPerType: widget.maxItems,
      );

      final placeIds = recommendationResults['place'] ?? [];
      final places = <PlaceDetails>[];

      // Fetch place details for recommended IDs
      for (final placeId in placeIds.take(widget.maxItems)) {
        // In a real app, you'd have a method to get place details by ID
        // For now, we'll use search to find nearby places with similar vibes
        continue;
      }

      // Fallback: Search for places with user's vibes
      final vibeIds = userVibes.map((v) => v.vibeTagId).toList();
      final vibeSearchQuery = vibeIds.take(3).join(' ');
      
      final searchResults = await _searchService.unifiedSearch(
        query: vibeSearchQuery,
        latitude: locationResult.position!.latitude,
        longitude: locationResult.position!.longitude,
        radiusKm: 30.0,
        entityTypes: ['place'],
        limitPerType: widget.maxItems,
      );

      if (searchResults.success) {
        final searchPlaces = searchResults.results['places'] as List<PlaceDetails>? ?? [];
        setState(() {
          _recommendations = searchPlaces;
          _isLoading = false;
          _lastCacheTime = DateTime.now(); // Cache timestamp
        });
      } else {
        setState(() {
          _error = 'Failed to load recommendations';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading recommendations: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!_isLoading && _recommendations.isNotEmpty) ...[
                IconButton(
                  onPressed: () {
                    setState(() {
                      _lastCacheTime = null; // Force refresh
                    });
                    _loadRecommendations();
                  },
                  icon: Icon(Icons.refresh, size: 20, color: Colors.grey[600]),
                  tooltip: 'Refresh recommendations',
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const VisualDiscoveryScreen(),
                      ),
                    );
                  },
                  child: const Text('See All'),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Content
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load recommendations',
                      style: TextStyle(color: Colors.red[600]),
                    ),
                    TextButton(
                      onPressed: _loadRecommendations,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_recommendations.isEmpty)
            _buildEmptyState()
          else
            _buildRecommendationsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No recommendations yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete your vibe profile to get personalized suggestions',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return Container(
      height: 290, // Increased by 10px to fix overflow
      padding: const EdgeInsets.symmetric(vertical: 5), // Add vertical padding
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recommendations.length + (widget.showLoadMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _recommendations.length && widget.showLoadMore) {
            return _buildLoadMoreCard();
          }
          
          final place = _recommendations[index];
          return _buildPlaceRecommendationCard(place);
        },
      ),
    );
  }

  Widget _buildPlaceRecommendationCard(PlaceDetails place) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            // Navigate to place detail
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with overlay
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Main image
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[200],
                        image: place.imageUrls != null && place.imageUrls!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(place.imageUrls!.first),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: place.imageUrls == null || place.imageUrls!.isEmpty
                          ? Icon(Icons.place, size: 40, color: Colors.grey[400])
                          : null,
                    ),
                    
                    // Gradient overlay
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    
                    // Top overlay info (rating, distance, vibe match)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          if (place.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 12, color: Colors.amber[400]),
                                  const SizedBox(width: 2),
                                  Text(
                                    place.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '95% Match',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Bottom overlay info (distance)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 12, color: Colors.white),
                            const SizedBox(width: 2),
                            const Text(
                              '2.3km',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Details below image
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        place.description.isNotEmpty ? place.description : 'No description available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreCard() {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onLoadMore ?? () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VisualDiscoveryScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 32, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'See More',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// VIBE-COMPATIBLE CIRCLES
// ============================================================================

class VibeCompatibleCircles extends StatefulWidget {
  final String title;
  final int maxItems;
  final EdgeInsets? padding;

  const VibeCompatibleCircles({
    super.key,
    this.title = 'Circles You\'ll Love',
    this.maxItems = 5,
    this.padding,
  });

  @override
  State<VibeCompatibleCircles> createState() => _VibeCompatibleCirclesState();
}

class _VibeCompatibleCirclesState extends State<VibeCompatibleCircles> {
  final VibeTagService _vibeTagService = VibeTagService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _compatibleCircles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompatibleCircles();
  }

  Future<void> _loadCompatibleCircles() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final compatibleCircles = await _vibeTagService.getCompatibleEntities(
        sourceEntityId: currentUser.uid,
        sourceEntityType: 'user',
        targetEntityType: 'circle',
        limit: widget.maxItems,
        minCompatibility: 0.4,
      );

      setState(() {
        _compatibleCircles = compatibleCircles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading compatible circles: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (_isLoading)
            const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          else if (_compatibleCircles.isEmpty)
            _buildEmptyState()
          else
            _buildCirclesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No compatible circles found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCirclesList() {
    return Column(
      children: _compatibleCircles.map((circleData) {
        final circle = circleData['circle'] as VibeCircle;
        final compatibility = circleData['compatibilityScore'] as VibeCompatibilityScore;
        
        return _buildCircleCard(circle, compatibility);
      }).toList(),
    );
  }

  Widget _buildCircleCard(VibeCircle circle, VibeCompatibilityScore compatibility) {
    final matchPercentage = (compatibility.overallScore * 100).round();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: circle.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(circle.imageUrl!, fit: BoxFit.cover),
                )
              : Icon(Icons.group, color: Colors.white, size: 20),
        ),
        
        title: Text(
          circle.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${circle.memberCount} members • $matchPercentage% match',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (compatibility.sharedVibes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: compatibility.sharedVibes.take(3).map((vibe) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vibe,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CircleDetailScreen(circleId: circle.id),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(60, 32),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Join', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

// ============================================================================
// TRENDING VIBES WIDGET
// ============================================================================

class TrendingVibesWidget extends StatefulWidget {
  final String title;
  final int maxItems;
  final EdgeInsets? padding;

  const TrendingVibesWidget({
    super.key,
    this.title = 'Trending Vibes',
    this.maxItems = 8,
    this.padding,
  });

  @override
  State<TrendingVibesWidget> createState() => _TrendingVibesWidgetState();
}

class _TrendingVibesWidgetState extends State<TrendingVibesWidget> {
  final VibeTagService _vibeTagService = VibeTagService();
  
  List<VibeTag> _trendingVibes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrendingVibes();
  }

  Future<void> _loadTrendingVibes() async {
    setState(() => _isLoading = true);

    try {
      final allVibes = await _vibeTagService.getAllVibeTags();
      
      // Sort by popularity and usage
      allVibes.sort((a, b) {
        final scoreA = a.popularity + (a.usageCount / 1000.0);
        final scoreB = b.popularity + (b.usageCount / 1000.0);
        return scoreB.compareTo(scoreA);
      });

      setState(() {
        _trendingVibes = allVibes.take(widget.maxItems).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading trending vibes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (_isLoading)
            const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
          else if (_trendingVibes.isEmpty)
            _buildEmptyState()
          else
            _buildTrendingVibesGrid(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No trending vibes available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildTrendingVibesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _trendingVibes.map((vibe) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VisualDiscoveryScreen(
                  initialVibes: [vibe.id],
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(int.parse(vibe.color.replaceFirst('#', '0xFF'))),
                  Color(int.parse(vibe.color.replaceFirst('#', '0xFF'))).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Color(int.parse(vibe.color.replaceFirst('#', '0xFF'))).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconData(vibe.icon),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  vibe.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'fireplace': Icons.fireplace,
      'flash': Icons.flash_on,
      'leaf': Icons.local_florist,
      'camera': Icons.camera_alt,
      'square': Icons.crop_square,
      'time': Icons.access_time,
      'people': Icons.people,
      'heart': Icons.favorite,
      'home': Icons.home,
      'compass': Icons.explore,
      'diamond': Icons.diamond,
      'star': Icons.star,
      'heart-outline': Icons.favorite_border,
      'bulb': Icons.lightbulb,
      'leaf-outline': Icons.eco,
      'happy': Icons.sentiment_very_satisfied,
    };
    return iconMap[iconName] ?? Icons.tag;
  }
}

// ============================================================================
// RECOMMENDED PEOPLE WIDGET
// ============================================================================

class RecommendedPeopleWidget extends StatefulWidget {
  final String title;
  final int maxItems;
  final EdgeInsets? padding;

  const RecommendedPeopleWidget({
    super.key,
    this.title = 'People You\'ll Vibe With',
    this.maxItems = 5,
    this.padding,
  });

  @override
  State<RecommendedPeopleWidget> createState() => _RecommendedPeopleWidgetState();
}

class _RecommendedPeopleWidgetState extends State<RecommendedPeopleWidget> {
  final VibeTagService _vibeTagService = VibeTagService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _recommendedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendedUsers();
  }

  Future<void> _loadRecommendedUsers() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final compatibleUsers = await _vibeTagService.getCompatibleEntities(
        sourceEntityId: currentUser.uid,
        sourceEntityType: 'user',
        targetEntityType: 'user',
        limit: widget.maxItems,
        minCompatibility: 0.5,
      );

      setState(() {
        _recommendedUsers = compatibleUsers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recommended users: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          if (_isLoading)
            const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          else if (_recommendedUsers.isEmpty)
            _buildEmptyState()
          else
            _buildUsersList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No recommendations yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recommendedUsers.length,
        itemBuilder: (context, index) {
          final userData = _recommendedUsers[index];
          final user = userData['user'] as EnhancedUser;
          final compatibility = userData['compatibilityScore'] as VibeCompatibilityScore;
          
          return _buildUserCard(user, compatibility);
        },
      ),
    );
  }

  Widget _buildUserCard(EnhancedUser user, VibeCompatibilityScore compatibility) {
    final matchPercentage = (compatibility.overallScore * 100).round();
    
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EnhancedProfileScreen(userId: user.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: user.photoUrl == null
                      ? Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                
                const SizedBox(height: 8),
                
                // Name
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Match percentage
                Text(
                  '$matchPercentage% match',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}