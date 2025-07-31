// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/vibe_tag_models.dart';
// import '../models/models.dart';
// import 'vibe_tag_service.dart';
// import 'shared_utilities_service.dart';
// import 'auth_service.dart';

// // ============================================================================
// // COMPREHENSIVE VIBE SYSTEM - For Gen Z & Millennials 🔥
// // Covers ALL aspects of young adult lifestyle
// // ============================================================================

// class ComprehensiveVibeSystem {
//   static final ComprehensiveVibeSystem _instance = ComprehensiveVibeSystem._internal();
//   factory ComprehensiveVibeSystem() => _instance;
//   ComprehensiveVibeSystem._internal();

//   final VibeTagService _vibeTagService = VibeTagService();
//   final SharedUtilitiesService _utils = SharedUtilitiesService();
//   final AuthService _authService = AuthService();

//   // ============================================================================
//   // COMPREHENSIVE VIBE CATEGORIES - Everything Young Adults Do
//   // ============================================================================

//   static const Map<String, Map<String, dynamic>> vibeCategories = {
//     'active': {
//       'displayName': 'Active & Fitness',
//       'description': 'Get moving and stay healthy',
//       'color': '#FF5722',
//       'icon': 'fitness',
//       'emoji': '🏃‍♂️',
//     },
//     'nightlife': {
//       'displayName': 'Nightlife & Party',
//       'description': 'Night out vibes and party scenes',
//       'color': '#9C27B0',
//       'icon': 'musical-notes',
//       'emoji': '🌙',
//     },
//     'social': {
//       'displayName': 'Social & Hangouts',
//       'description': 'Friend groups and social activities',
//       'color': '#2196F3',
//       'icon': 'people',
//       'emoji': '👥',
//     },
//     'creative': {
//       'displayName': 'Creative & Arts',
//       'description': 'Express yourself and explore creativity',
//       'color': '#FF9800',
//       'icon': 'palette',
//       'emoji': '🎨',
//     },
//     'foodie': {
//       'displayName': 'Food & Drinks',
//       'description': 'Culinary adventures and taste experiences',
//       'color': '#4CAF50',
//       'icon': 'restaurant',
//       'emoji': '🍽️',
//     },
//     'adventure': {
//       'displayName': 'Adventure & Explore',
//       'description': 'Discover new places and experiences',
//       'color': '#00BCD4',
//       'icon': 'compass',
//       'emoji': '🗺️',
//     },
//     'chill': {
//       'displayName': 'Chill & Relax',
//       'description': 'Unwind and take it easy',
//       'color': '#607D8B',
//       'icon': 'leaf',
//       'emoji': '😌',
//     },
//     'romantic': {
//       'displayName': 'Date & Romance',
//       'description': 'Perfect for dates and romantic moments',
//       'color': '#E91E63',
//       'icon': 'heart',
//       'emoji': '💕',
//     },
//     'work_life': {
//       'displayName': 'Work & Productivity',
//       'description': 'Productive spaces and networking',
//       'color': '#795548',
//       'icon': 'briefcase',
//       'emoji': '💼',
//     },
//     'seasonal': {
//       'displayName': 'Seasonal & Events',
//       'description': 'Time-specific and seasonal activities',
//       'color': '#8BC34A',
//       'icon': 'calendar',
//       'emoji': '📅',
//     },
//   };

//   // ============================================================================
//   // COMPREHENSIVE VIBE TAGS - 100+ Lifestyle Vibes
//   // ============================================================================

//   static const Map<String, Map<String, dynamic>> comprehensiveVibeTags = {
    
