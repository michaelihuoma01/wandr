import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/search_service.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/unified_search_service.dart';
import '../services/visit_service.dart';
import '../services/vibe_tag_service.dart';
import '../widgets/enhanced_place_card.dart';
import '../widgets/vibe_recommendation_widgets.dart';
import '../widgets/search_history_item.dart';
import '../screens/discovery/visual_discovery_screen.dart';
import '../screens/circles/circles_list_screen.dart';
import '../screens/enhanced_profile_screen.dart';
import '../screens/onboarding/streamlined_onboarding_screen.dart';

// ============================================================================
// ENHANCED HOME SCREEN WITH VIBE INTEGRATION
// ============================================================================

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  // Services
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();
  final UnifiedSearchService _searchService = UnifiedSearchService();
  final VisitService _visitService = VisitService();
  final VibeTagService _vibeTagService = VibeTagService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchSlideAnimation;

  // State variables
  UnifiedSearchResult? _searchResults;
  List<SearchSuggestion> _suggestions = [];
  List<SearchHistory> _recentSearches = [];
  bool _isLoading = false;
  bool _isLoadingRecommendations = false;
  String? _errorMessage;
  String _userName = 'User';
  double _searchRadius = 25.0;
  String? _currentQuery;
  int _selectedIndex = 0; // For bottom navigation
  bool _isTrackingEnabled = false;
  File? _selectedImage;
  bool _isImageSearch = false;
  bool _isSearchFocused = false;
  bool _hasSearched = false;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _searchSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeData() async {
    await _loadUserName();
    await _loadLocation();
    await _loadRecentSearches();
    await _checkTrackingStatus();
    await _checkOnboardingStatus();
    _animationController.forward();
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
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    try {
      // In a real implementation, you'd have a method to get search history
      // For now, we'll leave it empty or implement a basic version
      setState(() => _recentSearches = []);
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _checkTrackingStatus() async {
    setState(() => _isTrackingEnabled = false);
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Check if user has completed vibe onboarding
      final userVibes = await _vibeTagService.getEntityVibeAssociations(
        currentUser.uid,
        'user',
      );

      setState(() {
        _showOnboarding = userVibes.isEmpty;
      });
    } catch (e) {
      print('Error checking onboarding status: $e');
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

  Future<void> _performSearch([String? historyQuery]) async {
    final query = historyQuery ?? _searchController.text.trim();

    if (query.isEmpty && _selectedImage == null) {
      setState(() {
        _searchResults = null;
        _hasSearched = false;
        _suggestions = [];
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
      _suggestions = [];
      if (historyQuery != null) {
        _searchController.text = historyQuery;
      }
    });

    try {
      UnifiedSearchResult result;

      if (_selectedImage != null) {
        // Handle image search
        _isImageSearch = true;
        // For now, we'll convert image search to a text query
        // In a real implementation, you'd upload the image and get a URL
        result = await _searchService.unifiedSearch(
          query: 'image search visual similar',
          latitude: _locationService.currentPosition!.latitude,
          longitude: _locationService.currentPosition!.longitude,
          radiusKm: _searchRadius,
          limitPerType: 20,
        );
      } else {
        // Text search
        _isImageSearch = false;
        result = await _searchService.unifiedSearch(
          query: query,
          latitude: _locationService.currentPosition!.latitude,
          longitude: _locationService.currentPosition!.longitude,
          radiusKm: _searchRadius,
          limitPerType: 20,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) {
            _searchResults = result;
            _currentQuery = _isImageSearch ? 'Image Search' : query;
            _hasSearched = true;
            _isSearchFocused = false;
            FocusScope.of(context).unfocus();
          } else {
            _errorMessage = result.error;
            _searchResults = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Search failed: $e';
          _searchResults = null;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _suggestions = [];
      _searchResults = null;
      _hasSearched = false;
      _selectedImage = null;
      _isImageSearch = false;
      _currentQuery = null;
      _errorMessage = null;
    });
  }

  Future<void> _pickImageForSearch() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _performSearch();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedIndex) return;

    setState(() => _selectedIndex = index);

    switch (index) {
      case 0:
        // Home - stay here
        break;
      case 1:
        // Discovery
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const VisualDiscoveryScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 2:
        // Circles
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const CirclesListScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
      case 3:
        // Profile
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, _) => const EnhancedProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(position: animation.drive(tween), child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        break;
    }

    // Reset selected index after navigation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _selectedIndex = 0);
    });
  }

  void _navigateToDiscover() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const VisualDiscoveryScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToCircles() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, _) => const CirclesListScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search header with safe area
          SafeArea(
            bottom: false,
            child: _buildSearchHeader(),
          ),
          
          // Content
          Expanded(
            child: _hasSearched ? _buildSearchResults() : _buildHomeContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildNearbyRecommendations() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.near_me, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Nearby Places',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // Force refresh nearby places
                    setState(() {}); // This will trigger a rebuild of FutureBuilder
                  },
                  icon: Icon(Icons.refresh, size: 20, color: Colors.grey[600]),
                  tooltip: 'Refresh nearby places',
                ),
                TextButton(
                  onPressed: () => _navigateToDiscover(),
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Use PersonalizedPlaceRecommendations widget for consistency
          const PersonalizedPlaceRecommendations(
            title: '', // Empty title since we have our own header
            maxItems: 5,
            showLoadMore: false, // Remove duplicate See All
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
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
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isSearchFocused
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: _isSearchFocused ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search places, vibes, circles...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedImage != null)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                image: DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt, size: 20),
                            onPressed: _pickImageForSearch,
                          ),
                          if (_searchController.text.isNotEmpty || _selectedImage != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: _clearSearch,
                            ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onTap: () {
                      setState(() => _isSearchFocused = true);
                      HapticFeedback.selectionClick();
                    },
                    onSubmitted: (_) {
                      HapticFeedback.lightImpact();
                      _performSearch();
                    },
                    onChanged: (_) => _onSearchChanged(),
                    onEditingComplete: () {
                      setState(() => _isSearchFocused = false);
                    },
                  ),
                ),
              ),
              
              if (_hasSearched) ...[
                const SizedBox(width: 12),
                AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _clearSearch();
                    },
                  ),
                ),
              ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            onTap: () {
              _searchController.text = suggestion.text;
              _performSearch();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _initializeData,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            _buildWelcomeHeader(),
            
            // Onboarding prompt (if needed)
            if (_showOnboarding) _buildOnboardingPrompt(),
            
            // Quick actions
            _buildQuickActions(),
            
            // Trending vibes
            const TrendingVibesWidget(),
            
            // Personalized recommendations
            const PersonalizedPlaceRecommendations(),
            
            // Nearby places with recommendation widgets
            _buildNearbyRecommendations(),
            
            // Compatible circles
            const VibeCompatibleCircles(),
            
            // People recommendations
            const RecommendedPeopleWidget(),
            
            const SizedBox(height: 100), // Bottom padding for nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hey $_userName! 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Discover amazing places that match your vibe',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPrompt() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete Your Vibe Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get personalized recommendations',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const StreamlinedOnboardingScreen(),
                      ),
                    ).then((_) => _checkOnboardingStatus());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  child: const Text('Get Started'),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.psychology,
            color: Colors.white,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout - use column on very small screens
          if (constraints.maxWidth < 300) {
            return Column(
              children: [
                _buildQuickActionCard(
                  icon: Icons.explore,
                  title: 'Discover',
                  subtitle: 'Find new places',
                  color: Colors.blue,
                  onTap: () => _navigateToDiscover(),
                ),
                const SizedBox(height: 12),
                _buildQuickActionCard(
                  icon: Icons.group,
                  title: 'Circles',
                  subtitle: 'Join groups',
                  color: Colors.green,
                  onTap: () => _navigateToCircles(),
                ),
              ],
            );
          }
          
          // Normal row layout
          return Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.explore,
                  title: 'Discover',
                  subtitle: 'Find new places',
                  color: Colors.blue,
                  onTap: () => _navigateToDiscover(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.group,
                  title: 'Circles',
                  subtitle: 'Join groups',
                  color: Colors.green,
                  onTap: () => _navigateToCircles(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Search Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _performSearch,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults == null || _searchResults!.totalResults == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Results Found',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search terms',
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

    // Show search results
    final places = _searchResults!.results['places'] as List<PlaceDetails>? ?? [];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive padding based on screen width
        final horizontalPadding = constraints.maxWidth > 600 
            ? (constraints.maxWidth - 600) / 2 
            : 0.0;
        
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            bottom: 120, // Space for bottom nav
            top: 8,
          ),
          itemCount: places.length,
          itemBuilder: (context, index) {
            final place = places[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: EnhancedPlaceCard(
                place: place,
                currentPosition: _locationService.currentPosition!,
                processImageUrl: (url) => url ?? '',
                onVibesUpdated: () {
                  // Refresh recommendations if needed
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          selectedIconTheme: const IconThemeData(size: 26),
          unselectedIconTheme: const IconThemeData(size: 24),
          items: [
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 1 ? Icons.explore : Icons.explore_outlined),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2 ? Icons.group : Icons.group_outlined),
              label: 'Circles',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 3 ? Icons.person : Icons.person_outline),
              label: 'Profile',
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
}