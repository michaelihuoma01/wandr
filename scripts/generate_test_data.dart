import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// Sample data for generation
class TestDataGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Sample user IDs (you should replace these with actual user IDs from your system)
  final List<String> _userIds = [
    'user_1_sample',
    'user_2_sample', 
    'user_3_sample',
    'user_4_sample',
    'user_5_sample',
  ];

  // Sample places data
  final List<Map<String, dynamic>> _samplePlaces = [
    {
      'name': 'Sunset Rooftop Bar',
      'description': 'Amazing rooftop bar with panoramic city views and craft cocktails',
      'latitude': 40.7589,
      'longitude': -73.9851,
      'type': 'bar',
      'rating': 4.6,
      'priceLevel': '\$\$\$',
      'imageUrls': ['https://images.unsplash.com/photo-1574391884720-bfce7feac425'],
      'tags': ['rooftop', 'cocktails', 'views', 'romantic'],
    },
    {
      'name': 'Corner Bistro',
      'description': 'Cozy French bistro with authentic cuisine and intimate atmosphere',
      'latitude': 40.7505,
      'longitude': -73.9934,
      'type': 'restaurant',
      'rating': 4.8,
      'priceLevel': '\$\$\$\$',
      'imageUrls': ['https://images.unsplash.com/photo-1517248135467-4c7edcad34c4'],
      'tags': ['french', 'fine dining', 'romantic', 'intimate'],
    },
    {
      'name': 'Central Park',
      'description': 'Iconic urban park perfect for walking, picnics, and outdoor activities',
      'latitude': 40.7829,
      'longitude': -73.9654,
      'type': 'park',
      'rating': 4.9,
      'priceLevel': 'Free',
      'imageUrls': ['https://images.unsplash.com/photo-1572986945473-b2bc53b5bdcd'],
      'tags': ['nature', 'outdoors', 'walking', 'scenic'],
    },
    {
      'name': 'Blue Note Jazz Club',
      'description': 'Historic jazz club featuring world-class musicians and intimate performances',
      'latitude': 40.7295,
      'longitude': -74.0009,
      'type': 'entertainment',
      'rating': 4.7,
      'priceLevel': '\$\$\$',
      'imageUrls': ['https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f'],
      'tags': ['jazz', 'music', 'nightlife', 'entertainment'],
    },
    {
      'name': 'Brooklyn Bridge',
      'description': 'Iconic suspension bridge with breathtaking views and photo opportunities',
      'latitude': 40.7061,
      'longitude': -73.9969,
      'type': 'landmark',
      'rating': 4.8,
      'priceLevel': 'Free',
      'imageUrls': ['https://images.unsplash.com/photo-1500522144261-ea64433bbe27'],
      'tags': ['landmark', 'views', 'walking', 'photos'],
    },
    {
      'name': 'Artisan Coffee House',
      'description': 'Third-wave coffee shop with locally roasted beans and cozy atmosphere',
      'latitude': 40.7282,
      'longitude': -73.9942,
      'type': 'cafe',
      'rating': 4.5,
      'priceLevel': '\$\$',
      'imageUrls': ['https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb'],
      'tags': ['coffee', 'cozy', 'work-friendly', 'local'],
    },
    {
      'name': 'Metropolitan Museum',
      'description': 'World-renowned art museum with extensive collections and exhibitions',
      'latitude': 40.7794,
      'longitude': -73.9632,
      'type': 'museum',
      'rating': 4.9,
      'priceLevel': '\$\$',
      'imageUrls': ['https://images.unsplash.com/photo-1566127982909-9663b0b87edb'],
      'tags': ['art', 'culture', 'museum', 'educational'],
    },
    {
      'name': 'Speakeasy Lounge',
      'description': 'Hidden cocktail bar with prohibition-era ambiance and craft drinks',
      'latitude': 40.7400,
      'longitude': -73.9900,
      'type': 'bar',
      'rating': 4.4,
      'priceLevel': '\$\$\$',
      'imageUrls': ['https://images.unsplash.com/photo-1572457881717-3a2b53c1c194'],
      'tags': ['speakeasy', 'cocktails', 'hidden', 'vintage'],
    },
  ];

  // Sample circle names and descriptions
  final List<Map<String, String>> _sampleCircles = [
    {
      'name': 'NYC Foodies',
      'description': 'Exploring the best restaurants and hidden gems in New York City',
    },
    {
      'name': 'Adventure Seekers',
      'description': 'Always looking for the next exciting experience and outdoor adventure',
    },
    {
      'name': 'Art & Culture Lovers',
      'description': 'Passionate about museums, galleries, and cultural experiences',
    },
    {
      'name': 'Night Owls',
      'description': 'The best spots for nightlife, bars, and late-night entertainment',
    },
    {
      'name': 'Coffee Enthusiasts',
      'description': 'Discovering amazing coffee shops and cafes around the city',
    },
    {
      'name': 'Weekend Warriors',
      'description': 'Making the most of weekends with fun activities and new places',
    },
  ];

  // Sample board ideas
  final List<Map<String, dynamic>> _sampleBoards = [
    {
      'name': 'Perfect Date Night',
      'description': 'Romantic spots for an unforgettable evening',
      'type': 'normal',
      'tags': ['romantic', 'date', 'evening'],
    },
    {
      'name': 'Weekend in NYC',
      'description': 'Complete itinerary for a perfect weekend getaway',
      'type': 'itinerary',
      'tags': ['weekend', 'itinerary', 'nyc'],
    },
    {
      'name': 'Hidden Gems',
      'description': 'Secret spots only locals know about',
      'type': 'normal',
      'tags': ['hidden', 'local', 'unique'],
    },
    {
      'name': 'Birthday Celebration',
      'description': 'Amazing venues for birthday parties and celebrations',
      'type': 'itinerary',
      'tags': ['birthday', 'celebration', 'party'],
    },
    {
      'name': 'Coffee Crawl',
      'description': 'Best coffee shops to visit in one day',
      'type': 'normal',
      'tags': ['coffee', 'crawl', 'morning'],
    },
  ];

  Future<void> generateTestData() async {
    print('🚀 Starting test data generation...');
    
    try {
      // Generate circles
      await _generateCircles();
      
      // Generate boards
      await _generateBoards();
      
      // Generate check-ins
      await _generateCheckIns();
      
      print('✅ Test data generation completed successfully!');
      
    } catch (e) {
      print('❌ Error generating test data: $e');
    }
  }

  Future<void> _generateCircles() async {
    print('📍 Generating circles...');
    
    for (int i = 0; i < _sampleCircles.length; i++) {
      final circle = _sampleCircles[i];
      final circleId = 'test_circle_${i + 1}';
      
      // Random member count between 3-15
      final memberCount = 3 + _random.nextInt(13);
      final members = _userIds.take(memberCount).toList();
      
      final circleData = {
        'id': circleId,
        'name': circle['name'],
        'description': circle['description'],
        'createdBy': _userIds[_random.nextInt(_userIds.length)],
        'members': members,
        'memberCount': memberCount,
        'isPublic': _random.nextBool(),
        'createdAt': _randomRecentTimestamp(),
        'updatedAt': _randomRecentTimestamp(),
        'tags': _generateRandomTags(),
        'activityCount': _random.nextInt(50) + 10,
      };
      
      await _firestore.collection('circles').doc(circleId).set(circleData);
      print('  ✓ Created circle: ${circle['name']}');
    }
  }

  Future<void> _generateBoards() async {
    print('📋 Generating boards...');
    
    for (int i = 0; i < _sampleBoards.length; i++) {
      final board = _sampleBoards[i];
      final boardId = 'test_board_${i + 1}';
      
      // Select random places for this board
      final boardPlaces = _selectRandomPlaces(2 + _random.nextInt(4));
      
      List<Map<String, dynamic>>? itineraryStops;
      if (board['type'] == 'itinerary') {
        itineraryStops = _generateItineraryStops(boardPlaces);
      }
      
      final boardData = {
        'id': boardId,
        'name': board['name'],
        'description': board['description'],
        'createdBy': _userIds[_random.nextInt(_userIds.length)],
        'createdAt': _randomRecentTimestamp(),
        'updatedAt': _randomRecentTimestamp(),
        'isPublic': _random.nextBool(),
        'type': board['type'],
        'tags': board['tags'],
        'places': boardPlaces,
        'itineraryStops': itineraryStops,
        'likeCount': _random.nextInt(100),
        'saveCount': _random.nextInt(50),
      };
      
      await _firestore.collection('boards').doc(boardId).set(boardData);
      print('  ✓ Created board: ${board['name']}');
    }
  }

  Future<void> _generateCheckIns() async {
    print('📍 Generating check-ins...');
    
    int checkInCount = 0;
    
    // Generate 20-30 random check-ins
    for (int i = 0; i < 25; i++) {
      final checkInId = 'test_checkin_${i + 1}';
      final place = _samplePlaces[_random.nextInt(_samplePlaces.length)];
      final userId = _userIds[_random.nextInt(_userIds.length)];
      
      final checkInData = {
        'id': checkInId,
        'userId': userId,
        'placeId': 'place_${place['name'].toLowerCase().replaceAll(' ', '_')}',
        'placeName': place['name'],
        'placeType': place['type'],
        'latitude': place['latitude'],
        'longitude': place['longitude'],
        'timestamp': _randomRecentTimestamp(),
        'rating': _random.nextDouble() * 2 + 3, // Rating between 3-5
        'review': _generateRandomReview(place['name'] as String),
        'photos': _random.nextBool() ? [place['imageUrls']![0]] : [],
        'tags': _generateRandomTags(),
        'isPublic': _random.nextBool(),
        'likeCount': _random.nextInt(20),
        'commentCount': _random.nextInt(10),
      };
      
      await _firestore.collection('checkins').doc(checkInId).set(checkInData);
      checkInCount++;
    }
    
    print('  ✓ Created $checkInCount check-ins');
  }

  List<Map<String, dynamic>> _selectRandomPlaces(int count) {
    final selectedPlaces = <Map<String, dynamic>>[];
    final availablePlaces = List<Map<String, dynamic>>.from(_samplePlaces);
    
    for (int i = 0; i < count && availablePlaces.isNotEmpty; i++) {
      final index = _random.nextInt(availablePlaces.length);
      selectedPlaces.add(availablePlaces.removeAt(index));
    }
    
    return selectedPlaces;
  }

  List<Map<String, dynamic>> _generateItineraryStops(List<Map<String, dynamic>> places) {
    final timeSlots = ['morning', 'afternoon', 'evening', 'night'];
    final categories = ['start', 'main', 'dining', 'finale'];
    
    return places.asMap().entries.map((entry) {
      final index = entry.key;
      final place = entry.value;
      
      return {
        'place': place,
        'timeSlot': timeSlots[index % timeSlots.length],
        'category': categories[index % categories.length],
        'order': index + 1,
        'description': _generateStopDescription(place['type'] as String),
      };
    }).toList();
  }

  String _generateStopDescription(String placeType) {
    switch (placeType) {
      case 'bar':
        return 'Perfect spot for drinks and conversation';
      case 'restaurant':
        return 'Exceptional dining experience awaits';
      case 'park':
        return 'Enjoy nature and outdoor activities';
      case 'museum':
        return 'Immerse yourself in art and culture';
      case 'cafe':
        return 'Great coffee and cozy atmosphere';
      default:
        return 'Must-visit destination for your itinerary';
    }
  }

  List<String> _generateRandomTags() {
    final allTags = [
      'romantic', 'casual', 'upscale', 'hidden', 'popular', 'local',
      'outdoor', 'indoor', 'family', 'date', 'group', 'solo',
      'morning', 'afternoon', 'evening', 'night', 'weekend',
      'food', 'drinks', 'coffee', 'art', 'music', 'nature'
    ];
    
    final tagCount = 2 + _random.nextInt(4);
    final selectedTags = <String>[];
    
    for (int i = 0; i < tagCount; i++) {
      final tag = allTags[_random.nextInt(allTags.length)];
      if (!selectedTags.contains(tag)) {
        selectedTags.add(tag);
      }
    }
    
    return selectedTags;
  }

  String _generateRandomReview(String placeName) {
    final reviews = [
      'Amazing experience at $placeName! Highly recommend.',
      'Great atmosphere and service. Will definitely come back!',
      'Perfect spot for a special occasion. Loved everything about it.',
      'Hidden gem! So glad I discovered this place.',
      'Excellent quality and attention to detail. Five stars!',
      'Beautiful location with incredible views.',
      'Outstanding experience from start to finish.',
      'Cozy atmosphere and friendly staff. Perfect for date night.',
    ];
    
    return reviews[_random.nextInt(reviews.length)];
  }

  Timestamp _randomRecentTimestamp() {
    // Generate timestamp within last 30 days
    final now = DateTime.now();
    final daysAgo = _random.nextInt(30);
    final hoursAgo = _random.nextInt(24);
    final minutesAgo = _random.nextInt(60);
    
    final timestamp = now.subtract(Duration(
      days: daysAgo,
      hours: hoursAgo,
      minutes: minutesAgo,
    ));
    
    return Timestamp.fromDate(timestamp);
  }
}

Future<void> main() async {
  print('🔥 Initializing Firebase...');
  
  // Initialize Firebase (you may need to configure this for your project)
  await Firebase.initializeApp();
  
  final generator = TestDataGenerator();
  await generator.generateTestData();
  
  print('🎉 All done! Your app now has sample data to work with.');
  exit(0);
}