//     // 🏃‍♂️ ACTIVE & FITNESS VIBES
//     'gym_warrior': {
//       'displayName': 'Gym Warrior',
//       'description': 'High-intensity workouts and fitness goals',
//       'category': 'active',
//       'synonyms': ['gym', 'fitness', 'workout', 'strength', 'gains'],
//       'color': '#F44336',
//       'icon': 'barbell',
//       'contexts': ['morning', 'evening', 'weekend', 'motivation']
//     },
//     'runner_high': {
//       'displayName': 'Runner\'s High',
//       'description': 'Running, jogging, and cardio adventures',
//       'category': 'active',
//       'synonyms': ['running', 'jogging', 'cardio', 'marathon', 'trail'],
//       'color': '#FF5722',
//       'icon': 'walk',
//       'contexts': ['morning', 'park', 'outdoor', 'solo', 'group']
//     },
//     'adventure_sports': {
//       'displayName': 'Adrenaline Rush',
//       'description': 'Extreme sports and thrilling activities',
//       'category': 'active',
//       'synonyms': ['climbing', 'surfing', 'skateboarding', 'extreme', 'adrenaline'],
//       'color': '#FF9800',
//       'icon': 'trending-up',
//       'contexts': ['weekend', 'adventure', 'outdoor', 'challenge']
//     },
//     'yoga_zen': {
//       'displayName': 'Yoga & Mindfulness',
//       'description': 'Mind-body connection and inner peace',
//       'category': 'active',
//       'synonyms': ['yoga', 'meditation', 'mindfulness', 'zen', 'wellness'],
//       'color': '#8BC34A',
//       'icon': 'leaf',
//       'contexts': ['morning', 'evening', 'peace', 'self-care']
//     },
//     'team_sports': {
//       'displayName': 'Team Spirit',
//       'description': 'Group sports and competitive games',
//       'category': 'active',
//       'synonyms': ['basketball', 'soccer', 'volleyball', 'team', 'competitive'],
//       'color': '#2196F3',
//       'icon': 'trophy',
//       'contexts': ['weekend', 'group', 'competitive', 'social']
//     },
//     'hiking_nature': {
//       'displayName': 'Nature Explorer',
//       'description': 'Hiking trails and outdoor adventures',
//       'category': 'active',
//       'synonyms': ['hiking', 'trails', 'nature', 'mountains', 'outdoor'],
//       'color': '#4CAF50',
//       'icon': 'leaf-outline',
//       'contexts': ['weekend', 'outdoor', 'adventure', 'fresh_air']
//     },

//     // 🌙 NIGHTLIFE & PARTY VIBES
//     'club_scene': {
//       'displayName': 'Club Life',
//       'description': 'Dance floors, DJs, and late-night energy',
//       'category': 'nightlife',
//       'synonyms': ['club', 'dancing', 'DJ', 'party', 'nightclub'],
//       'color': '#9C27B0',
//       'icon': 'musical-notes',
//       'contexts': ['night', 'weekend', 'dancing', 'energy', 'group']
//     },
//     'rooftop_vibes': {
//       'displayName': 'Rooftop Nights',
//       'description': 'Sky-high bars with city views',
//       'category': 'nightlife',
//       'synonyms': ['rooftop', 'skybar', 'views', 'cocktails', 'elevated'],
//       'color': '#673AB7',
//       'icon': 'trending-up',
//       'contexts': ['night', 'drinks', 'views', 'upscale', 'date']
//     },
//     'underground_scene': {
//       'displayName': 'Underground Scene',
//       'description': 'Hidden gems and alternative nightlife',
//       'category': 'nightlife',
//       'synonyms': ['underground', 'alternative', 'indie', 'speakeasy', 'hidden'],
//       'color': '#424242',
//       'icon': 'eye-off',
//       'contexts': ['night', 'alternative', 'unique', 'discovery']
//     },
//     'beach_club': {
//       'displayName': 'Beach Club',
//       'description': 'Ocean vibes with drinks and music',
//       'category': 'nightlife',
//       'synonyms': ['beach', 'ocean', 'pool party', 'summer', 'sunset'],
//       'color': '#00BCD4',
//       'icon': 'water',
//       'contexts': ['summer', 'beach', 'sunset', 'vacation', 'group']
//     },
//     'karaoke_night': {
//       'displayName': 'Karaoke Star',
//       'description': 'Sing your heart out with friends',
//       'category': 'nightlife',
//       'synonyms': ['karaoke', 'singing', 'performance', 'fun', 'group'],
//       'color': '#E91E63',
//       'icon': 'mic',
//       'contexts': ['night', 'group', 'fun', 'performance', 'social']
//     },

