import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, EnhancedUser> _userCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // ============================================================================
  // USER PROFILE MANAGEMENT
  // ============================================================================

  /// Create initial enhanced user profile from basic user data
  Future<EnhancedUser> createEnhancedUserProfile({
    required String id,
    required String name,
    required String email,
    String? photoUrl,
    String? location,
    String? bio,
  }) async {
    final now = DateTime.now();
    
    final enhancedUser = EnhancedUser(
      id: id,
      name: name,
      email: email,
      photoUrl: photoUrl,
      createdAt: now,
      lastLogin: now,
      vibeProfile: _createDefaultVibeProfile(),
      tasteSignature: _createDefaultTasteSignature(),
      behavioralSignals: _createDefaultBehavioralSignals(),
      onboardingData: _createDefaultOnboardingData(),
      privacySettings: PrivacySettings(),
      notificationPreferences: NotificationPreferences(),
      bio: bio,
      location: location,
      profileLastUpdated: now,
      appVersion: '1.0.0',
    );

    await _firestore.collection('users').doc(id).set(enhancedUser.toJson());
    _userCache[id] = enhancedUser;
    _cacheTimestamps[id] = now;
    
    return enhancedUser;
  }

  /// Get enhanced user profile with caching
  Future<EnhancedUser?> getEnhancedUser(String userId) async {
    try {
      // Check cache first
      if (_userCache.containsKey(userId)) {
        final cacheTime = _cacheTimestamps[userId];
        if (cacheTime != null && DateTime.now().difference(cacheTime) < _cacheExpiry) {
          return _userCache[userId];
        }
      }

      // Fetch from Firestore
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final user = EnhancedUser.fromJson({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      });

      // Update cache
      _userCache[userId] = user;
      _cacheTimestamps[userId] = DateTime.now();

      return user;
    } catch (e) {
      print('Error getting enhanced user: $e');
      return null;
    }
  }

  /// Update user's vibe profile based on onboarding responses
  Future<void> updateVibeProfileFromOnboarding({
    required String userId,
    required List<String> selectedVibes,
    required Map<String, dynamic> quizResponses,
    required Map<String, double> vibeIntensities,
  }) async {
    try {
      final user = await getEnhancedUser(userId);
      if (user == null) return;

      // Create vibe scores from selections
      final vibeScores = <String, VibeScore>{};
      for (final vibe in selectedVibes) {
        final intensity = vibeIntensities[vibe] ?? 0.8;
        vibeScores[vibe] = VibeScore(
          vibeId: vibe,
          score: intensity,
          lastUpdated: DateTime.now(),
          interactionCount: 1,
        );
      }

      // Create evolution data point
      final evolutionPoint = VibeEvolutionDataPoint(
        timestamp: DateTime.now(),
        vibeScores: Map.fromEntries(
          vibeScores.entries.map((e) => MapEntry(e.key, e.value.score)),
        ),
        context: 'onboarding',
      );

      // Update vibe profile
      final updatedVibeProfile = VibeProfile(
        primaryVibes: selectedVibes.take(5).toList(),
        vibeScores: vibeScores,
        vibeEvolution: [evolutionPoint],
        contextualVibes: ContextualVibes(
          contextVibeMap: _inferContextualVibes(selectedVibes),
          lastUpdated: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      // Update onboarding data
      final updatedOnboardingData = OnboardingData(
        completedSteps: ['welcome', 'vibe_selection', 'preferences', 'completed'],
        quizResponses: quizResponses,
        initialMatches: [], // Will be populated by matching service
        onboardingVersion: '1.0',
        completionTimestamp: DateTime.now(),
        engagementScore: _calculateEngagementScore(quizResponses),
      );

      // Save updates
      await _firestore.collection('users').doc(userId).update({
        'vibeProfile': updatedVibeProfile.toJson(),
        'onboardingData': updatedOnboardingData.toJson(),
        'profileLastUpdated': FieldValue.serverTimestamp(),
      });

      // Clear cache
      _userCache.remove(userId);
      _cacheTimestamps.remove(userId);

    } catch (e) {
      print('Error updating vibe profile from onboarding: $e');
    }
  }

  /// Update user's taste signature based on behavior analysis
  Future<void> updateTasteSignature(String userId) async {
    try {
      final user = await getEnhancedUser(userId);
      if (user == null) return;

      // Analyze user's recent behavior
      final venuePreferences = await _analyzeVenuePreferences(userId);
      final priceRangeAffinity = await _analyzePriceRangeAffinity(userId);
      final socialPreference = await _analyzeSocialPreference(userId);
      final discoveryQuotient = await _analyzeDiscoveryQuotient(userId);
      final timePatterns = await _analyzeTimePatterns(userId);

      final updatedTasteSignature = TasteSignature(
        venuePreferences: venuePreferences,
        priceRangeAffinity: priceRangeAffinity,
        socialPreference: socialPreference,
        discoveryQuotient: discoveryQuotient,
        timePatterns: timePatterns,
        lastCalculated: DateTime.now(),
      );

      await _firestore.collection('users').doc(userId).update({
        'tasteSignature': updatedTasteSignature.toJson(),
        'profileLastUpdated': FieldValue.serverTimestamp(),
      });

      // Clear cache
      _userCache.remove(userId);
      _cacheTimestamps.remove(userId);

    } catch (e) {
      print('Error updating taste signature: $e');
    }
  }

  /// Update behavioral signals based on recent activity
  Future<void> updateBehavioralSignals(String userId) async {
    try {
      final consistencyScore = await _calculateVibeConsistency(userId);
      final explorationRadius = await _calculateExplorationRadius(userId);
      final influenceScore = await _calculateInfluenceScore(userId);
      final activityPatterns = await _analyzeActivityPatterns(userId);

      final updatedBehavioralSignals = BehavioralSignals(
        vibeConsistencyScore: consistencyScore,
        explorationRadius: explorationRadius,
        influenceScore: influenceScore,
        activityPatterns: activityPatterns,
        lastCalculated: DateTime.now(),
      );

      await _firestore.collection('users').doc(userId).update({
        'behavioralSignals': updatedBehavioralSignals.toJson(),
        'profileLastUpdated': FieldValue.serverTimestamp(),
      });

      // Clear cache
      _userCache.remove(userId);
      _cacheTimestamps.remove(userId);

    } catch (e) {
      print('Error updating behavioral signals: $e');
    }
  }

  /// Add vibe evolution data point when user makes vibe-related choices
  Future<void> addVibeEvolutionPoint({
    required String userId,
    required Map<String, double> vibeScores,
    required String context,
  }) async {
    try {
      final user = await getEnhancedUser(userId);
      if (user == null) return;

      final evolutionPoint = VibeEvolutionDataPoint(
        timestamp: DateTime.now(),
        vibeScores: vibeScores,
        context: context,
      );

      // Update vibe scores and evolution
      final updatedVibeScores = Map<String, VibeScore>.from(user.vibeProfile.vibeScores);
      for (final entry in vibeScores.entries) {
        if (updatedVibeScores.containsKey(entry.key)) {
          final existing = updatedVibeScores[entry.key]!;
          updatedVibeScores[entry.key] = VibeScore(
            vibeId: entry.key,
            score: _exponentialMovingAverage(existing.score, entry.value, 0.3),
            lastUpdated: DateTime.now(),
            interactionCount: existing.interactionCount + 1,
          );
        } else {
          updatedVibeScores[entry.key] = VibeScore(
            vibeId: entry.key,
            score: entry.value,
            lastUpdated: DateTime.now(),
            interactionCount: 1,
          );
        }
      }

      // Update primary vibes based on current scores
      final sortedVibes = updatedVibeScores.entries
          .toList()
          ..sort((a, b) => b.value.score.compareTo(a.value.score));
      final newPrimaryVibes = sortedVibes.take(5).map((e) => e.key).toList();

      final updatedEvolution = List<VibeEvolutionDataPoint>.from(user.vibeProfile.vibeEvolution)
        ..add(evolutionPoint);

      // Keep only last 100 evolution points
      if (updatedEvolution.length > 100) {
        updatedEvolution.removeRange(0, updatedEvolution.length - 100);
      }

      final updatedVibeProfile = VibeProfile(
        primaryVibes: newPrimaryVibes,
        vibeScores: updatedVibeScores,
        vibeEvolution: updatedEvolution,
        contextualVibes: user.vibeProfile.contextualVibes,
        lastUpdated: DateTime.now(),
      );

      await _firestore.collection('users').doc(userId).update({
        'vibeProfile': updatedVibeProfile.toJson(),
      });

      // Clear cache
      _userCache.remove(userId);
      _cacheTimestamps.remove(userId);

    } catch (e) {
      print('Error adding vibe evolution point: $e');
    }
  }

  /// Generate auto vibe title based on user's profile
  Future<void> updateVibeTitle(String userId) async {
    try {
      final user = await getEnhancedUser(userId);
      if (user == null) return;

      final vibeTitle = _generateVibeTitle(user.vibeProfile, user.behavioralSignals, user.tasteSignature);

      await _firestore.collection('users').doc(userId).update({
        'vibeTitle': vibeTitle,
      });

      // Clear cache
      _userCache.remove(userId);
      _cacheTimestamps.remove(userId);

    } catch (e) {
      print('Error updating vibe title: $e');
    }
  }

  // ============================================================================
  // PRIVACY & DATA EXPORT
  // ============================================================================

  /// Update user's privacy settings
  Future<void> updatePrivacySettings(String userId, PrivacySettings settings) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'privacySettings': settings.toJson(),
      });

      _userCache.remove(userId);
      _cacheTimestamps.remove(userId);
    } catch (e) {
      print('Error updating privacy settings: $e');
    }
  }

  /// Export user's data for privacy compliance
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final user = await getEnhancedUser(userId);
      if (user == null) return {};

      // Get all user-related data
      final visits = await _getUserVisits(userId);
      final boards = await _getUserBoards(userId);
      final circlesMemberships = await _getUserCircleMemberships(userId);

      return {
        'profile': user.toJson(),
        'visits': visits,
        'boards': boards,
        'circleMemberships': circlesMemberships,
        'exportTimestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error exporting user data: $e');
      return {};
    }
  }

  /// Delete user's data (for account deletion)
  Future<void> deleteUserData(String userId) async {
    try {
      // Delete user profile
      await _firestore.collection('users').doc(userId).delete();

      // Delete related data
      await _deleteUserRelatedData(userId);

      // Clear cache
      _userCache.remove(userId);
      _cacheTimestamps.remove(userId);

    } catch (e) {
      print('Error deleting user data: $e');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  VibeProfile _createDefaultVibeProfile() {
    return VibeProfile(
      primaryVibes: [],
      vibeScores: {},
      vibeEvolution: [],
      contextualVibes: ContextualVibes(
        contextVibeMap: {},
        lastUpdated: DateTime.now(),
      ),
      lastUpdated: DateTime.now(),
    );
  }

  TasteSignature _createDefaultTasteSignature() {
    return TasteSignature(
      venuePreferences: {},
      priceRangeAffinity: {
        '\$': 0.8,
        '\$\$': 0.6,
        '\$\$\$': 0.4,
        '\$\$\$\$': 0.2,
      },
      socialPreference: 0.5,
      discoveryQuotient: 0.5,
      timePatterns: {},
      lastCalculated: DateTime.now(),
    );
  }

  BehavioralSignals _createDefaultBehavioralSignals() {
    return BehavioralSignals(
      vibeConsistencyScore: 0.5,
      explorationRadius: 0.5,
      influenceScore: 0.0,
      activityPatterns: {},
      lastCalculated: DateTime.now(),
    );
  }

  OnboardingData _createDefaultOnboardingData() {
    return OnboardingData(
      completedSteps: [],
      quizResponses: {},
      initialMatches: [],
      onboardingVersion: '1.0',
      engagementScore: 0.0,
    );
  }

  Map<String, List<String>> _inferContextualVibes(List<String> selectedVibes) {
    final contextMap = <String, List<String>>{};
    
    // Basic context inference based on vibe types
    if (selectedVibes.contains('energetic') || selectedVibes.contains('social')) {
      contextMap['evening'] = ['energetic', 'social'];
      contextMap['weekend'] = ['energetic', 'social'];
    }
    
    if (selectedVibes.contains('cozy') || selectedVibes.contains('chill')) {
      contextMap['morning'] = ['cozy', 'chill'];
      contextMap['rainy'] = ['cozy', 'chill'];
    }
    
    if (selectedVibes.contains('aesthetic')) {
      contextMap['date'] = ['aesthetic', 'intimate'];
    }

    return contextMap;
  }

  double _calculateEngagementScore(Map<String, dynamic> quizResponses) {
    // Calculate engagement based on response completeness and depth
    double score = 0.0;
    
    score += quizResponses.length * 0.1; // Base points for answering
    
    // Bonus for detailed responses
    for (final response in quizResponses.values) {
      if (response is String && response.length > 10) {
        score += 0.1;
      } else if (response is List && response.length > 1) {
        score += 0.1;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  String _generateVibeTitle(VibeProfile profile, BehavioralSignals signals, TasteSignature tasteSignature) {
    if (profile.primaryVibes.isEmpty) return 'Explorer';

    final primaryVibe = profile.primaryVibes.first;
    
    final titleMap = {
      'cozy': signals.explorationRadius > 0.7 ? 'Cozy Adventurer' : 'Cozy Corner Connoisseur',
      'active': tasteSignature.socialPreference > 0.7 ? 'Social Dynamo' : 'Solo Energy',
      'aesthetic': signals.influenceScore > 0.6 ? 'Aesthetic Trendsetter' : 'Visual Curator',
      'adventurous': tasteSignature.discoveryQuotient > 0.8 ? 'Hidden Gem Hunter' : 'Adventure Seeker',
      'luxurious': 'Luxury Lifestyle Guru',
      'social': 'Community Connector',
      'chill': 'Zen Master',
      'intimate': 'Romantic Experience Curator',
      'fitness': signals.explorationRadius > 0.6 ? 'Fitness Explorer' : 'Wellness Warrior',
    };

    return titleMap[primaryVibe] ?? 'Vibe Explorer';
  }

  double _exponentialMovingAverage(double oldValue, double newValue, double alpha) {
    return alpha * newValue + (1 - alpha) * oldValue;
  }

  // Analysis methods (simplified for brevity)
  Future<Map<String, double>> _analyzeVenuePreferences(String userId) async {
    // Analyze user's visit history for venue type preferences
    final visits = await _getUserVisits(userId);
    final preferences = <String, double>{};
    
    // Count venue types
    final typeCounts = <String, int>{};
    for (final visit in visits) {
      final type = visit['placeType'] as String? ?? 'unknown';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    
    // Convert to preferences (0.0-1.0)
    final total = typeCounts.values.fold(0, (a, b) => a + b);
    if (total > 0) {
      typeCounts.forEach((type, count) {
        preferences[type] = count / total;
      });
    }
    
    return preferences;
  }

  Future<Map<String, double>> _analyzePriceRangeAffinity(String userId) async {
    // Default to moderate preferences
    return {
      '\$': 0.8,
      '\$\$': 0.9,
      '\$\$\$': 0.6,
      '\$\$\$\$': 0.3,
    };
  }

  Future<double> _analyzeSocialPreference(String userId) async {
    // Analyze group vs solo activities
    return 0.5; // Default neutral
  }

  Future<double> _analyzeDiscoveryQuotient(String userId) async {
    // Analyze how often they visit new vs popular places
    return 0.5; // Default neutral
  }

  Future<Map<String, List<String>>> _analyzeTimePatterns(String userId) async {
    // Analyze activity patterns by time
    return {
      'morning': ['breakfast', 'coffee'],
      'afternoon': ['lunch', 'cafe'],
      'evening': ['dinner', 'bar'],
    };
  }

  Future<double> _calculateVibeConsistency(String userId) async {
    // Calculate how consistent user's vibe choices are
    return 0.7; // Placeholder
  }

  Future<double> _calculateExplorationRadius(String userId) async {
    // Calculate willingness to try new things
    return 0.6; // Placeholder
  }

  Future<double> _calculateInfluenceScore(String userId) async {
    // Calculate how much user influences others
    return 0.3; // Placeholder
  }

  Future<Map<String, int>> _analyzeActivityPatterns(String userId) async {
    // Analyze when user is most active
    return {}; // Placeholder
  }

  Future<List<Map<String, dynamic>>> _getUserVisits(String userId) async {
    try {
      final visits = await _firestore
          .collection('visits')
          .where('userId', isEqualTo: userId)
          .get();
      
      return visits.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getUserBoards(String userId) async {
    try {
      final boards = await _firestore
          .collection('boards')
          .where('createdBy', isEqualTo: userId)
          .get();
      
      return boards.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getUserCircleMemberships(String userId) async {
    try {
      final memberships = await _firestore
          .collection('circle_memberships')
          .where('userId', isEqualTo: userId)
          .get();
      
      return memberships.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _deleteUserRelatedData(String userId) async {
    // Delete visits
    final visitsBatch = _firestore.batch();
    final visits = await _firestore
        .collection('visits')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (final doc in visits.docs) {
      visitsBatch.delete(doc.reference);
    }
    await visitsBatch.commit();

    // Delete other related data as needed
  }
}