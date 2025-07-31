import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/models.dart';
import '../../models/circle_models.dart';
import '../../models/vibe_tag_models.dart';
import '../../services/unified_search_service.dart';
import '../../services/vibe_tag_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/vibe_selection_widgets.dart';
import '../circles/circle_detail_screen.dart';
import '../enhanced_profile_screen.dart';

// ============================================================================
// VISUAL-FIRST DISCOVERY - TikTok meets Instagram for places
// ============================================================================

class VisualDiscoveryScreen extends StatefulWidget {
  final String? initialQuery;
  final List<String>? initialVibes;

  const VisualDiscoveryScreen({
    super.key,
    this.initialQuery,
    this.initialVibes,
  });

  @override
  State<VisualDiscoveryScreen> createState() => _VisualDiscoveryScreenState();
}

class _VisualDiscoveryScreenState extends State<VisualDiscoveryScreen>
    with TickerProviderStateMixin {
  final UnifiedSearchService _searchService = UnifiedSearchService();
  final VibeTagService _vibeTagService = VibeTagService();
  final LocationService _locationService = LocationService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;
  late AnimationController _filterAnimationController;
  late Animation<Offset> _filterSlideAnimation;

  UnifiedSearchResult? _searchResults;
  List<SearchSuggestion> _suggestions = [];
  Set<String> _selectedVibes = {};
  bool _isLoading = false;
  bool _showFilters = false;
  bool _hasSearched = false;
  String _activeTab = 'all';
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;

  static const List<String> _tabs = ['all', 'places', 'circles', 'boards', 'people'];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupInitialData();
    _loadLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTab = _tabs[_tabController.index];
        });
      }
    });

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _filterSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupInitialData() {
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
    if (widget.initialVibes != null) {
      _selectedVibes = widget.initialVibes!.toSet();
    }
  }

  Future<void> _loadLocation() async {
    final locationResult = await _locationService.getCurrentLocation();
    if (locationResult.success && locationResult.position != null) {
      setState(() {
        _currentLatitude = locationResult.position!.latitude;
        _currentLongitude = locationResult.position!.longitude;
      });
      
      // Perform initial search if we have data
      if (widget.initialQuery != null || widget.initialVibes != null) {
        _performSearch();
      } else {
        _loadTrendingContent();
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      _getSuggestions(query);
    } else {
      setState(() => _suggestions = []);
    }
  }

  Future<void> _getSuggestions(String query) async {
    try {
      final suggestions = await _searchService.getSearchSuggestions(query);
      setState(() => _suggestions = suggestions);
    } catch (e) {
      print('Error getting suggestions: $e');
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    
    if (query.isEmpty && _selectedVibes.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _suggestions = [];
    });

    try {
      final results = await _searchService.unifiedSearch(
        query: query.isNotEmpty ? query : null,
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        radiusKm: 25.0,
        limitPerType: 20,
      );

      setState(() {
        _searchResults = results;
        _hasSearched = true;
        _isLoading = false;
      });

      // Close filters if open
      if (_showFilters) {
        _toggleFilterPanel();
      }
    } catch (e) {
      print('Error performing search: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTrendingContent() async {
    // Load trending/popular content when no specific search
    setState(() => _isLoading = true);

    try {
      final results = await _searchService.unifiedSearch(
        query: 'trending popular',
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        radiusKm: 50.0,
        entityTypes: ['place', 'circle', 'board'],
        limitPerType: 15,
      );

      setState(() {
        _searchResults = results;
        _hasSearched = true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading trending content: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applySuggestion(SearchSuggestion suggestion) {
    _searchController.text = suggestion.text;
    _performSearch();
  }

  void _toggleFilterPanel() {
    setState(() => _showFilters = !_showFilters);
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  void _onVibeSelectionChanged(Set<String> vibes) {
    setState(() => _selectedVibes = vibes);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _selectedVibes = {};
      _searchResults = null;
      _hasSearched = false;
    });
    _loadTrendingContent();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[800], size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Discover',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_selectedVibes.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedVibes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _showFilters || _selectedVibes.isNotEmpty
                  ? theme.primaryColor
                  : Colors.grey[600],
            ),
            onPressed: _toggleFilterPanel,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Search header
            _buildSearchHeader(),
            
            // Filters panel
            if (_showFilters) _buildFiltersPanel(),
            
            // Tab bar
            if (_hasSearched) _buildTabBar(),
            
            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search places, vibes, circles...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Search action button
              GestureDetector(
                onTap: _performSearch,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          // Suggestions
          if (_suggestions.isNotEmpty) _buildSuggestions(),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: _suggestions.take(3).map((suggestion) {
          return ListTile(
            dense: true,
            leading: Icon(
              _getSuggestionIcon(suggestion.type),
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              suggestion.text,
              style: const TextStyle(fontSize: 14),
            ),
            subtitle: suggestion.subtitle != null
                ? Text(
                    suggestion.subtitle!,
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
            onTap: () => _applySuggestion(suggestion),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return SlideTransition(
      position: _filterSlideAnimation,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filter by vibes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_selectedVibes.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _selectedVibes = {}),
                    child: const Text('Clear'),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            CompactVibeSelector(
              selectedVibes: _selectedVibes,
              onSelectionChanged: _onVibeSelectionChanged,
              maxSelections: 5,
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _toggleFilterPanel,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'All (${_searchResults?.totalResults ?? 0})'),
          Tab(text: 'Places (${_searchResults?.results['places']?.length ?? 0})'),
          Tab(text: 'Circles (${_searchResults?.results['circles']?.length ?? 0})'),
          Tab(text: 'Boards (${_searchResults?.results['boards']?.length ?? 0})'),
          Tab(text: 'People (${_searchResults?.results['users']?.length ?? 0})'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState();
    }

    if (_searchResults == null || _searchResults!.totalResults == 0) {
      return _buildNoResultsState();
    }

    if (_hasSearched) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildAllResultsView(),
          _buildPlacesView(),
          _buildCirclesView(),
          _buildBoardsView(),
          _buildPeopleView(),
        ],
      );
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Discover Amazing Places',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for places, find circles to join, or discover curated boards',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.text = 'trending';
                _performSearch();
              },
              icon: const Icon(Icons.trending_up),
              label: const Text('Explore Trending'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _clearSearch,
              child: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllResultsView() {
    final allResults = <Widget>[];
    
    // Add places
    final places = _searchResults?.results['places'] as List<PlaceDetails>? ?? [];
    if (places.isNotEmpty) {
      allResults.add(_buildSectionHeader('Places', places.length));
      allResults.add(_buildPlaceGrid(places.take(4).toList()));
    }
    
    // Add circles
    final circles = _searchResults?.results['circles'] as List<Map<String, dynamic>>? ?? [];
    if (circles.isNotEmpty) {
      allResults.add(_buildSectionHeader('Circles', circles.length));
      allResults.add(_buildCirclesList(circles.take(3).toList()));
    }
    
    // Add boards
    final boards = _searchResults?.results['boards'] as List<Map<String, dynamic>>? ?? [];
    if (boards.isNotEmpty) {
      allResults.add(_buildSectionHeader('Boards', boards.length));
      allResults.add(_buildBoardsGrid(boards.take(4).toList()));
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: allResults,
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacesView() {
    final places = _searchResults?.results['places'] as List<PlaceDetails>? ?? [];
    return _buildPlaceGrid(places);
  }

  Widget _buildCirclesView() {
    final circles = _searchResults?.results['circles'] as List<Map<String, dynamic>>? ?? [];
    return _buildCirclesList(circles);
  }

  Widget _buildBoardsView() {
    final boards = _searchResults?.results['boards'] as List<Map<String, dynamic>>? ?? [];
    return _buildBoardsGrid(boards);
  }

  Widget _buildPeopleView() {
    final users = _searchResults?.results['users'] as List<Map<String, dynamic>>? ?? [];
    return _buildUsersList(users);
  }

  Widget _buildPlaceGrid(List<PlaceDetails> places) {
    if (places.isEmpty) {
      return const Center(child: Text('No places found'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return _buildPlaceCard(place);
      },
    );
  }

  Widget _buildPlaceCard(PlaceDetails place) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        // Navigate to place detail
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    image: place.imageUrls != null && place.imageUrls!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(place.imageUrls!.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: place.imageUrls == null || place.imageUrls!.isEmpty
                      ? Icon(
                          Icons.place,
                          size: 40,
                          color: Colors.grey[400],
                        )
                      : null,
                ),
              ),
              
              // Details
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      if (place.rating != null)
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              place.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      
                      const Spacer(),
                      
                      if (place.priceLevel != null && place.priceLevel!.isNotEmpty)
                        Text(
                          '\$' * _parsePriceLevel(place.priceLevel!),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
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

  Widget _buildCirclesList(List<Map<String, dynamic>> circles) {
    if (circles.isEmpty) {
      return const Center(child: Text('No circles found'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: circles.length,
      itemBuilder: (context, index) {
        final circleData = circles[index];
        final circle = circleData['circle'] as VibeCircle;
        return _buildCircleCard(circle, circleData);
      },
    );
  }

  Widget _buildCircleCard(VibeCircle circle, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CircleDetailScreen(circleId: circle.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circle avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
              child: circle.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        circle.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 24,
                    ),
            ),
            
            const SizedBox(width: 16),
            
            // Circle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circle.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    circle.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${circle.memberCount} members',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Join button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(60, 32),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'Join',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardsGrid(List<Map<String, dynamic>> boards) {
    if (boards.isEmpty) {
      return const Center(child: Text('No boards found'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: boards.length,
      itemBuilder: (context, index) {
        final boardData = boards[index];
        final board = boardData['board'] as VibeBoard;
        return _buildBoardCard(board, boardData);
      },
    );
  }

  Widget _buildBoardCard(VibeBoard board, Map<String, dynamic> data) {
    final vibes = data['vibes'] as List<String>? ?? [];
    
    return GestureDetector(
      onTap: () {
        // Navigate to board detail
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bookmark,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  Text(
                    '${board.places.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Text(
                board.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              Text(
                board.description!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              if (vibes.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: vibes.take(2).map((vibe) {
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
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return const Center(child: Text('No people found'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final userData = users[index];
        final user = userData['user'] as EnhancedUser;
        return _buildUserCard(user, userData);
      },
    );
  }

  Widget _buildUserCard(EnhancedUser user, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EnhancedProfileScreen(userId: user.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 24,
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
            
            const SizedBox(width: 16),
            
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  
                  if (user.vibeTitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.vibeTitle!,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  
                  if (user.bio != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Follow button
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).primaryColor),
                minimumSize: const Size(60, 32),
              ),
              child: Text(
                'Follow',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSuggestionIcon(String type) {
    switch (type) {
      case 'vibe':
        return Icons.psychology;
      case 'popular':
        return Icons.trending_up;
      case 'recent':
        return Icons.history;
      default:
        return Icons.search;
    }
  }

  int _parsePriceLevel(String priceLevel) {
    if (priceLevel.isEmpty) return 1;
    
    try {
      final parsed = int.parse(priceLevel);
      return parsed.clamp(1, 4); // Ensure it's between 1-4
    } catch (e) {
      // If it's not a number, try to count dollar signs
      final dollarCount = priceLevel.split('\$').length - 1;
      return dollarCount > 0 ? dollarCount.clamp(1, 4) : 1;
    }
  }
}