//     // 👥 SOCIAL & HANGOUT VIBES
//     'squad_goals': {
//       'displayName': 'Squad Goals',
//       'description': 'Perfect for your main friend group',
//       'category': 'social',
//       'synonyms': ['friends', 'squad', 'group', 'crew', 'gang'],
//       'color': '#FF9800',
//       'icon': 'people',
//       'contexts': ['group', 'friends', 'weekend', 'fun', 'memories']
//     },
//     'game_night': {
//       'displayName': 'Game Night',
//       'description': 'Board games, video games, and competitions',
//       'category': 'social',
//       'synonyms': ['games', 'arcade', 'bowling', 'mini golf', 'competition'],
//       'color': '#3F51B5',
//       'icon': 'game-controller',
//       'contexts': ['group', 'indoor', 'competition', 'fun', 'casual']
//     },
//     'networking': {
//       'displayName': 'Network & Connect',
//       'description': 'Meet new people and make connections',
//       'category': 'social',
//       'synonyms': ['networking', 'meetup', 'professional', 'connections', 'career'],
//       'color': '#607D8B',
//       'icon': 'people-outline',
//       'contexts': ['professional', 'career', 'learning', 'growth']
//     },
//     'double_date': {
//       'displayName': 'Double Date',
//       'description': 'Perfect for couples hanging out together',
//       'category': 'social',
//       'synonyms': ['double date', 'couples', 'group date', 'relationship'],
//       'color': '#E91E63',
//       'icon': 'heart',
//       'contexts': ['date', 'couples', 'group', 'romantic']
//     },
//     'party_host': {
//       'displayName': 'Party Starter',
//       'description': 'Places that get the party going',
//       'category': 'social',
//       'synonyms': ['party', 'celebration', 'birthday', 'event', 'festive'],
//       'color': '#FF5722',
//       'icon': 'balloon',
//       'contexts': ['celebration', 'party', 'group', 'festive', 'special']
//     },

//     // 🎨 CREATIVE & ARTS VIBES
//     'art_gallery': {
//       'displayName': 'Art & Culture',
//       'description': 'Museums, galleries, and cultural experiences',
//       'category': 'creative',
//       'synonyms': ['art', 'gallery', 'museum', 'culture', 'exhibition'],
//       'color': '#9C27B0',
//       'icon': 'palette',
//       'contexts': ['weekend', 'culture', 'learning', 'inspiration', 'date']
//     },
//     'live_music': {
//       'displayName': 'Live Music',
//       'description': 'Concerts, gigs, and live performances',
//       'category': 'creative',
//       'synonyms': ['concert', 'live music', 'band', 'performance', 'venue'],
//       'color': '#FF6B35',
//       'icon': 'musical-note',
//       'contexts': ['night', 'music', 'performance', 'energy', 'discovery']
//     },
//     'diy_craft': {
//       'displayName': 'DIY & Craft',
//       'description': 'Hands-on creative workshops and activities',
//       'category': 'creative',
//       'synonyms': ['workshop', 'crafts', 'DIY', 'pottery', 'creative'],
//       'color': '#8BC34A',
//       'icon': 'construct',
//       'contexts': ['weekend', 'learning', 'hands-on', 'creative', 'group']
//     },
//     'photography': {
//       'displayName': 'Photo Perfect',
//       'description': 'Instagram-worthy spots and photo opportunities',
//       'category': 'creative',
//       'synonyms': ['photography', 'instagram', 'aesthetic', 'photogenic', 'scenic'],
//       'color': '#FF9800',
//       'icon': 'camera',
//       'contexts': ['instagram', 'aesthetic', 'photo', 'memory', 'share']
//     },

//     // 🍽️ FOODIE VIBES
//     'food_adventure': {
//       'displayName': 'Food Explorer',
//       'description': 'Try new cuisines and unique dining experiences',
//       'category': 'foodie',
//       'synonyms': ['foodie', 'cuisine', 'unique', 'ethnic', 'authentic'],
//       'color': '#FF5722',
//       'icon': 'restaurant',
//       'contexts': ['dining', 'adventure', 'discovery', 'authentic', 'experience']
//     },
//     'brunch_squad': {
//       'displayName': 'Brunch Vibes',
//       'description': 'Weekend brunch with bottomless mimosas',
//       'category': 'foodie',
//       'synonyms': ['brunch', 'mimosas', 'weekend', 'leisurely', 'social'],
//       'color': '#FFEB3B',
//       'icon': 'wine',
//       'contexts': ['weekend', 'brunch', 'social', 'leisurely', 'group']
//     },
//     'late_night_eats': {
//       'displayName': 'Late Night Bites',
//       'description': 'After-party food and midnight cravings',
//       'category': 'foodie',
//       'synonyms': ['late night', 'midnight', 'after party', 'cravings', '24/7'],
//       'color': '#9C27B0',
//       'icon': 'moon',
//       'contexts': ['late_night', 'after_party', 'cravings', 'casual']
//     },
//     'craft_cocktails': {
//       'displayName': 'Craft Cocktails',
//       'description': 'Artisanal drinks and mixology experiences',
//       'category': 'foodie',
//       'synonyms': ['cocktails', 'mixology', 'craft', 'artisanal', 'bartender'],
//       'color': '#8E24AA',
//       'icon': 'wine',
//       'contexts': ['evening', 'upscale', 'craft', 'social', 'date']
//     },
//     'food_truck': {
//       'displayName': 'Street Food',
//       'description': 'Food trucks, markets, and casual street eats',
//       'category': 'foodie',
//       'synonyms': ['food truck', 'street food', 'market', 'casual', 'authentic'],
//       'color': '#FF9800',
//       'icon': 'car',
//       'contexts': ['casual', 'outdoor', 'authentic', 'affordable', 'quick']
//     },

