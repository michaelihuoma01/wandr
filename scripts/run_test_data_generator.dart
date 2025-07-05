import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() async {
  print('🚀 Generating test data for Wandr app...');
  
  final generator = QuickTestDataGenerator();
  
  // Generate sample data files
  await generator.generateCirclesData();
  await generator.generateBoardsData();
  await generator.generateCheckInsData();
  await generator.generateUsersData();
  
  print('✅ Test data generation completed!');
  print('📁 Generated files in: scripts/test_data/');
  print('');
  print('📋 Next steps:');
  print('1. Import the JSON files into Firestore');
  print('2. Or use the data to populate your app manually');
  print('3. Update user IDs to match your actual users');
}

class QuickTestDataGenerator {
  final Random _random = Random();
  
  // Create test_data directory
  Future<void> _ensureDirectory() async {
    final dir = Directory('scripts/test_data');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> generateUsersData() async {
    await _ensureDirectory();
    
    final users = [
      {
        'uid': 'user_alex_123',
        'email': 'alex@example.com',
        'displayName': 'Alex Chen',
        'photoURL': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
        'bio': 'Food enthusiast and adventure seeker',
        'location': 'New York, NY',
        'joinedAt': DateTime.now().subtract(Duration(days: 120)).toIso8601String(),
        'isPublic': true,
      },
      {
        'uid': 'user_sara_456',
        'email': 'sara@example.com',
        'displayName': 'Sara Johnson',
        'photoURL': 'https://images.unsplash.com/photo-1494790108755-2616b612b786',
        'bio': 'Art lover and coffee connoisseur',
        'location': 'Brooklyn, NY',
        'joinedAt': DateTime.now().subtract(Duration(days: 95)).toIso8601String(),
        'isPublic': true,
      },
      {
        'uid': 'user_mike_789',
        'email': 'mike@example.com',
        'displayName': 'Mike Rodriguez',
        'photoURL': 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
        'bio': 'Night owl exploring the city\'s nightlife',
        'location': 'Manhattan, NY',
        'joinedAt': DateTime.now().subtract(Duration(days: 67)).toIso8601String(),
        'isPublic': false,
      },
      {
        'uid': 'user_emma_012',
        'email': 'emma@example.com',
        'displayName': 'Emma Davis',
        'photoURL': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
        'bio': 'Weekend warrior and outdoor enthusiast',
        'location': 'Queens, NY',
        'joinedAt': DateTime.now().subtract(Duration(days: 45)).toIso8601String(),
        'isPublic': true,
      },
      {
        'uid': 'user_james_345',
        'email': 'james@example.com',
        'displayName': 'James Wilson',
        'photoURL': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        'bio': 'Cultural explorer and museum enthusiast',
        'location': 'Bronx, NY',
        'joinedAt': DateTime.now().subtract(Duration(days: 78)).toIso8601String(),
        'isPublic': true,
      },
    ];

    final file = File('scripts/test_data/users.json');
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(users));
    print('  ✓ Generated users.json (${users.length} users)');
  }

