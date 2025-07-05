import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'user_persona_service.dart';
import 'dynamic_recommendation_service.dart';

class PostOnboardingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // IMMEDIATE ENGAGEMENT TRIGGERS
  // ============================================================================

  /// Trigger immediate engagement actions after onboarding completion
  Future<void> triggerImmediateEngagement(String userId) async {
    try {
      // Schedule welcome notification
      await _scheduleWelcomeNotification(userId);
      
      // Create first-day challenges
      await _createFirstDayChallenges(userId);
      
      // Set up recommendation refresh
      await _scheduleRecommendationRefresh(userId);
      
      // Initialize engagement tracking
      await _initializeEngagementTracking(userId);
      
      print('Immediate engagement triggered for user: $userId');
    } catch (e) {
      print('Error triggering immediate engagement: $e');
    }
  }

  /// Schedule welcome notification 2 hours after onboarding
  Future<void> _scheduleWelcomeNotification(String userId) async {
    final scheduledTime = DateTime.now().add(const Duration(hours: 2));
    
    await _firestore.collection('scheduled_notifications').add({
      'userId': userId,
      'type': 'welcome_back',
      'title': '3 spots matching your vibe are trending now! 🌟',
      'body': 'Check out what your new vibe tribe is discovering',
      'scheduledFor': scheduledTime,
      'status': 'pending',
      'data': {
        'action': 'open_recommendations',
        'source': 'onboarding_completion',
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Create personalized challenges for the first day
  Future<void> _createFirstDayChallenges(String userId) async {
    final challenges = [
      {
        'id': 'first_check_in',
        'title': 'Make Your First Discovery',
        'description': 'Check in to a place that matches your vibe',
        'type': 'action',
        'points': 50,
        'icon': 'location_on',
        'deadline': DateTime.now().add(const Duration(days: 1)),
        'status': 'active',
      },
      {
        'id': 'follow_circle',
        'title': 'Join Your Vibe Tribe',
        'description': 'Follow a circle that matches your interests',
        'type': 'social',
        'points': 30,
        'icon': 'group_add',
        'deadline': DateTime.now().add(const Duration(days: 1)),
        'status': 'active',
      },
      {
        'id': 'save_board',
        'title': 'Curate Your Collection',
        'description': 'Save a board that speaks to you',
        'type': 'curation',
        'points': 20,
        'icon': 'bookmark_add',
        'deadline': DateTime.now().add(const Duration(days: 1)),
        'status': 'active',
      },
    ];

    for (final challenge in challenges) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('challenges')
          .doc(challenge['id'] as String)
          .set({
        ...challenge,
        'deadline': (challenge['deadline'] as DateTime).toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============================================================================
  // PUSH NOTIFICATION SCHEDULING
  // ============================================================================

  /// Set up personalized notification schedule
  Future<void> setupNotificationSchedule(String userId, UserPersona persona) async {
    try {
      final schedule = _generatePersonalizedSchedule(persona);
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notification_preferences')
          .doc('schedule')
          .set({
        'personalizedSchedule': schedule,
        'timezone': DateTime.now().timeZoneName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Schedule first week notifications
      await _scheduleFirstWeekNotifications(userId, persona);
      
    } catch (e) {
      print('Error setting up notification schedule: $e');
    }
  }

  Map<String, dynamic> _generatePersonalizedSchedule(UserPersona persona) {
    final schedule = <String, dynamic>{};
    
    // Based on persona peak times
    for (final entry in persona.timePreferences.entries) {
      if (entry.value > 0.7) {
        schedule[entry.key] = {
          'enabled': true,
          'preference_score': entry.value,
          'notification_types': _getNotificationTypesForTime(entry.key, persona),
        };
      }
    }
    
    return schedule;
  }

  List<String> _getNotificationTypesForTime(String timeOfDay, UserPersona persona) {
    switch (timeOfDay) {
      case 'morning':
        return ['daily_recommendations', 'breakfast_spots', 'workout_spots'];
      case 'afternoon':
        return ['trending_places', 'friend_activity', 'work_spaces'];
      case 'evening':
        return ['dinner_suggestions', 'social_events', 'date_spots'];
      case 'night':
        return ['nightlife', 'late_night_eats', 'events'];
      default:
        return ['recommendations'];
    }
  }

  Future<void> _scheduleFirstWeekNotifications(String userId, UserPersona persona) async {
    final notifications = [
      // Day 1 - 2 hours after onboarding
      _createNotification(
        userId,
        'welcome_back',
        '3 ${persona.primaryVibes.first} spots are trending near you! 🎯',
        'Your vibe tribe is discovering amazing places',
        DateTime.now().add(const Duration(hours: 2)),
        {'action': 'open_recommendations'},
      ),
      
      // Day 2 - Based on peak time
      _createNotification(
        userId,
        'daily_discovery',
        'Ready for today\'s ${persona.name.toLowerCase()} adventure? ✨',
        'We found the perfect spots for your vibe',
        DateTime.now().add(Duration(days: 1, hours: _getOptimalHour(persona))),
        {'action': 'open_feed'},
      ),
      
      // Day 3 - Social engagement
      _createNotification(
        userId,
        'social_connection',
        'Your vibe twin just shared an amazing discovery! 👯‍♀️',
        'Connect with like-minded explorers',
        DateTime.now().add(Duration(days: 2, hours: _getOptimalHour(persona))),
        {'action': 'open_social'},
      ),
      
      // Day 7 - Weekly insights
      _createNotification(
        userId,
        'weekly_insights',
        'Your first week of discoveries was amazing! 📊',
        'See your vibe journey and earn your first badge',
        DateTime.now().add(Duration(days: 6, hours: _getOptimalHour(persona))),
        {'action': 'open_insights'},
      ),
    ];

    for (final notification in notifications) {
      await _firestore.collection('scheduled_notifications').add(notification);
    }
  }

  int _getOptimalHour(UserPersona persona) {
    // Return optimal hour based on persona preferences
    final morningScore = persona.timePreferences['morning'] ?? 0.0;
    final afternoonScore = persona.timePreferences['afternoon'] ?? 0.0;
    final eveningScore = persona.timePreferences['evening'] ?? 0.0;
    
    if (morningScore > afternoonScore && morningScore > eveningScore) {
      return 9; // 9 AM
    } else if (eveningScore > afternoonScore) {
      return 18; // 6 PM
    } else {
      return 14; // 2 PM
    }
  }

  // ============================================================================
  // FIRST WEEK OPTIMIZATION
  // ============================================================================

  /// Track and optimize user engagement in the first week
  Future<void> initializeFirstWeekTracking(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('engagement_tracking')
        .doc('first_week')
        .set({
      'startDate': FieldValue.serverTimestamp(),
      'targetMetrics': {
        'first_check_in': false,
        'first_board_save': false,
        'first_circle_follow': false,
        'recommendations_viewed': 0,
        'social_connections': 0,
        'time_in_app': 0, // seconds
      },
      'dailyMetrics': {},
      'optimizations': [],
      'status': 'active',
    });
  }

  /// Update first week metrics
  Future<void> updateFirstWeekMetrics(
    String userId,
    String metric,
    dynamic value,
  ) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('engagement_tracking')
        .doc('first_week')
        .update({
      'targetMetrics.$metric': value,
      'dailyMetrics.$today.$metric': value,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    // Check if optimization is needed
    await _checkForOptimizationOpportunities(userId);
  }

  Future<void> _checkForOptimizationOpportunities(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('engagement_tracking')
          .doc('first_week')
          .get();

      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final metrics = data['targetMetrics'] as Map<String, dynamic>? ?? {};
      final startDate = (data['startDate'] as Timestamp).toDate();
      final daysSinceStart = DateTime.now().difference(startDate).inDays;

      // Optimization triggers
      if (daysSinceStart >= 2 && !(metrics['first_check_in'] ?? false)) {
        await _triggerCheckInOptimization(userId);
      }

      if (daysSinceStart >= 3 && (metrics['recommendations_viewed'] ?? 0) < 5) {
        await _triggerRecommendationOptimization(userId);
      }

      if (daysSinceStart >= 4 && (metrics['social_connections'] ?? 0) < 1) {
        await _triggerSocialOptimization(userId);
      }

    } catch (e) {
      print('Error checking optimization opportunities: $e');
    }
  }

  Future<void> _triggerCheckInOptimization(String userId) async {
    // Send targeted notification to encourage first check-in
    await _createAndScheduleNotification(
      userId,
      'check_in_encouragement',
      'Your perfect spot is just around the corner! 📍',
      'Complete your first check-in and earn 50 vibe points',
      DateTime.now().add(const Duration(hours: 1)),
      {'action': 'open_nearby_recommendations', 'campaign': 'first_check_in'},
    );
  }

  Future<void> _triggerRecommendationOptimization(String userId) async {
    // Update recommendation algorithm to show more engaging content
    await _createAndScheduleNotification(
      userId,
      'recommendation_refresh',
      'We updated your feed with trending discoveries! 🔥',
      'See what\'s hot in your vibe community',
      DateTime.now().add(const Duration(minutes: 30)),
      {'action': 'open_feed', 'campaign': 'engagement_boost'},
    );
  }

  Future<void> _triggerSocialOptimization(String userId) async {
    // Encourage social connections
    await _createAndScheduleNotification(
      userId,
      'social_boost',
      'Meet your vibe twin! You have 95% compatibility 🎯',
      'Connect with someone who shares your taste',
      DateTime.now().add(const Duration(hours: 2)),
      {'action': 'open_user_matches', 'campaign': 'social_connection'},
    );
  }

  // ============================================================================
  // PROGRESSIVE PROFILING
  // ============================================================================

  /// Set up progressive profiling to gather more data over time
  Future<void> setupProgressiveProfiling(String userId) async {
    final profilingSchedule = [
      {
        'day': 3,
        'prompt': 'location_preferences',
        'title': 'What\'s your home base?',
        'description': 'Help us suggest places in your area',
      },
      {
        'day': 7,
        'prompt': 'dietary_preferences',
        'title': 'Any dietary preferences?',
        'description': 'Get better food recommendations',
      },
      {
        'day': 14,
        'prompt': 'budget_preferences',
        'title': 'What\'s your comfort zone?',
        'description': 'Price range preferences for better matches',
      },
      {
        'day': 30,
        'prompt': 'advanced_vibes',
        'title': 'Ready to explore new vibes?',
        'description': 'Expand your taste profile',
      },
    ];

    for (final prompt in profilingSchedule) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('progressive_prompts')
          .doc(prompt['prompt'] as String)
          .set({
        ...prompt,
        'scheduledFor': DateTime.now().add(Duration(days: prompt['day'] as int)),
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ============================================================================
  // VIBE BADGE SYSTEM
  // ============================================================================

  /// Initialize badge system for user
  Future<void> initializeBadgeSystem(String userId, UserPersona persona) async {
    final initialBadges = [
      VibeBadge(
        id: 'onboarding_complete',
        name: 'Vibe Explorer',
        description: 'Completed the vibe discovery journey',
        icon: 'explore',
        rarity: BadgeRarity.common,
        unlockedAt: DateTime.now(),
        progress: 1.0,
      ),
      VibeBadge(
        id: 'persona_${persona.name.toLowerCase().replaceAll(' ', '_')}',
        name: '${persona.emoji} ${persona.name}',
        description: 'Embraced the ${persona.name.toLowerCase()} lifestyle',
        icon: 'psychology',
        rarity: BadgeRarity.special,
        unlockedAt: DateTime.now(),
        progress: 1.0,
      ),
    ];

    for (final badge in initialBadges) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badge.id)
          .set(badge.toJson());
    }

    // Set up badge tracking for future achievements
    await _setupBadgeTracking(userId, persona);
  }

  Future<void> _setupBadgeTracking(String userId, UserPersona persona) async {
    final trackingBadges = [
      {
        'id': 'first_check_in',
        'name': 'First Discovery',
        'description': 'Made your first check-in',
        'trigger': 'check_in_count >= 1',
        'icon': 'location_on',
        'rarity': 'common',
      },
      {
        'id': 'social_butterfly',
        'name': 'Social Butterfly',
        'description': 'Connected with 5 like-minded explorers',
        'trigger': 'connections >= 5',
        'icon': 'people',
        'rarity': 'uncommon',
      },
      {
        'id': 'curator',
        'name': 'Taste Curator',
        'description': 'Saved 10 amazing boards',
        'trigger': 'boards_saved >= 10',
        'icon': 'collections_bookmark',
        'rarity': 'uncommon',
      },
      {
        'id': 'local_legend',
        'name': 'Local Legend',
        'description': 'Discovered 25 places in your city',
        'trigger': 'local_check_ins >= 25',
        'icon': 'star',
        'rarity': 'rare',
      },
    ];

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('badge_tracking')
        .doc('progress')
        .set({
      'badges': trackingBadges,
      'counters': {
        'check_in_count': 0,
        'connections': 0,
        'boards_saved': 0,
        'local_check_ins': 0,
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  Map<String, dynamic> _createNotification(
    String userId,
    String type,
    String title,
    String body,
    DateTime scheduledFor,
    Map<String, dynamic> data,
  ) {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'scheduledFor': scheduledFor,
      'status': 'pending',
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _createAndScheduleNotification(
    String userId,
    String type,
    String title,
    String body,
    DateTime scheduledFor,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('scheduled_notifications').add(
      _createNotification(userId, type, title, body, scheduledFor, data),
    );
  }

  Future<void> _scheduleRecommendationRefresh(String userId) async {
    // Schedule recommendation refresh for peak hours
    final refreshTimes = [
      DateTime.now().add(const Duration(hours: 6)),  // 6 hours later
      DateTime.now().add(const Duration(hours: 24)), // Next day
      DateTime.now().add(const Duration(hours: 72)), // 3 days later
    ];

    for (final time in refreshTimes) {
      await _firestore.collection('scheduled_tasks').add({
        'userId': userId,
        'type': 'refresh_recommendations',
        'scheduledFor': time,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _initializeEngagementTracking(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('engagement_metrics')
        .doc('current')
        .set({
      'onboarding_completed_at': FieldValue.serverTimestamp(),
      'first_week_goals': {
        'first_check_in': false,
        'first_save': false,
        'first_follow': false,
        'first_interaction': false,
      },
      'weekly_targets': {
        'check_ins': 3,
        'discoveries': 5,
        'social_interactions': 2,
      },
      'status': 'active',
    });
  }
}

// ============================================================================
// BADGE SYSTEM CLASSES
// ============================================================================

class VibeBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeRarity rarity;
  final DateTime? unlockedAt;
  final double progress;

  VibeBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    this.unlockedAt,
    required this.progress,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'rarity': rarity.toString(),
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
    };
  }

  factory VibeBadge.fromJson(Map<String, dynamic> json) {
    return VibeBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      rarity: BadgeRarity.values.firstWhere(
        (r) => r.toString() == json['rarity'],
        orElse: () => BadgeRarity.common,
      ),
      unlockedAt: json['unlockedAt'] != null 
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: (json['progress'] as num).toDouble(),
    );
  }
}

enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  special,
}