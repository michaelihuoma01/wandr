import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'user_profile_service.dart';

class UserMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserProfileService _userProfileService = UserProfileService();

  // ============================================================================
  // MIGRATION FROM BASIC USER TO ENHANCED USER
  // ============================================================================

  /// Migrate all existing users to the enhanced user model
  Future<void> migrateAllUsers() async {
    try {
      print('Starting user migration to enhanced model...');
      
      // Get all existing users in batches
      const batchSize = 50;
      DocumentSnapshot? lastDoc;
      int totalMigrated = 0;
      
      while (true) {
        Query query = _firestore.collection('users').limit(batchSize);
        
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }
        
        final batch = await query.get();
        if (batch.docs.isEmpty) break;
        
        // Migrate this batch
        for (final doc in batch.docs) {
          try {
            await migrateSingleUser(doc.id, doc.data() as Map<String, dynamic>);
            totalMigrated++;
            print('Migrated user ${doc.id} ($totalMigrated)');
          } catch (e) {
            print('Error migrating user ${doc.id}: $e');
          }
        }
        
        lastDoc = batch.docs.last;
        
        // Brief pause to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      print('Migration completed. Total users migrated: $totalMigrated');
    } catch (e) {
      print('Error during batch migration: $e');
    }
  }

  /// Migrate a single user to the enhanced model
  Future<void> migrateSingleUser(String userId, Map<String, dynamic> userData) async {
    try {
      // Check if user is already migrated
      if (userData.containsKey('vibeProfile') && userData.containsKey('tasteSignature')) {
        print('User $userId already migrated, skipping...');
        return;
      }

      // Extract existing user data
      final name = userData['name'] as String? ?? 'Unknown User';
      final email = userData['email'] as String? ?? '';
      final photoUrl = userData['photoUrl'] as String?;
      final createdAt = _parseDateTime(userData['createdAt']);
      final lastLogin = _parseDateTime(userData['lastLogin']);

      // Analyze existing data to infer preferences
      final inferredData = await _inferUserPreferences(userId);

      // Create enhanced user profile
      final enhancedUser = EnhancedUser(
        id: userId,
        name: name,
        email: email,
        photoUrl: photoUrl,
        createdAt: createdAt,
        lastLogin: lastLogin,
        vibeProfile: inferredData.vibeProfile,
        tasteSignature: inferredData.tasteSignature,
        behavioralSignals: inferredData.behavioralSignals,
        onboardingData: _createMigrationOnboardingData(),
        privacySettings: PrivacySettings(),
        notificationPreferences: NotificationPreferences(),
        bio: userData['bio'] as String?,
        location: userData['location'] as String?,
        interests: _parseStringList(userData['interests']),
        vibeTitle: inferredData.vibeTitle,
        trustScore: userData['trustScore'] as int? ?? 0,
        achievements: _parseStringList(userData['achievements']),
        profileLastUpdated: DateTime.now(),
        appVersion: '1.0.0-migrated',
      );

      // Save enhanced user data
      await _firestore.collection('users').doc(userId).set(enhancedUser.toJson());

    } catch (e) {
      print('Error migrating user $userId: $e');
      rethrow;
    }
  }

  /// Analyze user's existing data to infer vibe preferences
  Future<InferredUserData> _inferUserPreferences(String userId) async {
    try {
      // Analyze user's visits to infer vibe preferences
      final vibeAnalysis = await _analyzeUserVibesFromVisits(userId);
      
      // Analyze venue preferences
      final venuePreferences = await _analyzeVenuePreferencesFromVisits(userId);
      
      // Analyze social behavior
      final socialAnalysis = await _analyzeSocialBehavior(userId);
      
      // Create vibe profile
      final vibeProfile = VibeProfile(
        primaryVibes: vibeAnalysis.primaryVibes,
        vibeScores: vibeAnalysis.vibeScores,
        vibeEvolution: [
          VibeEvolutionDataPoint(
            timestamp: DateTime.now(),
            vibeScores: Map.fromEntries(
              vibeAnalysis.vibeScores.entries.map((e) => MapEntry(e.key, e.value.score)),
            ),
            context: 'migration_analysis',
          ),
        ],
        contextualVibes: ContextualVibes(
          contextVibeMap: _inferContextualVibes(vibeAnalysis.primaryVibes),
          lastUpdated: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      // Create taste signature
      final tasteSignature = TasteSignature(
        venuePreferences: venuePreferences,
        priceRangeAffinity: _getDefaultPriceRangeAffinity(),
        socialPreference: socialAnalysis.socialPreference,
        discoveryQuotient: socialAnalysis.discoveryQuotient,
        timePatterns: socialAnalysis.timePatterns,
        lastCalculated: DateTime.now(),
      );

      // Create behavioral signals
      final behavioralSignals = BehavioralSignals(
        vibeConsistencyScore: socialAnalysis.consistencyScore,
        explorationRadius: socialAnalysis.explorationRadius,
        influenceScore: socialAnalysis.influenceScore,
        activityPatterns: socialAnalysis.activityPatterns,
        lastCalculated: DateTime.now(),
      );

      // Generate vibe title
      final vibeTitle = _generateVibeTitle(vibeProfile, behavioralSignals, tasteSignature);

      return InferredUserData(
        vibeProfile: vibeProfile,
        tasteSignature: tasteSignature,
        behavioralSignals: behavioralSignals,
        vibeTitle: vibeTitle,
      );

    } catch (e) {
      print('Error inferring user preferences for $userId: $e');
      return _createDefaultInferredData();
    }
  }

  /// Analyze user's vibe preferences from visit history
  Future<VibeAnalysis> _analyzeUserVibesFromVisits(String userId) async {
    try {
      final visits = await _firestore
          .collection('visits')
          .where('userId', isEqualTo: userId)
          .orderBy('visitTime', descending: true)
          .limit(50)
          .get();

      final vibeFrequency = <String, int>{};
      final vibeScores = <String, VibeScore>{};

      // Count vibe occurrences from visits
      for (final visit in visits.docs) {
        final visitData = visit.data();
        final vibes = List<String>.from(visitData['vibes'] ?? []);
        
        for (final vibe in vibes) {
          vibeFrequency[vibe] = (vibeFrequency[vibe] ?? 0) + 1;
        }
      }

      // Convert frequency to scores
      final maxFrequency = vibeFrequency.values.isNotEmpty 
          ? vibeFrequency.values.reduce((a, b) => a > b ? a : b) 
          : 1;

      for (final entry in vibeFrequency.entries) {
        final score = entry.value / maxFrequency;
        vibeScores[entry.key] = VibeScore(
          vibeId: entry.key,
          score: score,
          lastUpdated: DateTime.now(),
          interactionCount: entry.value,
        );
      }

      // Get top vibes as primary vibes
      final sortedVibes = vibeFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final primaryVibes = sortedVibes.take(5).map((e) => e.key).toList();

      // If no visit data, use default vibes
      if (primaryVibes.isEmpty) {
        return _createDefaultVibeAnalysis();
      }

      return VibeAnalysis(
        primaryVibes: primaryVibes,
        vibeScores: vibeScores,
      );

    } catch (e) {
      print('Error analyzing vibes from visits: $e');
      return _createDefaultVibeAnalysis();
    }
  }

  /// Analyze venue preferences from visit history
  Future<Map<String, double>> _analyzeVenuePreferencesFromVisits(String userId) async {
    try {
      final visits = await _firestore
          .collection('visits')
          .where('userId', isEqualTo: userId)
          .limit(100)
          .get();

      final venueTypeCounts = <String, int>{};

      for (final visit in visits.docs) {
        final visitData = visit.data();
        final placeType = visitData['placeType'] as String? ?? 'unknown';
        venueTypeCounts[placeType] = (venueTypeCounts[placeType] ?? 0) + 1;
      }

      // Convert counts to preferences
      final preferences = <String, double>{};
      final total = venueTypeCounts.values.fold(0, (a, b) => a + b);
      
      if (total > 0) {
        for (final entry in venueTypeCounts.entries) {
          preferences[entry.key] = entry.value / total;
        }
      }

      return preferences.isNotEmpty ? preferences : _getDefaultVenuePreferences();

    } catch (e) {
      print('Error analyzing venue preferences: $e');
      return _getDefaultVenuePreferences();
    }
  }

  /// Analyze social behavior patterns
  Future<SocialAnalysis> _analyzeSocialBehavior(String userId) async {
    try {
      // Analyze circle memberships for social preference
      final memberships = await _firestore
          .collection('circle_memberships')
          .where('userId', isEqualTo: userId)
          .get();

      // Analyze boards created for influence score
      final boards = await _firestore
          .collection('boards')
          .where('createdBy', isEqualTo: userId)
          .get();

      // Analyze visit patterns for time preferences
      final visits = await _firestore
          .collection('visits')
          .where('userId', isEqualTo: userId)
          .orderBy('visitTime', descending: true)
          .limit(50)
          .get();

      // Calculate metrics
      final socialPreference = memberships.docs.length > 3 ? 0.8 : 0.4;
      final influenceScore = boards.docs.length > 5 ? 0.7 : 0.3;
      final discoveryQuotient = _calculateDiscoveryQuotient(visits.docs);
      final consistencyScore = _calculateConsistencyScore(visits.docs);
      final explorationRadius = _calculateExplorationRadius(visits.docs);
      final timePatterns = _analyzeTimePatterns(visits.docs);
      final activityPatterns = _analyzeActivityPatterns(visits.docs);

      return SocialAnalysis(
        socialPreference: socialPreference,
        influenceScore: influenceScore,
        discoveryQuotient: discoveryQuotient,
        consistencyScore: consistencyScore,
        explorationRadius: explorationRadius,
        timePatterns: timePatterns,
        activityPatterns: activityPatterns,
      );

    } catch (e) {
      print('Error analyzing social behavior: $e');
      return _createDefaultSocialAnalysis();
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    return [];
  }

  OnboardingData _createMigrationOnboardingData() {
    return OnboardingData(
      completedSteps: ['migration'],
      quizResponses: {'migrationType': 'automatic'},
      initialMatches: [],
      onboardingVersion: '1.0-migration',
      completionTimestamp: DateTime.now(),
      engagementScore: 0.5,
    );
  }

  Map<String, List<String>> _inferContextualVibes(List<String> primaryVibes) {
    final contextMap = <String, List<String>>{};
    
    for (final vibe in primaryVibes.take(3)) {
      if (vibe == 'energetic' || vibe == 'social') {
        contextMap['evening'] = [...(contextMap['evening'] ?? []), vibe];
        contextMap['weekend'] = [...(contextMap['weekend'] ?? []), vibe];
      } else if (vibe == 'cozy' || vibe == 'chill') {
        contextMap['morning'] = [...(contextMap['morning'] ?? []), vibe];
        contextMap['rainy'] = [...(contextMap['rainy'] ?? []), vibe];
      }
    }
    
    return contextMap;
  }

  Map<String, double> _getDefaultPriceRangeAffinity() {
    return {
      '\$': 0.8,
      '\$\$': 0.9,
      '\$\$\$': 0.6,
      '\$\$\$\$': 0.3,
    };
  }

  Map<String, double> _getDefaultVenuePreferences() {
    return {
      'restaurant': 0.4,
      'cafe': 0.3,
      'bar': 0.2,
      'park': 0.1,
    };
  }

  VibeAnalysis _createDefaultVibeAnalysis() {
    final defaultVibes = ['social', 'chill', 'aesthetic'];
    final vibeScores = <String, VibeScore>{};
    
    for (int i = 0; i < defaultVibes.length; i++) {
      vibeScores[defaultVibes[i]] = VibeScore(
        vibeId: defaultVibes[i],
        score: 0.7 - (i * 0.1),
        lastUpdated: DateTime.now(),
        interactionCount: 0,
      );
    }

    return VibeAnalysis(
      primaryVibes: defaultVibes,
      vibeScores: vibeScores,
    );
  }

  SocialAnalysis _createDefaultSocialAnalysis() {
    return SocialAnalysis(
      socialPreference: 0.5,
      influenceScore: 0.3,
      discoveryQuotient: 0.5,
      consistencyScore: 0.6,
      explorationRadius: 0.5,
      timePatterns: {
        'morning': ['breakfast', 'coffee'],
        'evening': ['dinner', 'social'],
      },
      activityPatterns: {},
    );
  }

  InferredUserData _createDefaultInferredData() {
    final vibeAnalysis = _createDefaultVibeAnalysis();
    final socialAnalysis = _createDefaultSocialAnalysis();

    final vibeProfile = VibeProfile(
      primaryVibes: vibeAnalysis.primaryVibes,
      vibeScores: vibeAnalysis.vibeScores,
      vibeEvolution: [],
      contextualVibes: ContextualVibes(
        contextVibeMap: _inferContextualVibes(vibeAnalysis.primaryVibes),
        lastUpdated: DateTime.now(),
      ),
      lastUpdated: DateTime.now(),
    );

    final tasteSignature = TasteSignature(
      venuePreferences: _getDefaultVenuePreferences(),
      priceRangeAffinity: _getDefaultPriceRangeAffinity(),
      socialPreference: socialAnalysis.socialPreference,
      discoveryQuotient: socialAnalysis.discoveryQuotient,
      timePatterns: socialAnalysis.timePatterns,
      lastCalculated: DateTime.now(),
    );

    final behavioralSignals = BehavioralSignals(
      vibeConsistencyScore: socialAnalysis.consistencyScore,
      explorationRadius: socialAnalysis.explorationRadius,
      influenceScore: socialAnalysis.influenceScore,
      activityPatterns: socialAnalysis.activityPatterns,
      lastCalculated: DateTime.now(),
    );

    return InferredUserData(
      vibeProfile: vibeProfile,
      tasteSignature: tasteSignature,
      behavioralSignals: behavioralSignals,
      vibeTitle: 'Explorer',
    );
  }

  String _generateVibeTitle(VibeProfile profile, BehavioralSignals signals, TasteSignature tasteSignature) {
    if (profile.primaryVibes.isEmpty) return 'Explorer';

    final primaryVibe = profile.primaryVibes.first;
    
    final titleMap = {
      'cozy': signals.explorationRadius > 0.7 ? 'Cozy Adventurer' : 'Cozy Corner Connoisseur',
      'active': tasteSignature.socialPreference > 0.7 ? 'Social Dynamo' : 'Solo Energy',
      'aesthetic': signals.influenceScore > 0.6 ? 'Aesthetic Trendsetter' : 'Visual Curator',
      'adventurous': signals.explorationRadius > 0.8 ? 'Hidden Gem Hunter' : 'Adventure Seeker',
      'luxurious': 'Luxury Lifestyle Guru',
      'social': 'Community Connector',
      'chill': 'Zen Master',
      'intimate': 'Romantic Experience Curator',
      'fitness': signals.explorationRadius > 0.6 ? 'Fitness Explorer' : 'Wellness Warrior',
    };

    return titleMap[primaryVibe] ?? 'Vibe Explorer';
  }

  double _calculateDiscoveryQuotient(List<QueryDocumentSnapshot> visits) {
    // Simplified: assume 50% discovery quotient for migrated users
    return 0.5;
  }

  double _calculateConsistencyScore(List<QueryDocumentSnapshot> visits) {
    // Simplified: assume moderate consistency for migrated users
    return 0.6;
  }

  double _calculateExplorationRadius(List<QueryDocumentSnapshot> visits) {
    // Simplified: assume moderate exploration for migrated users
    return 0.5;
  }

  Map<String, List<String>> _analyzeTimePatterns(List<QueryDocumentSnapshot> visits) {
    return {
      'morning': ['breakfast', 'coffee'],
      'afternoon': ['lunch', 'cafe'],
      'evening': ['dinner', 'bar'],
    };
  }

  Map<String, int> _analyzeActivityPatterns(List<QueryDocumentSnapshot> visits) {
    final patterns = <String, int>{};
    
    for (final visit in visits) {
      final visitData = visit.data() as Map<String, dynamic>;
      final visitTime = _parseDateTime(visitData['visitTime']);
      final dayOfWeek = _getDayOfWeekKey(visitTime);
      patterns[dayOfWeek] = (patterns[dayOfWeek] ?? 0) + 1;
    }
    
    return patterns;
  }

  String _getDayOfWeekKey(DateTime dateTime) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[dateTime.weekday - 1];
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

class VibeAnalysis {
  final List<String> primaryVibes;
  final Map<String, VibeScore> vibeScores;

  VibeAnalysis({
    required this.primaryVibes,
    required this.vibeScores,
  });
}

class SocialAnalysis {
  final double socialPreference;
  final double influenceScore;
  final double discoveryQuotient;
  final double consistencyScore;
  final double explorationRadius;
  final Map<String, List<String>> timePatterns;
  final Map<String, int> activityPatterns;

  SocialAnalysis({
    required this.socialPreference,
    required this.influenceScore,
    required this.discoveryQuotient,
    required this.consistencyScore,
    required this.explorationRadius,
    required this.timePatterns,
    required this.activityPatterns,
  });
}

class InferredUserData {
  final VibeProfile vibeProfile;
  final TasteSignature tasteSignature;
  final BehavioralSignals behavioralSignals;
  final String vibeTitle;

  InferredUserData({
    required this.vibeProfile,
    required this.tasteSignature,
    required this.behavioralSignals,
    required this.vibeTitle,
  });
}