// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import 'circles/circles_list_screen.dart';
import 'history_screen.dart';
import 'vibe_quiz_screen.dart';
import '../widgets/admin_test_data_panel.dart';

import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/search_service.dart';
import '../services/visit_service.dart';
import '../widgets/place_card.dart';
import '../widgets/search_history_item.dart';
import '../widgets/search_filter_sheet.dart';
import 'welcome_screen.dart';
import 'enhanced_profile_screen.dart';

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
  final VisitService _visitService = VisitService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // State variables
  List<PlaceDetails> _searchResults = [];
  List<PlaceDetails> _filteredResults = [];
  List<SearchHistory> _recentSearches = [];
  List<PlaceDetails> _discoverPlaces = [];
  bool _isLoadingDiscoverPlaces = false;
  bool _isLoading = false;
  String? _errorMessage;
  String _userName = 'User';
  double _searchRadius = 25.0; // km - default 25km for better coverage
  String? _currentQuery;
  int _currentPage = 0;
  bool _hasMoreResults = false;
  bool _isLoadingMore = false;
  int _selectedIndex = 0; // For bottom navigation
  bool _isTrackingEnabled = false;
  File? _selectedImage;
  bool _isImageSearch = false;
  SearchFilter _currentFilter = SearchFilter();
  bool _isSearchFocused = false; // Track if search field is focused

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
    await _checkTrackingStatus();
    await _loadDiscoverPlaces();
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

  Future<void> _checkTrackingStatus() async {
    // Check if background tracking is enabled from preferences
    // This is a simplified version - you'd implement proper preference storage
    setState(() {
      _isTrackingEnabled = false; // Default to false
    });
  }

  Future<void> _toggleTracking() async {
    if (_isTrackingEnabled) {
      _visitService.stopBackgroundTracking();
      setState(() => _isTrackingEnabled = false);
    } else {
      final enabled = await _visitService.startBackgroundTracking();
      if (enabled) {
        setState(() => _isTrackingEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Background location tracking enabled'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable location permissions for background tracking'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _performSearch([String? historyQuery]) async {
    final query = historyQuery ?? _searchController.text;
    
    // Check if we have either text or image
    if (query.isEmpty && _selectedImage == null) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
        _currentQuery = null;
        _isImageSearch = false;
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

    SearchResult result;
    
    if (_selectedImage != null) {
      // Image search
      _isImageSearch = true;
      
      // Upload image and get URL
      final imageUrl = await _searchService.uploadSearchImage(_selectedImage!);
      
      if (imageUrl == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to upload image';
        });
        return;
      }
      
      result = await _searchService.searchPlaces(
        imageUrl: imageUrl,
        latitude: _locationService.currentPosition!.latitude,
        longitude: _locationService.currentPosition!.longitude,
        radiusKm: _searchRadius,
      );
    } else {
      // Text search
      _isImageSearch = false;
      result = await _searchService.searchPlaces(
        query: query,
        latitude: _locationService.currentPosition!.latitude,
        longitude: _locationService.currentPosition!.longitude,
        radiusKm: _searchRadius,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _searchResults = result.locations;
          _applyFilters(); // Apply filters to results
          _currentQuery = _isImageSearch ? 'Image Search' : query;
          _hasMoreResults = result.hasMore;
          _animationController.forward();
        } else {
          _errorMessage = result.error;
          _searchResults = [];
          _filteredResults = [];
        }
      });

      if (result.success && !_isImageSearch) {
        await _searchService.saveToHistory(
          query,
          result.totalResults,
          _locationService.currentPosition!.latitude,
          _locationService.currentPosition!.longitude,
        );
        await _loadRecentSearches();
      } else if (result.success && _isImageSearch) {
        // Save image search to history with a descriptive query
        await _searchService.saveToHistory(
          'Image Search - ${DateTime.now().toLocal().toString().split(' ')[1].split('.')[0]}',
          result.totalResults,
          _locationService.currentPosition!.latitude,
          _locationService.currentPosition!.longitude,
          isImageSearch: true,
        );
        await _loadRecentSearches();
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _searchController.clear(); // Clear text when image is selected
        });
        
        // Automatically perform search with the selected image
        await _performSearch();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _isImageSearch = false;
      _searchResults = [];
      _filteredResults = [];
      _currentQuery = null;
      _currentFilter = SearchFilter(); // Reset filters too
    });
  }

  void _applyFilters() {
    List<PlaceDetails> filtered = List.from(_searchResults);
    
    // Apply distance filter
    if (_currentFilter.maxDistance != null) {
      filtered = filtered.where((place) {
        final distance = _locationService.calculateDistance(
          _locationService.currentPosition!.latitude,
          _locationService.currentPosition!.longitude,
          place.latitude,
          place.longitude,
        );
        return distance <= _currentFilter.maxDistance!;
      }).toList();
    }
    
    // Apply rating filter
    if (_currentFilter.minRating != null) {
      filtered = filtered.where((place) {
        return place.rating != null && place.rating! >= _currentFilter.minRating!;
      }).toList();
    }
    
    // Apply price filter
    if (_currentFilter.priceLevels.isNotEmpty) {
      filtered = filtered.where((place) {
        return place.priceLevel != null && 
               _currentFilter.priceLevels.contains(place.priceLevel);
      }).toList();
    }
    
    // Apply type filter
    if (_currentFilter.placeTypes.isNotEmpty) {
      filtered = filtered.where((place) {
        final placeType = place.type.toLowerCase();
        return _currentFilter.placeTypes.any((type) => 
          placeType.contains(type.toLowerCase()));
      }).toList();
    }
    
    // Apply sorting
    switch (_currentFilter.sortBy) {
      case SortBy.distance:
        filtered.sort((a, b) {
          final distA = _locationService.calculateDistance(
            _locationService.currentPosition!.latitude,
            _locationService.currentPosition!.longitude,
            a.latitude,
            a.longitude,
          );
          final distB = _locationService.calculateDistance(
            _locationService.currentPosition!.latitude,
            _locationService.currentPosition!.longitude,
            b.latitude,
            b.longitude,
          );
          return distA.compareTo(distB);
        });
        break;
      case SortBy.rating:
        filtered.sort((a, b) {
          final ratingA = a.rating ?? 0;
          final ratingB = b.rating ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case SortBy.priceLowToHigh:
        filtered.sort((a, b) {
          final priceA = a.priceLevel?.length ?? 0;
          final priceB = b.priceLevel?.length ?? 0;
          return priceA.compareTo(priceB);
        });
        break;
      case SortBy.priceHighToLow:
        filtered.sort((a, b) {
          final priceA = a.priceLevel?.length ?? 0;
          final priceB = b.priceLevel?.length ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
    }
    
    setState(() {
      _filteredResults = filtered;
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchFilterSheet(
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
            _applyFilters();
          });
        },
      ),
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          _applyFilters(); // Re-apply filters to include new results
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

  Future<void> _loadDiscoverPlaces() async {
    if (_locationService.currentPosition == null) {
      return;
    }

    setState(() => _isLoadingDiscoverPlaces = true);

    try {
      final timeOfDay = _getTimeOfDayCategory();
      final vibeQuery = _getVibeQueryForTimeAndLocation(timeOfDay);
      
      final result = await _searchService.searchPlaces(
        query: vibeQuery,
        latitude: _locationService.currentPosition!.latitude,
        longitude: _locationService.currentPosition!.longitude,
        radiusKm: 10.0, // Smaller radius for discover places
      );

      if (mounted && result.success) {
        setState(() {
          _discoverPlaces = result.locations.take(6).toList(); // Limit to 6 places
        });
      }
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error loading discover places: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDiscoverPlaces = false);
      }
    }
  }

  String _getTimeOfDayCategory() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) {
      return 'morning';
    } else if (hour >= 11 && hour < 16) {
      return 'midday';
    } else if (hour >= 16 && hour < 19) {
      return 'evening';
    } else {
      return 'night';
    }
  }

  String _getVibeQueryForTimeAndLocation(String timeOfDay) {
    final cityName = _locationService.currentCity;
    final dayOfWeek = DateTime.now().weekday;
    final isSunday = dayOfWeek == 7;
    
    switch (timeOfDay) {
      case 'morning':
        if (isSunday) {
          return 'beach cafes brunch spots $cityName';
        }
        return 'breakfast cafes coffee shops $cityName';
      case 'midday':
        return 'lunch spots business lunch cafes $cityName';
      case 'evening':
        return 'sunset spots romantic restaurants $cityName';
      case 'night':
        return 'dinner restaurants lounges bars $cityName';
      default:
        return 'popular places $cityName';
    }
  }

  Widget _buildDiscoverPlacesSection() {
    final timeOfDay = _getTimeOfDayCategory();
    final sectionTitle = _getDiscoverSectionTitle(timeOfDay);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    _locationService.currentCity,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _loadDiscoverPlaces,
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).primaryColor,
                ),
                tooltip: 'Refresh suggestions',
              ),
            ],
          ),
        ),
        if (_isLoadingDiscoverPlaces)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_discoverPlaces.isNotEmpty)
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _discoverPlaces.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildDiscoverPlaceCard(_discoverPlaces[index]),
                );
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No suggestions available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
      ],
    );
  }

  String _getDiscoverSectionTitle(String timeOfDay) {
    final dayOfWeek = DateTime.now().weekday;
    final isSunday = dayOfWeek == 7;
    
    switch (timeOfDay) {
      case 'morning':
        if (isSunday) {
          return 'Sunday Morning Vibes';
        }
        return 'Morning Fuel';
      case 'midday':
        return 'Midday Picks';
      case 'evening':
        return 'Evening Magic';
      case 'night':
        return 'Night Scene';
      default:
        return 'Suggested for You';
    }
  }

  Widget _buildDiscoverPlaceCard(PlaceDetails place) {
    final distance = _locationService.calculateDistance(
      _locationService.currentPosition!.latitude,
      _locationService.currentPosition!.longitude,
      place.latitude,
      place.longitude,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey[200],
              child: place.imageUrls != null && place.imageUrls!.isNotEmpty
                  ? Image.network(
                      _searchService.processImageUrl(place.imageUrls!.first),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.place, color: Colors.grey[400], size: 40),
                        );
                      },
                    )
                  : Icon(Icons.place, color: Colors.grey[400], size: 40),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (place.rating != null) ...[ 
                        Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          place.rating!.toStringAsFixed(1),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        '${distance.toStringAsFixed(1)}km',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to place details or add to search results
                        setState(() {
                          _searchResults = [place];
                          _filteredResults = [place];
                          _currentQuery = place.name;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('View'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVibeGenerator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VibeQuizScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _isSearchFocused = false;
        });
      },
      child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _selectedIndex == 0 ? AppBar(
        title: const Text('Wandr'),
        actions: [
          // Filter button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterSheet,
                tooltip: 'Filter results',
              ),
              if (_currentFilter.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isTrackingEnabled ? Icons.location_on : Icons.location_off,
              color: _isTrackingEnabled ? Colors.green : Colors.grey,
            ),
            onPressed: _toggleTracking,
            tooltip: _isTrackingEnabled ? 'Tracking enabled' : 'Tracking disabled',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => HistoryScreen(
              //       onSearchSelected: (query) {
              //         Navigator.pop(context);
              //         _performSearch(query);
              //       },
              //     ),
              //   ),
              // );
               Navigator.push(context, MaterialPageRoute(
    builder: (context) => AdminTestDataPanel(),
  ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ) : null,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            // Search screen
            Column(
              children: [
                _buildHeader(),
                if (_errorMessage != null) _buildErrorMessage(),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
             // Circles screen
            const CirclesListScreen(),
            // Enhanced Profile screen
            const EnhancedProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Circles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
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
    return Column(
      children: [
        if (_selectedImage != null) ...[
          // Show selected image
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Colors.white),
                      onPressed: _clearSelectedImage,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.image, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Image Search',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Search input
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  enabled: _selectedImage == null, // Disable text input when image is selected
                  decoration: InputDecoration(
                    hintText: _selectedImage != null 
                      ? 'Using image search...' 
                      : 'Try "pet friendly cafes" or "romantic dinner"',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  ),
                  onSubmitted: (_) => _performSearch(),
                  onTap: () {
                    setState(() {
                      _isSearchFocused = true;
                    });
                  },
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        _isSearchFocused = false;
                      });
                    }
                  },
                ),
              ),
              // Image picker button
              IconButton(
                icon: Icon(
                  Icons.camera_alt,
                  color: _selectedImage != null 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[600],
                ),
                onPressed: _showImagePickerOptions,
                tooltip: 'Search by image',
              ),
              // Search button
              _isLoading
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.near_me, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Search Radius: ${_searchRadius.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Add visual indicator of radius size
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _searchRadius < 10 
                  ? Colors.green[100] 
                  : _searchRadius < 30 
                    ? Colors.orange[100] 
                    : Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _searchRadius < 10 
                  ? 'Local' 
                  : _searchRadius < 30 
                    ? 'Nearby' 
                    : 'Wide',
                style: TextStyle(
                  fontSize: 12,
                  color: _searchRadius < 10 
                    ? Colors.green[700] 
                    : _searchRadius < 30 
                      ? Colors.orange[700] 
                      : Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.2),
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 6,
          ),
          child: Slider(
            value: _searchRadius,
            min: 1.0,
            max: 50.0,
            divisions: 49,
            label: '${_searchRadius.toStringAsFixed(1)} km',
            onChanged: (value) {
              setState(() {
                _searchRadius = value;
                // If we have search results, show a message that they need to search again
                if (_searchResults.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Tap search to update results with new radius'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              });
            },
          ),
        ),
        // Add scale markers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1 km', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text('25 km', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text('50 km', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
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
    if (_filteredResults.isNotEmpty || (_searchResults.isNotEmpty && _currentFilter.hasActiveFilters)) {
      return _buildSearchResults();
    } else if (_isSearchFocused && _recentSearches.isNotEmpty && !_isLoading) {
      return _buildRecentSearchesOnly();
    } else if (!_isLoading) {
      return _buildMainContent();
    } else {
      return _buildEmptyState();
    }
  }

  Widget _buildSearchResults() {
    final displayResults = _currentFilter.hasActiveFilters ? _filteredResults : _searchResults;
    
    return Column(
      children: [
        if (_currentFilter.hasActiveFilters) _buildActiveFiltersBar(),
        if (displayResults.isEmpty && _currentFilter.hasActiveFilters)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_alt_off,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No places match your filters',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentFilter = SearchFilter();
                        _applyFilters();
                      });
                    },
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: NotificationListener<ScrollNotification>(
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
                itemCount: displayResults.length + (_hasMoreResults ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == displayResults.length) {
                    return _buildLoadMoreButton();
                  }
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: PlaceCard(
                      place: displayResults[index],
                      currentPosition: _locationService.currentPosition!,
                      processImageUrl: _searchService.processImageUrl,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveFiltersBar() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Filtered results',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredResults.length} of ${_searchResults.length} places',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  Widget _buildRecentSearchesOnly() {
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
        // Show only first 3 recent searches
        Expanded(
          child: ListView.builder(
            itemCount: _recentSearches.take(3).length,
            itemBuilder: (context, index) {
              final search = _recentSearches[index];
              return SearchHistoryItem(
                history: search,
                onTap: () {
                  setState(() {
                    _isSearchFocused = false;
                  });
                  _performSearch(search.query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Standalone Vibe Generator Button
          _buildVibeGeneratorSection(),
          
          // Discover Places Section
          _buildDiscoverPlacesSection(),
        ],
      ),
    );
  }
  
  Widget _buildVibeGeneratorSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vibe List Generator',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create personalized itineraries based on your mood and preferences',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showVibeGenerator,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate My Vibe List'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
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
            'Search by text or snap a photo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          // Image search hint
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Take a photo of a place or food to find similar spots nearby!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
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