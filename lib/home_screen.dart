import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/welcome_screen.dart';
import 'dart:convert';
import 'models.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceDetails> _searchResults = [];
  List<SearchHistory> _searchHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  Position? _currentPosition;
  double _searchRadius = 20.0; // Default search radius in km
  String _currentCity = 'Fetching location...';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Replace with your actual Cloud Function URL
  static const String _cloudFunctionUrl = 'https://searchplaces-sk572tzuuq-uc.a.run.app'; // <<<--- IMPORTANT: REPLACE THIS URL
  // static const String _cloudFunctionUrl = 'http://localhost:5001/locale-lens-uslei/us-central1/searchPlaces'; // <<<--- IMPORTANT: REPLACE THIS URL
  static const String _photoProxyUrl = 'https://proxyplacephoto-sk572tzuuq-uc.a.run.app';
  String _userName = 'Loading...'; 

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadSearchHistory();
    _getCurrentLocation();
    _fetchUserName();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? 'User'; // Fetch name or use 'User' as fallback
        });
      } else {
        setState(() {
          _userName = user.displayName ?? 'User'; // Use Google Display Name as fallback
        });
      }
    } else {
       setState(() {
          _userName = 'Guest'; // Display 'Guest' if no user is signed in
       });
    }
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('search_history') ?? [];
    setState(() {
      _searchHistory = historyJson
          .map((json) => SearchHistory.fromJson(jsonDecode(json)))
          .toList()
          .reversed
          .take(10)
          .toList();
    });
  }

  Future<void> _saveToHistory(String query, int resultCount) async {
    final prefs = await SharedPreferences.getInstance();
    final history = SearchHistory(
      query: query,
      timestamp: DateTime.now(),
      resultCount: resultCount,
      latitude: _currentPosition?.latitude ?? 0,
      longitude: _currentPosition?.longitude ?? 0,
    );
    
    final historyJson = prefs.getStringList('search_history') ?? [];
    historyJson.add(jsonEncode(history.toJson()));
    
    // Keep only last 50 searches
    if (historyJson.length > 50) {
      historyJson.removeRange(0, historyJson.length - 50);
    }
    
    await prefs.setStringList('search_history', historyJson);
    await _loadSearchHistory();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _currentPosition = position;
        _errorMessage = null;
      });
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
        _currentCity = placemarks.first.locality ?? 'Unknown City';
      } catch (e) {
        _currentCity = 'Could not get city name';
      }
      
      print('Current location: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location: ${e.toString()}';
      });
    }
  }

  void _performSearch([String? historyQuery]) async {
    final query = historyQuery ?? _searchController.text;
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    if (_currentPosition == null) {
      await _getCurrentLocation();
      if (_currentPosition == null) {
        setState(() {
          _errorMessage = 'Unable to get your location. Please check location settings.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (historyQuery != null) {
        _searchController.text = historyQuery;
      }
    });

    try {
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'textInput': query,
          'inputType': 'text',
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
 'searchRadius': _searchRadius * 1000, // Convert km to meters
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final output = AnalyzeInputAndSuggestLocationsOutput.fromJson(jsonResponse);
        
        // Sort by distance
        final sortedLocations = output.locations..sort((a, b) {
          final distA = Geolocator.distanceBetween(
            _currentPosition!.latitude, _currentPosition!.longitude,
            a.latitude, a.longitude,
          );
          final distB = Geolocator.distanceBetween(
            _currentPosition!.latitude, _currentPosition!.longitude,
            b.latitude, b.longitude,
          );
          return distA.compareTo(distB);
        });

        setState(() {
          _searchResults = sortedLocations;
          _isLoading = false;
        });

        // Save to history
        await _saveToHistory(query, sortedLocations.length);

        // Animate results
        _animationController.forward();
      } else {
        final errorBody = jsonDecode(response.body);
        setState(() {
          _errorMessage = errorBody['error'] ?? 'Unknown error occurred';
          _isLoading = false;
          _searchResults = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
        _searchResults = [];
      });
    }
  }

  String _processImageUrl(String? imageUrl) {
    if (imageUrl == null) return '';
    
    // If it's a Google Places photo URL with a photo reference
    if (imageUrl.contains('photoreference=')) {
      final uri = Uri.parse(imageUrl);
      final photoReference = uri.queryParameters['photoreference'];
      if (photoReference != null) {
        // Use our proxy function
        return '$_photoProxyUrl?photoReference=$photoReference&maxWidth=800';
      }
    }
    
    // For other URLs (Foursquare, etc.), return as is
    return imageUrl;
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openDirections(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    _launchUrl(url);
  }

  Widget _buildPlaceCard(PlaceDetails place, int index) {
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      place.latitude,
      place.longitude,
    ) / 1000; // Convert to km

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          elevation: 0,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                if (place.imageUrls != null && place.imageUrls!.isNotEmpty)
                  Stack(
                    children: [
                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          itemCount: place.imageUrls!.length,
                          itemBuilder: (context, imageIndex) {
                            final imageUrl = _processImageUrl(place.imageUrls![imageIndex]);
                            return ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, 
                                        size: 50, 
                                        color: Colors.grey[400]
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image unavailable',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Image indicators
                      if (place.imageUrls!.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              place.imageUrls!.length,
                              (dotIndex) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor.withOpacity(0.7),
                          Theme.of(context).primaryColor,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.place_outlined,
                        size: 80,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  place.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  place.type,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (place.dataSource != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                place.dataSource!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Description
                      Text(
                        place.description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Info chips
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          // Rating
                          if (place.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, 
                                    size: 18, 
                                    color: Colors.amber
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    place.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Price level
                          if (place.priceLevel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                place.priceLevel!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          
                          // Distance
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me_rounded, 
                                  size: 16, 
                                  color: Colors.blue
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${distance.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Tags
                      if (place.tags != null && place.tags!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: place.tags!.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                      
                      // Actions
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openDirections(
                                place.latitude,
                                place.longitude,
                              ),
                              icon: const Icon(Icons.directions, size: 18),
                              label: const Text('Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (place.websiteUrl != null)
                            IconButton(
                              onPressed: () => _launchUrl(place.websiteUrl!),
                              icon: const Icon(Icons.language),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          if (place.phoneNumber != null)
                            IconButton(
                              onPressed: () => _makePhoneCall(place.phoneNumber!),
                              icon: const Icon(Icons.phone),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(SearchHistory history) {
    final timeAgo = _formatTimeAgo(history.timestamp);
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.history,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        history.query,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '$timeAgo • ${history.resultCount} results',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(Icons.north_west, size: 16),
      onTap: () => _performSearch(history.query),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
        appBar: AppBar( // Add this AppBar
        title: Text('Wandr'), // You can keep the app title here or in the header as before
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigate back to the WelcomeScreen and remove all previous routes
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => WelcomeScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), // Adjust padding as AppBar adds space
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
            children: [
               Row(
                children: [
                  Expanded( // Use Expanded to allow the text to take available space
                    child: Text(
                      'Welcome, $_userName', // Display fetched user name
                      style: TextStyle(
                        fontSize: 24, // Adjust font size as needed
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: -1,
                      ),
                       overflow: TextOverflow.ellipsis, // Prevent overflow
                    ),
                  ),
                   const SizedBox(width: 8),
                   Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
               const SizedBox(height: 4),
              if (_currentPosition != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(_currentCity,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
               const SizedBox(height: 20),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Try \"pet friendly cafes\" or \"romantic dinner\"',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                    ),
                    suffixIcon: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
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
              ),
             const SizedBox(height: 12),
             // Distance Slider
              Row(
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
                    divisions: 49, // For steps of 1 km
                    label: _searchRadius.toStringAsFixed(0),
                    onChanged: (double value) {
                      setState(() {
                        _searchRadius = value;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                ),
               ],
              ),
              const SizedBox(height: 20), // Add spacing below slider
            ],
          ),
        ),
        // ... rest of your body content (error message, results/history)
            
            // Error message
            if (_errorMessage != null)
              Container(
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
              ),
            
            // Results or History
            Expanded(
              child: _searchResults.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildPlaceCard(_searchResults[index], index);
                      },
                    )
                  : _searchHistory.isNotEmpty && !_isLoading
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                              child: Text(
                                'Recent Searches',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _searchHistory.length,
                                itemBuilder: (context, index) {
                                  return _buildHistoryItem(_searchHistory[index]);
                                },
                              ),
                            ),
                          ],
                        )
                      : Center(
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
                              const SizedBox(height: 32),
                              if (_currentPosition == null)
                                ElevatedButton.icon(
                                  onPressed: _getCurrentLocation,
                                  icon: const Icon(Icons.location_on),
                                  label: const Text('Enable Location'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// Search History Model
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