//     // 🗺️ ADVENTURE & EXPLORE VIBES
//     'hidden_gems': {
//       'displayName': 'Hidden Gems',
//       'description': 'Secret spots and off-the-beaten-path discoveries',
//       'category': 'adventure',
//       'synonyms': ['hidden', 'secret', 'discovery', 'unique', 'local'],
//       'color': '#795548',
//       'icon': 'map',
//       'contexts': ['discovery', 'unique', 'local', 'exploration', 'secret']
//     },
//     'urban_explorer': {
//       'displayName': 'City Explorer',
//       'description': 'Urban adventures and city discoveries',
//       'category': 'adventure',
//       'synonyms': ['urban', 'city', 'downtown', 'exploration', 'walkable'],
//       'color': '#607D8B',
//       'icon': 'business',
//       'contexts': ['city', 'walking', 'exploration', 'urban', 'discovery']
//     },
//     'road_trip': {
//       'displayName': 'Road Trip Ready',
//       'description': 'Perfect stops for adventures and road trips',
//       'category': 'adventure',
//       'synonyms': ['road trip', 'drive', 'journey', 'scenic', 'travel'],
//       'color': '#2196F3',
//       'icon': 'car-sport',
//       'contexts': ['travel', 'journey', 'scenic', 'adventure', 'group']
//     },
//     'spontaneous': {
//       'displayName': 'Spontaneous',
//       'description': 'Last-minute plans and impromptu adventures',
//       'category': 'adventure',
//       'synonyms': ['spontaneous', 'last minute', 'impromptu', 'flexible', 'random'],
//       'color': '#FF6B35',
//       'icon': 'flash',
//       'contexts': ['spontaneous', 'flexible', 'last_minute', 'adventure']
//     },

//     // 😌 CHILL & RELAX VIBES
//     'cozy_corner': {
//       'displayName': 'Cozy Vibes',
//       'description': 'Warm, comfortable spaces to unwind',
//       'category': 'chill',
//       'synonyms': ['cozy', 'comfortable', 'relaxing', 'warm', 'intimate'],
//       'color': '#8D6E63',
//       'icon': 'home',
//       'contexts': ['relaxing', 'comfortable', 'intimate', 'quiet', 'peaceful']
//     },
//     'study_spot': {
//       'displayName': 'Study Sanctuary',
//       'description': 'Perfect for studying, reading, or working',
//       'category': 'chill',
//       'synonyms': ['study', 'quiet', 'wifi', 'productive', 'focus'],
//       'color': '#607D8B',
//       'icon': 'library',
//       'contexts': ['study', 'quiet', 'productive', 'wifi', 'focus']
//     },
//     'self_care': {
//       'displayName': 'Self-Care Sunday',
//       'description': 'Spa days, wellness, and me-time activities',
//       'category': 'chill',
//       'synonyms': ['spa', 'wellness', 'self-care', 'relaxation', 'pamper'],
//       'color': '#E1BEE7',
//       'icon': 'flower',
//       'contexts': ['relaxation', 'wellness', 'self_care', 'peaceful', 'rejuvenating']
//     },
//     'sunset_spot': {
//       'displayName': 'Golden Hour',
//       'description': 'Perfect sunset and sunrise viewing spots',
//       'category': 'chill',
//       'synonyms': ['sunset', 'sunrise', 'golden hour', 'scenic', 'peaceful'],
//       'color': '#FFB74D',
//       'icon': 'sunny',
//       'contexts': ['sunset', 'scenic', 'peaceful', 'romantic', 'photo']
//     },

