// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:myapp/screens/history_screen.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/search_service.dart';
import '../../widgets/place_card.dart';
import '../../widgets/search_history_item.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Services
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  final SearchService _searchService = SearchService();

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // State variables
  List<PlaceDetails> _searchResults = [];
  List<SearchHistory> _recentSearches = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _userName = 'User';
  double _searchRadius = 20.0; // km
  String? _currentQuery;
  int _currentPage = 0;
  bool _hasMoreResults = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeData();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  Future<void> _initializeData() async {
    await _loadUserName();
    await _loadLocation();
    await _loadRecentSearches();
  }

  Future<void> _loadUserName() async {
    final name = await _authService.getDisplayName();
    if (mounted) {
      setState(() => _userName = name);
    }
  }

  Future<void> _loadLocation() async {
    final result = await _locationService.getCurrentLocation();
    if (mounted) {
      if (result.success) {
        setState(() => _errorMessage = null);
      } else {
        setState(() => _errorMessage = result.error);
        // Show action based on error type
        if (result.errorType == LocationErrorType.serviceDisabled) {
          _showLocationSettingsDialog();
        } else if (result.errorType == LocationErrorType.permissionDeniedForever) {
          _showAppSettingsDialog();
        }
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    final searches = await _searchService.getSearchHistory();
    if (mounted) {
      setState(() => _recentSearches = searches);
    }
  }

  Future<void> _performSearch([String? historyQuery]) async {
    final query = historyQuery ?? _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
        _currentQuery = null;
      });
      return;
    }

    // Ensure we have location
    if (_locationService.currentPosition == null) {
      await _loadLocation();
      if (_locationService.currentPosition == null) {
        setState(() => _errorMessage = 'Unable to get location for search');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 0;
      if (historyQuery != null) {
        _searchController.text = historyQuery;
      }
    });

    final result = await _searchService.searchPlaces(
      query: query,
      latitude: _locationService.currentPosition!.latitude,
      longitude: _locationService.currentPosition!.longitude,
      radiusKm: _searchRadius,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _searchResults = result.locations;
          _currentQuery = query;
          _hasMoreResults = result.hasMore;
          _animationController.forward();
        } else {
          _errorMessage = result.error;
          _searchResults = [];
        }
      });

      if (result.success) {
        await _searchService.saveToHistory(
          query,
          result.totalResults,
          _locationService.currentPosition!.latitude,
          _locationService.currentPosition!.longitude,
        );
        await _loadRecentSearches();
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMoreResults || _currentQuery == null) return;

    setState(() => _isLoadingMore = true);

    final result = await _searchService.loadMoreResults(
      _currentQuery!,
      _locationService.currentPosition!.latitude,
      _locationService.currentPosition!.longitude,
      _searchRadius,
      _currentPage,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          _searchResults.addAll(result.locations);
          _currentPage++;
          _hasMoreResults = result.hasMore;
        }
      });
    }
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text('Please enable location services to use this app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showAppSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text('Please grant location permission in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Wandr'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(
                    onSearchSelected: (query) {
                      Navigator.pop(context);
                      _performSearch(query);
                    },
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_errorMessage != null) _buildErrorMessage(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Row(
            children: [
              Expanded(
                child: Text(
                  'Welcome, $_userName',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: -1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'AI Powered',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // Location info
          if (_locationService.currentPosition != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _locationService.currentCity,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Search bar
          _buildSearchBar(),
          
          const SizedBox(height: 12),
          
          // Distance slider
          _buildDistanceSlider(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Try "pet friendly cafes" or "romantic dinner"',
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).primaryColor,
                  ),
                  onPressed: _performSearch,
                ),
        ),
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildDistanceSlider() {
    return Row(
      children: [
        Text(
          'Search Radius: ${_searchRadius.toStringAsFixed(0)} km',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Slider(
            value: _searchRadius,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_searchRadius.toStringAsFixed(0)} km',
            onChanged: (value) => setState(() => _searchRadius = value),
            activeColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_searchResults.isNotEmpty) {
      return _buildSearchResults();
    } else if (_recentSearches.isNotEmpty && !_isLoading) {
      return _buildRecentSearches();
    } else {
      return _buildEmptyState();
    }
  }

  Widget _buildSearchResults() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            _hasMoreResults &&
            !_isLoadingMore) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _searchResults.length + (_hasMoreResults ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _searchResults.length) {
            return _buildLoadMoreButton();
          }
          return FadeTransition(
            opacity: _fadeAnimation,
            child: PlaceCard(
              place: _searchResults[index],
              currentPosition: _locationService.currentPosition!,
              processImageUrl: _searchService.processImageUrl,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (_isLoadingMore) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _loadMore,
          icon: const Icon(Icons.expand_more),
          label: const Text('Load More'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryScreen(
                        onSearchSelected: (query) {
                          Navigator.pop(context);
                          _performSearch(query);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.length,
            itemBuilder: (context, index) {
              return SearchHistoryItem(
                history: _recentSearches[index],
                onTap: () => _performSearch(_recentSearches[index].query),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.explore_outlined,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Discover Amazing Places',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for your perfect vibe',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_locationService.currentPosition == null) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadLocation,
              icon: const Icon(Icons.location_on),
              label: const Text('Enable Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}