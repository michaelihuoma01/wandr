import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/models.dart';

class UserInitializationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Initialize basic user profile data if it doesn't exist
  Future<void> initializeUserIfNeeded() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (!userDoc.exists) {
        print('Creating basic user profile for ${currentUser.uid}');
        
        final basicUserData = {
          'name': currentUser.displayName ?? 'User',
          'email': currentUser.email ?? '',
          'photoUrl': currentUser.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'followersCount': 0,
          'followingCount': 0,
          'vibeTitle': 'New Explorer',
          'bio': 'New to Wandr - discovering amazing places!',
          'trustScore': 50,
          'achievements': [],
          'interests': [],
          'profileLastUpdated': FieldValue.serverTimestamp(),
          'appVersion': '1.0.0',
          
          // Basic vibe profile
          'vibeProfile': {
            'primaryVibes': ['social', 'aesthetic'],
            'vibeScores': {},
            'vibeEvolution': [],
            'contextualVibes': {
              'contextVibeMap': {},
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          
          // Basic taste signature
          'tasteSignature': {
            'venuePreferences': {},
            'priceRangeAffinity': {},
            'socialPreference': 0.7,
            'discoveryQuotient': 0.5,
            'timePatterns': {},
            'lastCalculated': FieldValue.serverTimestamp(),
          },
          
          // Basic behavioral signals
          'behavioralSignals': {
            'vibeConsistencyScore': 0.5,
            'explorationRadius': 0.6,
            'influenceScore': 0.4,
            'activityPatterns': {},
            'lastCalculated': FieldValue.serverTimestamp(),
          },
          
          // Onboarding data
          'onboardingData': {
            'completedSteps': ['basic_setup'],
            'quizResponses': {},
            'initialMatches': [],
            'onboardingVersion': '1.0',
            'completionTimestamp': FieldValue.serverTimestamp(),
            'engagementScore': 0.8,
          },
          
          // Privacy settings
          'privacySettings': {
            'vibeVisibility': true,
            'locationSharing': true,
            'activityPrivacyLevel': 'circles',
            'allowVibeMatching': true,
            'showBehavioralInsights': false,
          },
          
          // Notification preferences
          'notificationPreferences': {
            'boardUpdateAlerts': true,
            'circleActivityNotifications': true,
            'vibeMatchAlerts': true,
            'discoveryRecommendations': true,
            'weeklyInsights': true,
            'mutedCircles': [],
          },
        };

        await _firestore.collection('users').doc(currentUser.uid).set(basicUserData);
        print('Basic user profile created successfully');
      } else {
        print('User profile already exists');
        
        // Update last login
        await _firestore.collection('users').doc(currentUser.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing user: $e');
    }
  }

  /// Update user's basic info from Firebase Auth
  Future<void> updateBasicInfo() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': currentUser.displayName ?? 'User',
        'email': currentUser.email ?? '',
        'photoUrl': currentUser.photoURL,
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating basic info: $e');
    }
  }
}