//     // 💕 ROMANTIC & DATE VIBES
//     'first_date': {
//       'displayName': 'First Date Perfect',
//       'description': 'Safe, comfortable spots for getting to know someone',
//       'category': 'romantic',
//       'synonyms': ['first date', 'casual', 'comfortable', 'conversation', 'safe'],
//       'color': '#FF8A80',
//       'icon': 'heart-outline',
//       'contexts': ['first_date', 'casual', 'conversation', 'comfortable', 'safe']
//     },
//     'anniversary': {
//       'displayName': 'Anniversary Special',
//       'description': 'Celebrate love and special relationship milestones',
//       'category': 'romantic',
//       'synonyms': ['anniversary', 'special', 'celebration', 'romantic', 'milestone'],
//       'color': '#C2185B',
//       'icon': 'heart',
//       'contexts': ['anniversary', 'special', 'celebration', 'romantic', 'upscale']
//     },
//     'proposal_ready': {
//       'displayName': 'Proposal Perfect',
//       'description': 'Breathtaking spots for life\'s biggest moments',
//       'category': 'romantic',
//       'synonyms': ['proposal', 'engagement', 'special', 'memorable', 'scenic'],
//       'color': '#AD1457',
//       'icon': 'diamond',
//       'contexts': ['proposal', 'special', 'memorable', 'scenic', 'private']
//     },
//     'cute_couple': {
//       'displayName': 'Couple Goals',
//       'description': 'Instagram-worthy spots for cute couple content',
//       'category': 'romantic',
//       'synonyms': ['couple', 'cute', 'instagram', 'photo', 'aesthetic'],
//       'color': '#F48FB1',
//       'icon': 'camera',
//       'contexts': ['couple', 'photo', 'instagram', 'aesthetic', 'cute']
//     },

//     // 💼 WORK & PRODUCTIVITY VIBES
//     'digital_nomad': {
//       'displayName': 'Digital Nomad',
//       'description': 'Remote work-friendly with great WiFi and vibes',
//       'category': 'work_life',
//       'synonyms': ['remote work', 'digital nomad', 'wifi', 'laptop', 'productive'],
//       'color': '#37474F',
//       'icon': 'laptop',
//       'contexts': ['work', 'productive', 'wifi', 'quiet', 'comfortable']
//     },
//     'business_meeting': {
//       'displayName': 'Business Casual',
//       'description': 'Professional atmosphere for work meetings',
//       'category': 'work_life',
//       'synonyms': ['business', 'meeting', 'professional', 'networking', 'corporate'],
//       'color': '#455A64',
//       'icon': 'briefcase',
//       'contexts': ['business', 'professional', 'networking', 'meeting', 'quiet']
//     },
//     'creative_workspace': {
//       'displayName': 'Creative Hub',
//       'description': 'Inspiring spaces for creative work and brainstorming',
//       'category': 'work_life',
//       'synonyms': ['creative', 'inspiring', 'brainstorm', 'innovative', 'artistic'],
//       'color': '#FF7043',
//       'icon': 'bulb',
//       'contexts': ['creative', 'inspiring', 'brainstorm', 'innovative', 'collaborative']
//     },

//     // 📅 SEASONAL & EVENT VIBES
//     'summer_vibes': {
//       'displayName': 'Summer Vibes',
//       'description': 'Hot weather activities and summer fun',
//       'category': 'seasonal',
//       'synonyms': ['summer', 'hot', 'outdoor', 'beach', 'festival'],
//       'color': '#FFD54F',
//       'icon': 'sunny',
//       'contexts': ['summer', 'hot', 'outdoor', 'beach', 'festival', 'vacation']
//     },
//     'winter_cozy': {
//       'displayName': 'Winter Warmth',
//       'description': 'Cozy indoor spots for cold weather',
//       'category': 'seasonal',
//       'synonyms': ['winter', 'cozy', 'warm', 'indoor', 'fireplace'],
//       'color': '#81C784',
//       'icon': 'snow',
//       'contexts': ['winter', 'cozy', 'warm', 'indoor', 'comfort']
//     },
//     'holiday_spirit': {
//       'displayName': 'Holiday Magic',
//       'description': 'Festive spots during holiday seasons',
//       'category': 'seasonal',
//       'synonyms': ['holiday', 'festive', 'celebration', 'christmas', 'new year'],
//       'color': '#C62828',
//       'icon': 'gift',
//       'contexts': ['holiday', 'festive', 'celebration', 'special', 'magical']
//     },
//     'festival_ready': {
//       'displayName': 'Festival Life',
//       'description': 'Music festivals, food festivals, and outdoor events',
//       'category': 'seasonal',
//       'synonyms': ['festival', 'event', 'music', 'outdoor', 'crowd'],
//       'color': '#8E24AA',
//       'icon': 'musical-notes',
//       'contexts': ['festival', 'music', 'outdoor', 'crowd', 'energy', 'weekend']
//     },
//   };