  Future<void> generateCirclesData() async {
    await _ensureDirectory();
    
    final circles = [
      {
        'id': 'circle_foodies_nyc',
        'name': 'NYC Foodies',
        'description': 'Exploring the best restaurants and hidden culinary gems across all five boroughs',
        'createdBy': 'user_alex_123',
        'members': ['user_alex_123', 'user_sara_456', 'user_mike_789', 'user_emma_012'],
        'memberCount': 4,
        'isPublic': true,
        'createdAt': _randomRecentDate(30),
        'updatedAt': _randomRecentDate(7),
        'tags': ['food', 'restaurants', 'nyc', 'dining'],
        'activityCount': 24,
        'coverPhoto': 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
      },
      {
        'id': 'circle_adventure_seekers',
        'name': 'Adventure Seekers',
        'description': 'Always ready for the next exciting outdoor experience and urban exploration',
        'createdBy': 'user_emma_012',
        'members': ['user_emma_012', 'user_james_345', 'user_alex_123'],
        'memberCount': 3,
        'isPublic': true,
        'createdAt': _randomRecentDate(45),
        'updatedAt': _randomRecentDate(3),
        'tags': ['adventure', 'outdoors', 'exploration', 'active'],
        'activityCount': 18,
        'coverPhoto': 'https://images.unsplash.com/photo-1551632811-561732d1e306',
      },
      {
        'id': 'circle_art_culture',
        'name': 'Art & Culture Lovers',
        'description': 'Passionate about museums, galleries, theater, and all things cultural',
        'createdBy': 'user_sara_456',
        'members': ['user_sara_456', 'user_james_345', 'user_mike_789'],
        'memberCount': 3,
        'isPublic': false,
        'createdAt': _randomRecentDate(25),
        'updatedAt': _randomRecentDate(5),
        'tags': ['art', 'culture', 'museums', 'galleries'],
        'activityCount': 15,
        'coverPhoto': 'https://images.unsplash.com/photo-1541961017774-22349e4a1262',
      },
      {
        'id': 'circle_night_owls',
        'name': 'Night Owls',
        'description': 'Discovering the best nightlife, bars, and late-night entertainment venues',
        'createdBy': 'user_mike_789',
        'members': ['user_mike_789', 'user_alex_123', 'user_sara_456', 'user_emma_012', 'user_james_345'],
        'memberCount': 5,
        'isPublic': true,
        'createdAt': _randomRecentDate(35),
        'updatedAt': _randomRecentDate(2),
        'tags': ['nightlife', 'bars', 'entertainment', 'late-night'],
        'activityCount': 31,
        'coverPhoto': 'https://images.unsplash.com/photo-1566737236500-c8ac43014a8e',
      },
      {
        'id': 'circle_coffee_enthusiasts',
        'name': 'Coffee Enthusiasts',
        'description': 'On a mission to find the perfect cup at the city\'s best coffee shops',
        'createdBy': 'user_sara_456',
        'members': ['user_sara_456', 'user_james_345'],
        'memberCount': 2,
        'isPublic': true,
        'createdAt': _randomRecentDate(20),
        'updatedAt': _randomRecentDate(1),
        'tags': ['coffee', 'cafes', 'morning', 'local'],
        'activityCount': 12,
        'coverPhoto': 'https://images.unsplash.com/photo-1445116572660-236099ec97a0',
      },
    ];

    final file = File('scripts/test_data/circles.json');
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(circles));
    print('  ✓ Generated circles.json (${circles.length} circles)');
  }

  Future<void> generateBoardsData() async {
    await _ensureDirectory();
    
    final boards = [
      {
        'id': 'board_perfect_date_night',
        'name': 'Perfect Date Night in NYC',
        'description': 'A romantic evening itinerary with stunning views, amazing food, and intimate vibes',
        'createdBy': 'user_alex_123',
        'createdAt': _randomRecentDate(15),
        'updatedAt': _randomRecentDate(8),
        'isPublic': true,
        'type': 'itinerary',
        'tags': ['romantic', 'date', 'evening', 'nyc'],
        'coverPhotoUrl': 'https://images.unsplash.com/photo-1519741497674-611481863552',
        'likeCount': 47,
        'saveCount': 23,
        'enhancedCategories': [
          {
            'categoryTitle': 'With a View',
            'categoryDescription': 'Sunset rooftop bars and scenic spots to set the mood',
            'timeSlot': 'sunset',
            'order': 1,
            'places': [
              _createSamplePlace('Sunset Rooftop Bar', 'Panoramic city views with craft cocktails', 40.7589, -73.9851, 'bar', 4.6),
              _createSamplePlace('Edge Observation Deck', 'Highest outdoor sky deck in the Western Hemisphere', 40.7576, -74.0014, 'attraction', 4.8),
              _createSamplePlace('Brooklyn Bridge Park', 'Waterfront park with Manhattan skyline views', 40.7023, -73.9976, 'park', 4.7),
            ],
          },
          {
            'categoryTitle': 'Fine Dining',
            'categoryDescription': 'Exquisite restaurants for an unforgettable dinner',
            'timeSlot': 'dinner',
            'order': 2,
            'places': [
              _createSamplePlace('Le Bernardin', 'Michelin-starred French seafood restaurant', 40.7614, -73.9776, 'restaurant', 4.9),
              _createSamplePlace('Corner Bistro', 'Intimate French bistro with authentic cuisine', 40.7505, -73.9934, 'restaurant', 4.8),
              _createSamplePlace('The Modern', 'Contemporary American cuisine with MoMA views', 40.7616, -73.9776, 'restaurant', 4.7),
            ],
          },
          {
            'categoryTitle': 'Party All Night',
            'categoryDescription': 'Vibrant nightlife spots to dance the night away',
            'timeSlot': 'night',
            'order': 3,
            'places': [
              _createSamplePlace('Blue Note Jazz Club', 'Legendary jazz club with intimate performances', 40.7295, -74.0009, 'entertainment', 4.7),
              _createSamplePlace('Speakeasy Lounge', 'Hidden cocktail bar with prohibition-era charm', 40.7400, -73.9900, 'bar', 4.4),
              _createSamplePlace('Rooftop Nightclub', 'Open-air dancing under the stars', 40.7580, -73.9855, 'nightclub', 4.5),
            ],
          },
        ],
      },
      {
        'id': 'board_weekend_warriors',
        'name': 'Weekend Adventure Guide',
        'description': 'Action-packed weekend itinerary for thrill-seekers and outdoor enthusiasts',
        'createdBy': 'user_emma_012',
        'createdAt': _randomRecentDate(12),
        'updatedAt': _randomRecentDate(5),
        'isPublic': true,
        'type': 'itinerary',
        'tags': ['adventure', 'weekend', 'outdoor', 'active'],
        'coverPhotoUrl': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4',
        'likeCount': 38,
        'saveCount': 19,
        'enhancedCategories': [
          {
            'categoryTitle': 'Start Strong',
            'categoryDescription': 'Energizing morning activities to kick off your adventure',
            'timeSlot': 'morning',
            'order': 1,
            'places': [
              _createSamplePlace('Central Park', 'Iconic urban park perfect for morning runs and walks', 40.7829, -73.9654, 'park', 4.9),
              _createSamplePlace('Brooklyn Bridge', 'Historic bridge walk with breathtaking views', 40.7061, -73.9969, 'landmark', 4.8),
              _createSamplePlace('High Line', 'Elevated park with unique urban garden experience', 40.7480, -74.0048, 'park', 4.6),
            ],
          },
          {
            'categoryTitle': 'Main Event',
            'categoryDescription': 'Exciting activities and unique experiences',
            'timeSlot': 'afternoon',
            'order': 2,
            'places': [
              _createSamplePlace('Rock Climbing Gym', 'Indoor climbing with city views', 40.7505, -73.9870, 'fitness', 4.5),
              _createSamplePlace('Kayak Rental', 'Paddle around Manhattan waterways', 40.7589, -73.9851, 'outdoor', 4.4),
              _createSamplePlace('Bike Tour', 'Guided cycling tour through NYC boroughs', 40.7282, -73.9942, 'tour', 4.6),
            ],
          },
          {
            'categoryTitle': 'Victory Lap',
            'categoryDescription': 'Celebrate your accomplishments with great food and drinks',
            'timeSlot': 'evening',
            'order': 3,
            'places': [
              _createSamplePlace('Sports Bar & Grill', 'Casual dining with game day atmosphere', 40.7400, -73.9900, 'restaurant', 4.3),
              _createSamplePlace('Brewery Tour', 'Local craft beer tasting experience', 40.7294, -73.9965, 'brewery', 4.5),
              _createSamplePlace('Victory Garden', 'Rooftop bar celebrating outdoor adventures', 40.7576, -73.9857, 'bar', 4.4),
            ],
          },
        ],
      },
      {
        'id': 'board_hidden_gems',
        'name': 'NYC Hidden Gems',
        'description': 'Secret spots and local favorites that most tourists never discover',
        'createdBy': 'user_sara_456',
        'createdAt': _randomRecentDate(20),
        'updatedAt': _randomRecentDate(10),
        'isPublic': false,
        'type': 'normal',
        'tags': ['hidden', 'local', 'unique', 'secret'],
        'coverPhotoUrl': 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9',
        'likeCount': 62,
        'saveCount': 34,
        'places': [
          _createSamplePlace('Secret Garden', 'Hidden courtyard cafe known only to locals', 40.7282, -73.9942, 'cafe', 4.7),
          _createSamplePlace('Underground Speakeasy', 'Unmarked bar in a basement below a pizza shop', 40.7295, -74.0009, 'bar', 4.8),
          _createSamplePlace('Artisan Workshop', 'Working artist studio that doubles as gallery', 40.7505, -73.9934, 'gallery', 4.6),
          _createSamplePlace('Pocket Park', 'Tiny green space between buildings most people miss', 40.7589, -73.9851, 'park', 4.5),
        ],
      },
      {
        'id': 'board_coffee_crawl',
        'name': 'Ultimate Coffee Crawl',
        'description': 'The best third-wave coffee shops for a perfect caffeine tour',
        'createdBy': 'user_james_345',
        'createdAt': _randomRecentDate(8),
        'updatedAt': _randomRecentDate(3),
        'isPublic': true,
        'type': 'normal',
        'tags': ['coffee', 'morning', 'crawl', 'local'],
        'coverPhotoUrl': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb',
        'likeCount': 29,
        'saveCount': 18,
        'places': [
          _createSamplePlace('Artisan Coffee House', 'Third-wave coffee with locally roasted beans', 40.7282, -73.9942, 'cafe', 4.5),
          _createSamplePlace('Steam & Bean', 'Specialty espresso bar with minimal decor', 40.7400, -73.9900, 'cafe', 4.6),
          _createSamplePlace('Morning Ritual', 'Pour-over specialists with single-origin beans', 40.7505, -73.9934, 'cafe', 4.7),
          _createSamplePlace('Caffeine Culture', 'Modern coffee lab with innovative brewing methods', 40.7589, -73.9851, 'cafe', 4.4),
        ],
      },
    ];

    final file = File('scripts/test_data/boards.json');
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(boards));
    print('  ✓ Generated boards.json (${boards.length} boards)');
  }

  Future<void> generateCheckInsData() async {
    await _ensureDirectory();
    
    final checkIns = <Map<String, dynamic>>[];
    final userIds = ['user_alex_123', 'user_sara_456', 'user_mike_789', 'user_emma_012', 'user_james_345'];
    
    // Generate 50 check-ins
    for (int i = 0; i < 50; i++) {
      final userId = userIds[_random.nextInt(userIds.length)];
      final place = _getRandomPlace();
      
      checkIns.add({
        'id': 'checkin_${i.toString().padLeft(3, '0')}',
        'userId': userId,
        'placeId': 'place_${place['name'].toLowerCase().replaceAll(' ', '_')}',
        'placeName': place['name'],
        'placeType': place['type'],
        'latitude': place['latitude'],
        'longitude': place['longitude'],
        'timestamp': _randomRecentDate(_random.nextInt(30) + 1),
        'rating': (3.0 + _random.nextDouble() * 2.0), // 3.0 to 5.0
        'review': _generateRandomReview(place['name']),
        'photos': _random.nextBool() ? [place['imageUrl']] : [],
        'tags': _generateRandomTags(),
        'isPublic': _random.nextBool(),
        'likeCount': _random.nextInt(25),
        'commentCount': _random.nextInt(8),
        'weather': _getRandomWeather(),
        'mood': _getRandomMood(),
      });
    }

    final file = File('scripts/test_data/checkins.json');
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(checkIns));
    print('  ✓ Generated checkins.json (${checkIns.length} check-ins)');
  }

  Map<String, dynamic> _createSamplePlace(String name, String description, double lat, double lng, String type, double rating) {
    return {
      'name': name,
      'description': description,
      'latitude': lat,
      'longitude': lng,
      'type': type,
      'rating': rating,
      'priceLevel': _getRandomPriceLevel(),
      'imageUrls': [_getRandomImageUrl(type)],
      'tags': _generateRandomTags(),
      'phoneNumber': _generatePhoneNumber(),
      'websiteUrl': 'https://example.com/${name.toLowerCase().replaceAll(' ', '')}',
    };
  }

  Map<String, dynamic> _getRandomPlace() {
    final places = [
      {'name': 'Sunset Rooftop Bar', 'type': 'bar', 'latitude': 40.7589, 'longitude': -73.9851, 'imageUrl': 'https://images.unsplash.com/photo-1574391884720-bfce7feac425'},
      {'name': 'Corner Bistro', 'type': 'restaurant', 'latitude': 40.7505, 'longitude': -73.9934, 'imageUrl': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4'},
      {'name': 'Central Park', 'type': 'park', 'latitude': 40.7829, 'longitude': -73.9654, 'imageUrl': 'https://images.unsplash.com/photo-1572986945473-b2bc53b5bdcd'},
      {'name': 'Blue Note Jazz Club', 'type': 'entertainment', 'latitude': 40.7295, 'longitude': -74.0009, 'imageUrl': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f'},
      {'name': 'Artisan Coffee House', 'type': 'cafe', 'latitude': 40.7282, 'longitude': -73.9942, 'imageUrl': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb'},
      {'name': 'Metropolitan Museum', 'type': 'museum', 'latitude': 40.7794, 'longitude': -73.9632, 'imageUrl': 'https://images.unsplash.com/photo-1566127982909-9663b0b87edb'},
    ];
    
    return places[_random.nextInt(places.length)];
  }

  String _getRandomImageUrl(String type) {
    final imageUrls = {
      'bar': 'https://images.unsplash.com/photo-1574391884720-bfce7feac425',
      'restaurant': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      'cafe': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb',
      'park': 'https://images.unsplash.com/photo-1572986945473-b2bc53b5bdcd',
      'museum': 'https://images.unsplash.com/photo-1566127982909-9663b0b87edb',
      'entertainment': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f',
    };
    
    return imageUrls[type] ?? 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4';
  }

  String _getRandomPriceLevel() {
    final levels = ['\$', '\$\$', '\$\$\$', '\$\$\$\$'];
    return levels[_random.nextInt(levels.length)];
  }

  String _generatePhoneNumber() {
    return '+1 (${_random.nextInt(900) + 100}) ${_random.nextInt(900) + 100}-${_random.nextInt(9000) + 1000}';
  }

  List<String> _generateRandomTags() {
    final allTags = [
      'romantic', 'casual', 'upscale', 'hidden', 'popular', 'local',
      'outdoor', 'indoor', 'family', 'date', 'group', 'solo',
      'morning', 'afternoon', 'evening', 'night', 'weekend',
      'food', 'drinks', 'coffee', 'art', 'music', 'nature'
    ];
    
    final count = 2 + _random.nextInt(4);
    final selected = <String>[];
    
    while (selected.length < count) {
      final tag = allTags[_random.nextInt(allTags.length)];
      if (!selected.contains(tag)) {
        selected.add(tag);
      }
    }
    
    return selected;
  }

  String _generateRandomReview(String placeName) {
    final reviews = [
      'Amazing experience at $placeName! The atmosphere was perfect and service was top-notch.',
      'Absolutely loved this place! Will definitely be coming back soon.',
      'Perfect spot for a special occasion. Everything exceeded my expectations.',
      'Hidden gem alert! So glad I discovered $placeName.',
      'Outstanding quality and attention to detail. Highly recommend!',
      'Beautiful location with incredible vibes. A must-visit!',
      'Exceptional experience from start to finish. Five stars!',
      'Cozy atmosphere and friendly staff. Perfect for date night.',
      'Great food, great people, great time! What more could you ask for?',
      'This place has such a unique character. Loved every minute here.',
    ];
    
    return reviews[_random.nextInt(reviews.length)];
  }

  String _getRandomWeather() {
    final weather = ['sunny', 'cloudy', 'rainy', 'clear', 'partly_cloudy'];
    return weather[_random.nextInt(weather.length)];
  }

  String _getRandomMood() {
    final moods = ['excited', 'relaxed', 'adventurous', 'romantic', 'energetic', 'peaceful', 'social', 'inspired'];
    return moods[_random.nextInt(moods.length)];
  }

  String _randomRecentDate(int maxDaysAgo) {
    final now = DateTime.now();
    final daysAgo = _random.nextInt(maxDaysAgo);
    final hoursAgo = _random.nextInt(24);
    final minutesAgo = _random.nextInt(60);
    
    final date = now.subtract(Duration(
      days: daysAgo,
      hours: hoursAgo,
      minutes: minutesAgo,
    ));
    
    return date.toIso8601String();
  }
}