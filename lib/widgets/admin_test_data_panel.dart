import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/models/models.dart';

class AdminTestDataPanel extends StatefulWidget {
  const AdminTestDataPanel({super.key});

  @override
  State<AdminTestDataPanel> createState() => _AdminTestDataPanelState();
}

class _AdminTestDataPanelState extends State<AdminTestDataPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final Random _random = Random();
  
  bool _isGenerating = false;
  String _statusMessage = '';
  
  // Controllers for quantity inputs
  final TextEditingController _circleCountController = TextEditingController(text: '3');
  final TextEditingController _boardCountController = TextEditingController(text: '5');
  final TextEditingController _visitCountController = TextEditingController(text: '10');
  final TextEditingController _userCountController = TextEditingController(text: '1');

  // Sample data for randomization
  final List<String> _circleNames = [
    'NYC Foodies', 'Adventure Seekers', 'Coffee Addicts', 'Night Owls', 'Art Lovers',
    'Fitness Fanatics', 'Music Enthusiasts', 'Bookworms', 'Movie Buffs', 'Tech Geeks',
    'Fashion Forward', 'Outdoor Explorers', 'Craft Beer Club', 'Wine Connoisseurs',
    'Photography Club', 'Gaming Squad', 'Cooking Masters', 'Travel Buddies'
  ];

  final List<String> _circleCategories = [
    'foodies', 'nightlife', 'culture', 'adventure', 'wellness', 
    'shopping', 'family', 'business', 'creative', 'other'
  ];

  final List<String> _vibePreferences = [
    'romantic', 'fun', 'relaxing', 'exciting', 'cozy', 'lively', 
    'intimate', 'energetic', 'trendy', 'hipster', 'family_friendly',
    'professional', 'aesthetic', 'rustic', 'modern', 'vintage'
  ];

  final List<String> _placeTypes = [
    'restaurant', 'cafe', 'hotel', 'club', 'lounge', 'cultural', 'adventure', 'other'
  ];

  final List<Map<String, dynamic>> _samplePlaces = [
    {'name': 'Blue Note Jazz Club', 'type': 'cultural', 'lat': 40.7295, 'lng': -74.0009},
    {'name': 'Central Park', 'type': 'adventure', 'lat': 40.7829, 'lng': -73.9654},
    {'name': 'Corner Bistro', 'type': 'restaurant', 'lat': 40.7505, 'lng': -73.9934},
    {'name': 'Artisan Coffee House', 'type': 'cafe', 'lat': 40.7282, 'lng': -73.9942},
    {'name': 'Sunset Rooftop Bar', 'type': 'lounge', 'lat': 40.7589, 'lng': -73.9851},
    {'name': 'Metropolitan Museum', 'type': 'cultural', 'lat': 40.7794, 'lng': -73.9632},
    {'name': 'Brooklyn Bridge', 'type': 'adventure', 'lat': 40.7061, 'lng': -73.9969},
    {'name': 'Speakeasy Lounge', 'type': 'club', 'lat': 40.7400, 'lng': -73.9900},
  ];

  final List<String> _boardTitles = [
    'Perfect Date Night', 'Weekend Adventure', 'Coffee Crawl', 'Art Gallery Tour',
    'Foodie Paradise', 'Night Out', 'Romantic Evening', 'Family Fun Day',
    'Hidden Gems', 'Brunch Spots', 'Rooftop Views', 'Live Music Venues',
    'Cozy Corners', 'Trendy Hotspots', 'Local Favorites', 'Must-Try Places'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Data Generator'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningCard(),
            const SizedBox(height: 20),
            _buildUserSection(),
            const SizedBox(height: 20),
            _buildCircleSection(),
            const SizedBox(height: 20),
            _buildBoardSection(),
            const SizedBox(height: 20),
            _buildVisitSection(),
            const SizedBox(height: 20),
            _buildStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[800]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Admin Panel - Development Use Only',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userCountController,
                    decoration: const InputDecoration(
                      labelText: 'Number of users',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateUsers,
                  icon: _isGenerating 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                  label: const Text('Add Users'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Creates users with emails test@test.com, test1@test.com, etc.\nEach user gets random circles, boards, and visits.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Circles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _circleCountController,
                    decoration: const InputDecoration(
                      labelText: 'Number of circles',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateCircles,
                  icon: _isGenerating 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                  label: const Text('Add Circles'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bookmark, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Boards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _boardCountController,
                    decoration: const InputDecoration(
                      labelText: 'Number of boards',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateBoards,
                  icon: _isGenerating 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                  label: const Text('Add Boards'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Visits (Check-ins)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _visitCountController,
                    decoration: const InputDecoration(
                      labelText: 'Number of visits',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateVisits,
                  icon: _isGenerating 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add),
                  label: const Text('Add Visits'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_statusMessage.isEmpty) return const SizedBox.shrink();
    
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _statusMessage,
                style: TextStyle(color: Colors.green[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateUsers() async {
    final count = int.tryParse(_userCountController.text) ?? 1;
    setState(() {
      _isGenerating = true;
      _statusMessage = '';
    });

    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < count; i++) {
        final userId = 'test_user_$i';
        final email = i == 0 ? 'test@test.com' : 'test$i@test.com';
        
        // Create user document
        final userRef = _firestore.collection('users').doc(userId);
        batch.set(userRef, {
          'userId': userId,
          'name': _generateRandomName(),
          'email': email,
          'photoUrl': _getRandomPhotoUrl(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'notificationsEnabled': _random.nextBool(),
        });

        // Create user vibe score
        final scoreRef = _firestore.collection('user_vibe_scores').doc(userId);
        batch.set(scoreRef, {
          'userId': userId,
          'totalCredPoints': _random.nextInt(1000) + 100,
          'verifiedCheckIns': _random.nextInt(50),
          'photoUploads': _random.nextInt(30),
          'communityLikes': _random.nextInt(200),
          'badges': _getRandomBadges(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'level': _random.nextInt(10) + 1,
          'title': _getRandomTitle(),
        });
      }

      await batch.commit();

      // Generate additional data for each user
      for (int i = 0; i < count; i++) {
        final userId = 'test_user_$i';
        await _generateUserData(userId);
      }

      setState(() {
        _statusMessage = 'Successfully generated $count users with complete data!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating users: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateUserData(String userId) async {
    // Generate 2-4 circles for this user
    final circleCount = 2 + _random.nextInt(3);
    for (int i = 0; i < circleCount; i++) {
      await _createRandomCircle(userId);
    }

    // Generate 3-7 boards
    final boardCount = 3 + _random.nextInt(5);
    for (int i = 0; i < boardCount; i++) {
      await _createRandomBoard(userId);
    }

    // Generate 8-15 visits
    final visitCount = 8 + _random.nextInt(8);
    for (int i = 0; i < visitCount; i++) {
      await _createRandomVisit(userId);
    }
  }

  Future<void> _generateCircles() async {
    final count = int.tryParse(_circleCountController.text) ?? 3;
    setState(() {
      _isGenerating = true;
      _statusMessage = '';
    });

    try {
      for (int i = 0; i < count; i++) {
        await _createRandomCircle('test_user_0'); // Default creator
      }

      setState(() {
        _statusMessage = 'Successfully generated $count circles!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating circles: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateBoards() async {
    final count = int.tryParse(_boardCountController.text) ?? 5;
    setState(() {
      _isGenerating = true;
      _statusMessage = '';
    });

    try {
      for (int i = 0; i < count; i++) {
        await _createRandomBoard('test_user_0'); // Default creator
      }

      setState(() {
        _statusMessage = 'Successfully generated $count boards!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating boards: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _generateVisits() async {
    final count = int.tryParse(_visitCountController.text) ?? 10;
    setState(() {
      _isGenerating = true;
      _statusMessage = '';
    });

    try {
      for (int i = 0; i < count; i++) {
        await _createRandomVisit('test_user_0'); // Default user
      }

      setState(() {
        _statusMessage = 'Successfully generated $count visits!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating visits: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _createRandomCircle(String creatorId) async {
    final circleId = 'circle_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    final circleName = _circleNames[_random.nextInt(_circleNames.length)];
    
    final circleData = {
      'id': circleId,
      'name': circleName,
      'description': _generateCircleDescription(circleName),
      'creatorId': creatorId,
      'creatorName': _generateRandomName(),
      'imageUrl': _getRandomCircleImage(),
      'isPublic': _random.nextBool(),
      'vibePreferences': _getRandomVibes(3 + _random.nextInt(3)),
      'category': _circleCategories[_random.nextInt(_circleCategories.length)],
      'memberCount': 1 + _random.nextInt(20),
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivityAt': FieldValue.serverTimestamp(),
      'requiresApproval': _random.nextBool(),
      'allowMemberInvites': _random.nextBool(),
      'showMemberVisits': _random.nextBool(),
      'memberLimit': _random.nextBool() ? 50 + _random.nextInt(100) : null,
    };

    await _firestore.collection('circles').doc(circleId).set(circleData);

    // Add creator as admin member
    await _firestore.collection('circles').doc(circleId).collection('members').doc(creatorId).set({
      'userId': creatorId,
      'userName': _generateRandomName(),
      'circleId': circleId,
      'role': 'admin',
      'joinedAt': FieldValue.serverTimestamp(),
      'notificationsEnabled': true,
      'contributionScore': _random.nextInt(100),
      'checkInsShared': _random.nextInt(20),
      'boardsCreated': _random.nextInt(10),
      'reviewsWritten': _random.nextInt(15),
    });
  }

  Future<void> _createRandomBoard(String creatorId) async {
    final boardId = 'board_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    final boardTitle = _boardTitles[_random.nextInt(_boardTitles.length)];
    
    // Get random circle to add board to
    final circlesSnapshot = await _firestore.collection('circles').limit(1).get();
    String? circleId;
    if (circlesSnapshot.docs.isNotEmpty) {
      circleId = circlesSnapshot.docs.first.id;
    }

    final boardData = {
      'id': boardId,
      'circleId': circleId,
      'creatorId': creatorId,
      'creatorName': _generateRandomName(),
      'title': boardTitle,
      'description': _generateBoardDescription(boardTitle),
      'places': _generateRandomBoardPlaces(3 + _random.nextInt(5)),
      'tags': _getRandomVibes(2 + _random.nextInt(3)),
      'coverImageUrl': _getRandomPlaceImage(),
      'likeCount': _random.nextInt(50),
      'saveCount': _random.nextInt(25),
      'likedBy': [],
      'savedBy': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (circleId != null) {
      await _firestore.collection('circles').doc(circleId).collection('boards').doc(boardId).set(boardData);
    }
  }

  Future<void> _createRandomVisit(String userId) async {
    final visitId = 'visit_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(1000)}';
    final place = _samplePlaces[_random.nextInt(_samplePlaces.length)];
    
    final visitData = {
      'id': visitId,
      'userId': userId,
      'placeId': 'place_${place['name'].toString().toLowerCase().replaceAll(' ', '_')}',
      'placeName': place['name'],
      'placeType': place['type'],
      'placeCategory': place['type'],
      'latitude': place['lat'] + (_random.nextDouble() - 0.5) * 0.01, // Add some variation
      'longitude': place['lng'] + (_random.nextDouble() - 0.5) * 0.01,
      'visitTime': _getRandomRecentTimestamp(),
      'isManualCheckIn': _random.nextBool(),
      'vibes': _getRandomVibes(2 + _random.nextInt(3)),
      'aiGeneratedVibe': _vibePreferences[_random.nextInt(_vibePreferences.length)],
      'userNote': _generateRandomVisitNote(place['name']),
      'photoUrls': _random.nextBool() ? [_getRandomPlaceImage()] : [],
      'rating': 3.0 + _random.nextDouble() * 2.0, // 3.0 to 5.0
      'address': _generateRandomAddress(),
      'isVerified': _random.nextBool(),
      'verificationDistance': _random.nextInt(100).toDouble(),
      'hasDelayedCheckIn': _random.nextBool(),
      'hasVerifiedPhoto': _random.nextBool(),
      'photoCredibilityScore': _random.nextDouble(),
      'instantVibeTags': _getRandomVibes(1 + _random.nextInt(3)),
      'storyCaption': _generateRandomStoryCaption(),
      'isStoryPublic': _random.nextBool(),
      'vibeCred': _random.nextInt(50) + 10,
    };

    await _firestore.collection('visits').doc(visitId).set(visitData);
  }

  // Helper methods for generating random data
  String _generateRandomName() {
    final firstNames = ['Alex', 'Sarah', 'Mike', 'Emma', 'James', 'Lisa', 'David', 'Rachel', 'Chris', 'Megan'];
    final lastNames = ['Chen', 'Johnson', 'Rodriguez', 'Davis', 'Wilson', 'Garcia', 'Miller', 'Brown', 'Taylor', 'Anderson'];
    return '${firstNames[_random.nextInt(firstNames.length)]} ${lastNames[_random.nextInt(lastNames.length)]}';
  }

  String _getRandomPhotoUrl() {
    final photos = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      'https://images.unsplash.com/photo-1494790108755-2616b612b786',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
    ];
    return photos[_random.nextInt(photos.length)];
  }

  List<String> _getRandomBadges() {
    final badges = ['newcomer', 'explorer', 'photographer', 'social', 'verified', 'trendsetter'];
    final count = 1 + _random.nextInt(3);
    final selected = <String>[];
    while (selected.length < count) {
      final badge = badges[_random.nextInt(badges.length)];
      if (!selected.contains(badge)) selected.add(badge);
    }
    return selected;
  }

  String _getRandomTitle() {
    final titles = ['Vibe Newcomer', 'Local Explorer', 'Social Butterfly', 'Trendsetter', 'Community Leader'];
    return titles[_random.nextInt(titles.length)];
  }

  List<String> _getRandomVibes(int count) {
    final selected = <String>[];
    while (selected.length < count) {
      final vibe = _vibePreferences[_random.nextInt(_vibePreferences.length)];
      if (!selected.contains(vibe)) selected.add(vibe);
    }
    return selected;
  }

  String _getRandomCircleImage() {
    final images = [
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5',
      'https://images.unsplash.com/photo-1551632811-561732d1e306',
      'https://images.unsplash.com/photo-1541961017774-22349e4a1262',
      'https://images.unsplash.com/photo-1566737236500-c8ac43014a8e',
      'https://images.unsplash.com/photo-1445116572660-236099ec97a0',
    ];
    return images[_random.nextInt(images.length)];
  }

  String _getRandomPlaceImage() {
    final images = [
      'https://images.unsplash.com/photo-1574391884720-bfce7feac425',
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4',
      'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb',
      'https://images.unsplash.com/photo-1572986945473-b2bc53b5bdcd',
      'https://images.unsplash.com/photo-1566127982909-9663b0b87edb',
    ];
    return images[_random.nextInt(images.length)];
  }

  String _generateCircleDescription(String name) {
    final templates = [
      'A community of $name enthusiasts exploring the best spots in the city.',
      'Join us for amazing $name experiences and discover hidden gems.',
      'Connect with fellow $name lovers and share your favorite discoveries.',
      'Exploring the vibrant world of $name together, one place at a time.',
    ];
    return templates[_random.nextInt(templates.length)];
  }

  String _generateBoardDescription(String title) {
    final templates = [
      'Curated collection of amazing places for $title.',
      'My personal recommendations for the perfect $title experience.',
      'Discover the best spots for $title in the city.',
      'Hand-picked locations that make $title unforgettable.',
    ];
    return templates[_random.nextInt(templates.length)];
  }

  List<Map<String, dynamic>> _generateRandomBoardPlaces(int count) {
    final places = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      final place = _samplePlaces[_random.nextInt(_samplePlaces.length)];
      places.add({
        'placeId': 'place_${place['name'].toString().toLowerCase().replaceAll(' ', '_')}',
        'placeName': place['name'],
        'placeType': place['type'],
        'latitude': place['lat'],
        'longitude': place['lng'],
        'customNote': _generateRandomPlaceNote(place['name']),
        'vibes': _getRandomVibes(2 + _random.nextInt(2)),
        'imageUrl': _getRandomPlaceImage(),
        'orderIndex': i,
      });
    }
    return places;
  }

  String _generateRandomVisitNote(String placeName) {
    final notes = [
      'Amazing experience at $placeName!',
      'Perfect vibes at $placeName, definitely coming back.',
      'Great atmosphere and service at $placeName.',
      'Hidden gem! Love the energy at $placeName.',
      'Such a cool spot, $placeName exceeded my expectations.',
    ];
    return notes[_random.nextInt(notes.length)];
  }

  String _generateRandomPlaceNote(String placeName) {
    final notes = [
      'Must try the signature dish here!',
      'Perfect for dates and special occasions.',
      'Great spot for groups and celebrations.',
      'Amazing views and atmosphere.',
      'Don\'t miss the happy hour specials!',
    ];
    return notes[_random.nextInt(notes.length)];
  }

  String _generateRandomAddress() {
    final streets = ['Broadway', 'Fifth Avenue', 'Park Avenue', 'Madison Avenue', 'Lexington Avenue'];
    final number = 100 + _random.nextInt(900);
    final street = streets[_random.nextInt(streets.length)];
    return '$number $street, New York, NY';
  }

  String _generateRandomStoryCaption() {
    final captions = [
      'Perfect night out! 🌟',
      'Amazing vibes here ✨',
      'Found my new favorite spot! 💫',
      'Great times with great people 🎉',
      'This place never disappoints! 🔥',
    ];
    return captions[_random.nextInt(captions.length)];
  }

  Timestamp _getRandomRecentTimestamp() {
    final now = DateTime.now();
    final daysAgo = _random.nextInt(30);
    final hoursAgo = _random.nextInt(24);
    final minutesAgo = _random.nextInt(60);
    
    final date = now.subtract(Duration(
      days: daysAgo,
      hours: hoursAgo,
      minutes: minutesAgo,
    ));
    
    return Timestamp.fromDate(date);
  }
}