//   // ============================================================================
//   // DYNAMIC VIBE SELECTION SYSTEM
//   // ============================================================================

//   /// Get vibe suggestions based on current context (time, weather, location, etc.)
//   Future<List<Map<String, dynamic>>> getContextualVibeSuggestions({
//     required String userId,
//     DateTime? currentTime,
//     String? weather,
//     String? location,
//     int limit = 12,
//   }) async {
//     try {
//       final now = currentTime ?? DateTime.now();
//       final hour = now.hour;
//       final dayOfWeek = now.weekday;
//       final isWeekend = dayOfWeek >= 6;
      
//       // Get user's existing vibes to personalize suggestions
//       final userVibes = await _vibeTagService.getEntityVibeAssociations(userId, 'user');
//       final userVibeIds = userVibes.map((v) => v.vibeTagId).toSet();
      
//       final suggestions = <Map<String, dynamic>>[];
      
//       // Analyze all vibe tags and score them based on context
//       for (final entry in comprehensiveVibeTags.entries) {
//         final vibeId = entry.key;
//         final vibeData = entry.value;
//         final contexts = vibeData['contexts'] as List<String>;
        
//         double score = 0.0;
        
//         // Time-based scoring
//         if (hour >= 6 && hour < 12 && contexts.contains('morning')) score += 0.3;
//         if (hour >= 12 && hour < 17 && contexts.contains('afternoon')) score += 0.3;
//         if (hour >= 17 && hour < 22 && contexts.contains('evening')) score += 0.3;
//         if (hour >= 22 || hour < 6 && contexts.contains('night')) score += 0.3;
        
//         // Weekend boost
//         if (isWeekend && contexts.contains('weekend')) score += 0.2;
//         if (!isWeekend && contexts.contains('weekday')) score += 0.2;
        
//         // Weather-based scoring
//         if (weather != null) {
//           if (weather.contains('sunny') && contexts.contains('outdoor')) score += 0.2;
//           if (weather.contains('rain') && contexts.contains('indoor')) score += 0.2;
//           if (weather.contains('hot') && contexts.contains('summer')) score += 0.2;
//           if (weather.contains('cold') && contexts.contains('cozy')) score += 0.2;
//         }
        
//         // User preference boost (if they already have similar vibes)
//         final category = vibeData['category'] as String;
//         final userHasSimilarVibes = userVibes.any((v) => 
//           comprehensiveVibeTags[v.vibeTagId]?['category'] == category);
//         if (userHasSimilarVibes) score += 0.15;
        
//         // Avoid suggesting vibes user already has
//         if (userVibeIds.contains(vibeId)) score -= 0.5;
        
//         if (score > 0.1) { // Only include viable suggestions
//           suggestions.add({
//             'vibeId': vibeId,
//             'vibeData': vibeData,
//             'score': score,
//             'category': category,
//             'isNew': !userVibeIds.contains(vibeId),
//           });
//         }
//       }
      
//       // Sort by score and return top suggestions
//       suggestions.sort((a, b) => b['score'].compareTo(a['score']));
//       return suggestions.take(limit).toList();
      
//     } catch (e) {
//       print('Error getting contextual vibe suggestions: $e');
//       return [];
//     }
//   }

//   /// Get trending vibes based on what's popular among similar users
//   Future<List<Map<String, dynamic>>> getTrendingVibes({
//     required String userId,
//     String? ageGroup, // '18-24', '25-30', '31-35'
//     String? location,
//     int limit = 10,
//   }) async {
//     try {
//       // This would typically query usage analytics from Firebase
//       // For now, return some popular vibes based on Gen Z/Millennial trends
//       final trendingVibeIds = [
//         'club_scene', 'brunch_squad', 'photography', 'food_adventure',
//         'squad_goals', 'craft_cocktails', 'live_music', 'rooftop_vibes',
//         'hiking_nature', 'game_night', 'first_date', 'hidden_gems'
//       ];
      
//       final trending = <Map<String, dynamic>>[];
      
//       for (final vibeId in trendingVibeIds.take(limit)) {
//         final vibeData = comprehensiveVibeTags[vibeId];
//         if (vibeData != null) {
//           trending.add({
//             'vibeId': vibeId,
//             'vibeData': vibeData,
//             'trendingScore': 0.8 + (trending.length * 0.02), // Simulate trending score
//             'category': vibeData['category'],
//           });
//         }
//       }
      
