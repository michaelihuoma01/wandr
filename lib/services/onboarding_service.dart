import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'user_profile_service.dart';
import 'user_persona_service.dart';
import 'vibe_matching_service.dart';

class OnboardingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserProfileService _userProfileService = UserProfileService();
  final VibeMatchingService _vibeMatchingService = VibeMatchingService();

  // ============================================================================
  // ONBOARDING FLOW MANAGEMENT
  // ============================================================================

  /// Initialize onboarding for a user
  Future<OnboardingState> initializeOnboarding(String userId) async {
    final onboardingState = OnboardingState(
      userId: userId,
      currentStep: OnboardingStep.welcome,
      completedSteps: [],
      responses: {},
      startedAt: DateTime.now(),
    );

    await _saveOnboardingState(onboardingState);
    return onboardingState;
  }

  /// Get current onboarding state
  Future<OnboardingState?> getOnboardingState(String userId) async {
    try {
      final doc = await _firestore
          .collection('onboarding_states')
          .doc(userId)
          .get();

      if (doc.exists) {
        return OnboardingState.fromJson({
          'userId': userId,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      print('Error getting onboarding state: $e');
      return null;
    }
  }

  /// Progress to next onboarding step
  Future<OnboardingState> progressToNextStep(
    OnboardingState currentState,
    Map<String, dynamic> stepResponses,
  ) async {
    final nextStep = _getNextStep(currentState.currentStep);
    
    final updatedState = OnboardingState(
      userId: currentState.userId,
      currentStep: nextStep,
      completedSteps: [
        ...currentState.completedSteps,
        currentState.currentStep,
      ],
      responses: {
        ...currentState.responses,
        ...stepResponses,
      },
      startedAt: currentState.startedAt,
      lastUpdated: DateTime.now(),
    );

    await _saveOnboardingState(updatedState);
    return updatedState;
  }

  /// Complete onboarding and create user profile
  Future<OnboardingResult> completeOnboarding(OnboardingState state) async {
    try {
      // Create vibe profile from responses
      final vibeProfile = await _createVibeProfileFromResponses(state.responses);
      
      // Create user persona
      final persona = UserPersonaService.generatePersona(vibeProfile);
      
      // Find initial matches
      final initialMatches = await _findInitialMatches(state.userId, vibeProfile);
      
      // Update user profile with onboarding data
      await _userProfileService.updateVibeProfileFromOnboarding(
        userId: state.userId,
        selectedVibes: vibeProfile.primaryVibes,
        quizResponses: state.responses,
        vibeIntensities: _extractVibeIntensities(state.responses),
      );

      // Mark onboarding as completed
      await _markOnboardingCompleted(state.userId, initialMatches);

      // Clean up temporary onboarding state
      await _firestore.collection('onboarding_states').doc(state.userId).delete();

      return OnboardingResult(
        success: true,
        persona: persona,
        initialMatches: initialMatches,
        completedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error completing onboarding: $e');
      return OnboardingResult(
        success: false,
        error: 'Failed to complete onboarding. Please try again.',
      );
    }
  }

  /// Skip onboarding step with fallback
  Future<OnboardingState> skipStep(
    OnboardingState currentState,
    String reason,
  ) async {
    final fallbackResponses = _generateFallbackResponses(currentState.currentStep);
    
    return progressToNextStep(currentState, {
      'skipped': true,
      'skipReason': reason,
      ...fallbackResponses,
    });
  }

  // ============================================================================
  // VIBE CALCULATION & MATCHING
  // ============================================================================

  /// Create vibe profile from onboarding responses
  Future<VibeProfile> _createVibeProfileFromResponses(Map<String, dynamic> responses) async {
    final selectedVibes = _extractSelectedVibes(responses);
    final vibeIntensities = _extractVibeIntensities(responses);
    final contextualMapping = _generateContextualMapping(responses);

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

    return VibeProfile(
      primaryVibes: selectedVibes.take(5).toList(),
      vibeScores: vibeScores,
      vibeEvolution: [
        VibeEvolutionDataPoint(
          timestamp: DateTime.now(),
          vibeScores: Map.fromEntries(
            vibeScores.entries.map((e) => MapEntry(e.key, e.value.score)),
          ),
          context: 'onboarding',
        ),
      ],
      contextualVibes: ContextualVibes(
        contextVibeMap: contextualMapping,
        lastUpdated: DateTime.now(),
      ),
      lastUpdated: DateTime.now(),
    );
  }

  /// Find initial matches for user
  Future<OnboardingMatches> _findInitialMatches(
    String userId,
    VibeProfile vibeProfile,
  ) async {
    try {
      // Find similar users
      final userMatches = await _vibeMatchingService.findSimilarUsers(
        userId,
        limit: 5,
        minSimilarity: 0.3,
      );

      // Find matching circles
      final circleMatches = await _vibeMatchingService.findMatchingCircles(
        userId,
        limit: 3,
        minSimilarity: 0.4,
      );

      // Find matching boards
      final boardMatches = await _vibeMatchingService.findMatchingBoards(
        userId,
        limit: 8,
        minSimilarity: 0.3,
      );

      return OnboardingMatches(
        userMatches: userMatches,
        circleMatches: circleMatches,
        boardMatches: boardMatches,
      );
    } catch (e) {
      print('Error finding initial matches: $e');
      return OnboardingMatches(
        userMatches: [],
        circleMatches: [],
        boardMatches: [],
      );
    }
  }

  // ============================================================================
  // RESPONSE PROCESSING
  // ============================================================================

  List<String> _extractSelectedVibes(Map<String, dynamic> responses) {
    final vibes = <String>[];
    
    // From vibe wheel selection
    if (responses['vibeWheel'] != null) {
      final wheelData = responses['vibeWheel'] as Map<String, dynamic>;
      final selectedVibes = wheelData['selectedVibes'] as List<dynamic>?;
      if (selectedVibes != null) {
        vibes.addAll(selectedVibes.cast<String>());
      }
    }

    // From venue ratings
    if (responses['venueRatings'] != null) {
      final ratings = responses['venueRatings'] as Map<String, dynamic>;
      ratings.forEach((venue, rating) {
        if (rating is num && rating > 0.7) {
          // Extract vibes from highly rated venues
          final venueVibes = _getVenueVibes(venue);
          vibes.addAll(venueVibes);
        }
      });
    }

    // From contextual preferences
    if (responses['contextualPrefs'] != null) {
      final prefs = responses['contextualPrefs'] as Map<String, dynamic>;
      vibes.addAll(_inferVibesFromPreferences(prefs));
    }

    // Remove duplicates and return top vibes
    final uniqueVibes = vibes.toSet().toList();
    return uniqueVibes.take(8).toList();
  }

  Map<String, double> _extractVibeIntensities(Map<String, dynamic> responses) {
    final intensities = <String, double>{};

    // From vibe wheel positions
    if (responses['vibeWheel'] != null) {
      final wheelData = responses['vibeWheel'] as Map<String, dynamic>;
      final positions = wheelData['vibePositions'] as Map<String, dynamic>?;
      if (positions != null) {
        positions.forEach((vibe, position) {
          if (position is num) {
            intensities[vibe] = (position.toDouble() / 100.0).clamp(0.0, 1.0);
          }
        });
      }
    }

    // From venue rating strength
    if (responses['venueRatings'] != null) {
      final ratings = responses['venueRatings'] as Map<String, dynamic>;
      ratings.forEach((venue, rating) {
        if (rating is num) {
          final venueVibes = _getVenueVibes(venue);
          for (final vibe in venueVibes) {
            intensities[vibe] = max(intensities[vibe] ?? 0.0, rating.toDouble());
          }
        }
      });
    }

    return intensities;
  }

  Map<String, List<String>> _generateContextualMapping(Map<String, dynamic> responses) {
    final mapping = <String, List<String>>{};

    if (responses['contextualPrefs'] != null) {
      final prefs = responses['contextualPrefs'] as Map<String, dynamic>;
      
      // Map time preferences
      if (prefs['timePreferences'] != null) {
        final timePrefs = prefs['timePreferences'] as Map<String, dynamic>;
        timePrefs.forEach((time, vibes) {
          if (vibes is List) {
            mapping[time] = vibes.cast<String>();
          }
        });
      }

      // Map activity preferences
      if (prefs['activityPreferences'] != null) {
        final activityPrefs = prefs['activityPreferences'] as Map<String, dynamic>;
        activityPrefs.forEach((activity, vibes) {
          if (vibes is List) {
            mapping[activity] = vibes.cast<String>();
          }
        });
      }
    }

    return mapping;
  }

  List<String> _getVenueVibes(String venueId) {
    // This would normally query venue data or use predefined mappings
    // For now, return some default vibes based on venue type
    final venueVibeMap = {
      'cafe': ['cozy', 'aesthetic', 'breakfast'],
      'bar': ['social', 'active', 'lateNight'],
      'restaurant': ['luxurious', 'intimate', 'dateNight'],
      'park': ['outdoor', 'chill', 'wellness'],
      'gym': ['fitness', 'active', 'wellness'],
    };

    for (final entry in venueVibeMap.entries) {
      if (venueId.toLowerCase().contains(entry.key)) {
        return entry.value;
      }
    }

    return ['social', 'aesthetic']; // Default vibes
  }

  List<String> _inferVibesFromPreferences(Map<String, dynamic> prefs) {
    final vibes = <String>[];

    // Infer from stated preferences
    if (prefs['socialLevel'] == 'high') vibes.add('social');
    if (prefs['socialLevel'] == 'low') vibes.add('intimate');
    if (prefs['adventureLevel'] == 'high') vibes.add('adventurous');
    if (prefs['luxuryLevel'] == 'high') vibes.add('luxurious');
    if (prefs['fitnessLevel'] == 'high') vibes.add('fitness');
    if (prefs['workPreference'] == 'yes') vibes.add('coworking');

    return vibes;
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  OnboardingStep _getNextStep(OnboardingStep currentStep) {
    switch (currentStep) {
      case OnboardingStep.welcome:
        return OnboardingStep.vibeWheel;
      case OnboardingStep.vibeWheel:
        return OnboardingStep.contextualPrefs;
      case OnboardingStep.venueRating:
        return OnboardingStep.contextualPrefs;
      case OnboardingStep.contextualPrefs:
        return OnboardingStep.socialMatching;
      case OnboardingStep.socialMatching:
        return OnboardingStep.completed;
      case OnboardingStep.feedPreview:
        return OnboardingStep.completed;
      case OnboardingStep.completed:
        return OnboardingStep.completed;
    }
  }

  Map<String, dynamic> _generateFallbackResponses(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.vibeWheel:
        return {
          'selectedVibes': ['social', 'aesthetic', 'chill'],
          'vibePositions': {'social': 70, 'aesthetic': 60, 'chill': 50},
        };
      case OnboardingStep.venueRating:
        return {
          'venueRatings': {'popular_cafe': 0.7, 'trendy_restaurant': 0.6},
        };
      case OnboardingStep.contextualPrefs:
        return {
          'socialLevel': 'medium',
          'adventureLevel': 'medium',
          'timePreferences': {'morning': ['breakfast'], 'evening': ['social']},
        };
      default:
        return {};
    }
  }

  Future<void> _saveOnboardingState(OnboardingState state) async {
    await _firestore
        .collection('onboarding_states')
        .doc(state.userId)
        .set(state.toJson());
  }

  Future<void> _markOnboardingCompleted(
    String userId,
    OnboardingMatches matches,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'onboardingData.completedSteps': FieldValue.arrayUnion(['completed']),
      'onboardingData.completionTimestamp': FieldValue.serverTimestamp(),
      'onboardingData.initialMatches': _matchesToJson(matches),
    });
  }

  Map<String, dynamic> _matchesToJson(OnboardingMatches matches) {
    return {
      'userMatches': matches.userMatches.map((m) => m.toJson()).toList(),
      'circleMatches': matches.circleMatches.map((m) => m.toJson()).toList(),
      'boardMatches': matches.boardMatches.map((m) => m.toJson()).toList(),
    };
  }
}

// ============================================================================
// ONBOARDING DATA CLASSES
// ============================================================================

class OnboardingState {
  final String userId;
  final OnboardingStep currentStep;
  final List<OnboardingStep> completedSteps;
  final Map<String, dynamic> responses;
  final DateTime startedAt;
  final DateTime? lastUpdated;

  OnboardingState({
    required this.userId,
    required this.currentStep,
    required this.completedSteps,
    required this.responses,
    required this.startedAt,
    this.lastUpdated,
  });

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    return OnboardingState(
      userId: json['userId'] as String,
      currentStep: OnboardingStep.values.firstWhere(
        (step) => step.toString() == json['currentStep'],
        orElse: () => OnboardingStep.welcome,
      ),
      completedSteps: (json['completedSteps'] as List<dynamic>)
          .map((step) => OnboardingStep.values.firstWhere(
                (s) => s.toString() == step,
                orElse: () => OnboardingStep.welcome,
              ))
          .toList(),
      responses: Map<String, dynamic>.from(json['responses'] as Map),
      startedAt: DateTime.parse(json['startedAt'] as String),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStep': currentStep.toString(),
      'completedSteps': completedSteps.map((step) => step.toString()).toList(),
      'responses': responses,
      'startedAt': startedAt.toIso8601String(),
      'lastUpdated': (lastUpdated ?? DateTime.now()).toIso8601String(),
    };
  }

  double get progressPercentage {
    final totalSteps = OnboardingStep.values.length - 1; // Exclude 'completed'
    return completedSteps.length / totalSteps;
  }
}

class OnboardingResult {
  final bool success;
  final UserPersona? persona;
  final OnboardingMatches? initialMatches;
  final DateTime? completedAt;
  final String? error;

  OnboardingResult({
    required this.success,
    this.persona,
    this.initialMatches,
    this.completedAt,
    this.error,
  });
}

class OnboardingMatches {
  final List<UserMatch> userMatches;
  final List<CircleMatch> circleMatches;
  final List<BoardMatch> boardMatches;

  OnboardingMatches({
    required this.userMatches,
    required this.circleMatches,
    required this.boardMatches,
  });
}

enum OnboardingStep {
  welcome,
  vibeWheel,
  venueRating,
  contextualPrefs,
  socialMatching,
  feedPreview,
  completed,
}