//       return trending;
//     } catch (e) {
//       print('Error getting trending vibes: $e');
//       return [];
//     }
//   }

//   /// Search vibes by text query
//   Future<List<Map<String, dynamic>>> searchVibes(String query) async {
//     final lowerQuery = query.toLowerCase();
//     final results = <Map<String, dynamic>>[];
    
//     for (final entry in comprehensiveVibeTags.entries) {
//       final vibeId = entry.key;
//       final vibeData = entry.value;
//       final displayName = vibeData['displayName'] as String;
//       final description = vibeData['description'] as String;
//       final synonyms = vibeData['synonyms'] as List<String>;
      
//       // Check if query matches vibe name, description, or synonyms
//       if (displayName.toLowerCase().contains(lowerQuery) ||
//           description.toLowerCase().contains(lowerQuery) ||
//           synonyms.any((synonym) => synonym.toLowerCase().contains(lowerQuery))) {
        
//         results.add({
//           'vibeId': vibeId,
//           'vibeData': vibeData,
//           'category': vibeData['category'],
//           'relevanceScore': _calculateRelevanceScore(lowerQuery, vibeData),
//         });
//       }
//     }
    
//     // Sort by relevance
//     results.sort((a, b) => b['relevanceScore'].compareTo(a['relevanceScore']));
//     return results;
//   }

//   /// Get vibes by category
//   Future<List<Map<String, dynamic>>> getVibesByCategory(String category) async {
//     final categoryVibes = <Map<String, dynamic>>[];
    
//     for (final entry in comprehensiveVibeTags.entries) {
//       final vibeId = entry.key;
//       final vibeData = entry.value;
      
//       if (vibeData['category'] == category) {
//         categoryVibes.add({
//           'vibeId': vibeId,
//           'vibeData': vibeData,
//           'category': category,
//         });
//       }
//     }
    
//     return categoryVibes;
//   }

//   // ============================================================================
//   // USER VIBE MANAGEMENT
//   // ============================================================================

//   /// Add vibes to user's active vibe profile
//   Future<bool> activateVibesForUser({
//     required String userId,
//     required List<String> vibeIds,
//     Map<String, double>? intensities, // How strongly user feels about each vibe (0.0-1.0)
//   }) async {
//     try {
//       await _vibeTagService.associateVibesWithEntity(
//         entityId: userId,
//         entityType: 'user',
//         vibeTagIds: vibeIds,
//         source: 'user_activated',
//         customStrengths: intensities,
//         metadata: {
//           'activation_date': DateTime.now().toIso8601String(),
//           'activation_method': 'manual_selection',
//         },
//       );
      
//       // Track activation for learning
//       await _trackVibeActivation(userId, vibeIds, intensities);
      
//       return true;
//     } catch (e) {
//       print('Error activating vibes for user: $e');
//       return false;
//     }
//   }

//   /// Get user's currently active vibes
//   Future<List<Map<String, dynamic>>> getUserActiveVibes(String userId) async {
//     try {
//       final associations = await _vibeTagService.getEntityVibeAssociations(userId, 'user');
//       final activeVibes = <Map<String, dynamic>>[];
      
//       for (final association in associations) {
//         final vibeData = comprehensiveVibeTags[association.vibeTagId];
//         if (vibeData != null) {
//           activeVibes.add({
//             'vibeId': association.vibeTagId,
//             'vibeData': vibeData,
//             'strength': association.strength,
//             'category': vibeData['category'],
//             'activatedAt': association.createdAt,
//             'lastUsed': association.lastUpdated,
//           });
//         }
//       }
      
//       // Sort by strength (most important vibes first)
//       activeVibes.sort((a, b) => b['strength'].compareTo(a['strength']));
//       return activeVibes;
//     } catch (e) {
//       print('Error getting user active vibes: $e');
//       return [];
//     }
//   }

//   /// Deactivate specific vibes for user
//   Future<bool> deactivateVibesForUser({
//     required String userId,
//     required List<String> vibeIds,
//   }) async {
//     try {
//       // Remove vibe associations
//       final batch = _utils.createBatch();
      
//       for (final vibeId in vibeIds) {
//         final docRef = _utils.vibeAssociationsCollection.doc('user_${userId}_$vibeId');
//         batch.delete(docRef);
//       }
      
//       await batch.commit();
      
//       // Track deactivation
//       await _trackVibeDeactivation(userId, vibeIds);
      
//       return true;
//     } catch (e) {
//       print('Error deactivating vibes for user: $e');
//       return false;
//     }
//   }

//   // ============================================================================
//   // HELPER METHODS
//   // ============================================================================

//   double _calculateRelevanceScore(String query, Map<String, dynamic> vibeData) {
//     double score = 0.0;
//     final displayName = (vibeData['displayName'] as String).toLowerCase();
//     final description = (vibeData['description'] as String).toLowerCase();
    
//     // Exact match in display name gets highest score
//     if (displayName.contains(query)) score += 1.0;
    
//     // Match in description gets medium score
//     if (description.contains(query)) score += 0.5;
    
//     // Match in synonyms gets lower score
//     final synonyms = vibeData['synonyms'] as List<String>;
//     for (final synonym in synonyms) {
//       if (synonym.toLowerCase().contains(query)) {
//         score += 0.3;
//         break;
//       }
//     }
    
//     return score;
//   }

//   Future<void> _trackVibeActivation(
//     String userId, 
//     List<String> vibeIds, 
//     Map<String, double>? intensities,
//   ) async {
//     try {
//       await _utils.usersCollection
//           .doc(userId)
//           .collection('vibe_activity')
//           .add({
//         'action': 'activate',
//         'vibeIds': vibeIds,
//         'intensities': intensities ?? {},
//         'timestamp': FieldValue.serverTimestamp(),
//         'source': 'comprehensive_vibe_system',
//       });
//     } catch (e) {
//       print('Error tracking vibe activation: $e');
//     }
//   }

//   Future<void> _trackVibeDeactivation(String userId, List<String> vibeIds) async {
//     try {
//       await _utils.usersCollection
//           .doc(userId)
//           .collection('vibe_activity')
//           .add({
//         'action': 'deactivate',
//         'vibeIds': vibeIds,
//         'timestamp': FieldValue.serverTimestamp(),
//         'source': 'comprehensive_vibe_system',
//       });
//     } catch (e) {
//       print('Error tracking vibe deactivation: $e');
//     }
//   }
// }

// // ============================================================================
// // INITIALIZATION HELPER
// // ============================================================================

// /// Initialize comprehensive vibe system with all predefined vibes
// Future<void> initializeComprehensiveVibeSystem() async {
//   final vibeTagService = VibeTagService();
  
//   try {
//     // Initialize categories
//     for (final categoryEntry in ComprehensiveVibeSystem.vibeCategories.entries) {
//       final categoryData = categoryEntry.value;
//       final category = VibeCategory(
//         id: categoryEntry.key,
//         name: categoryEntry.key,
//         displayName: categoryData['displayName'],
//         description: categoryData['description'],
//         color: categoryData['color'],
//         icon: categoryData['icon'],
//         sortOrder: ComprehensiveVibeSystem.vibeCategories.keys.toList().indexOf(categoryEntry.key),
//         vibeTagIds: [],
//       );

//       await FirebaseFirestore.instance
//           .collection('vibe_categories')
//           .doc(categoryEntry.key)
//           .set(category.toJson(), SetOptions(merge: true));
//     }

//     // Initialize comprehensive vibe tags
//     for (final tagEntry in ComprehensiveVibeSystem.comprehensiveVibeTags.entries) {
//       final tagData = tagEntry.value;
//       final vibeTag = VibeTag(
//         id: tagEntry.key,
//         name: tagEntry.key,
//         displayName: tagData['displayName'],
//         description: tagData['description'],
//         category: tagData['category'],
//         synonyms: List<String>.from(tagData['synonyms']),
//         color: tagData['color'],
//         icon: tagData['icon'],
//         popularity: 0.5,
//         contextWeights: Map<String, double>.from(
//           (tagData['contexts'] as List<String>).asMap().map(
//             (index, context) => MapEntry(context, 0.8 - (index * 0.1))
//           )
//         ),
//         createdAt: DateTime.now(),
//         lastUsed: DateTime.now(),
//         usageCount: 0,
//       );

//       await FirebaseFirestore.instance
//           .collection('vibe_tags')
//           .doc(tagEntry.key)
//           .set(vibeTag.toJson(), SetOptions(merge: true));
//     }

//     print('✅ Comprehensive vibe system initialized with ${ComprehensiveVibeSystem.comprehensiveVibeTags.length} vibes!');
//   } catch (e) {
//     print('❌ Error initializing comprehensive vibe system: $e');
//   }
// }