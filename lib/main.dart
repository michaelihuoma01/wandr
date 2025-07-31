import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/circles/circle_detail_screen.dart';
import 'services/notification_service.dart';
import 'screens/enhanced_home_screen.dart';
import 'screens/auth_wrapper.dart';
import 'screens/enhanced_auth_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/onboarding/vibe_wheel_screen.dart';
import 'screens/onboarding/contextual_preferences_screen.dart';
import 'screens/onboarding/social_matching_screen.dart';
import 'screens/enhanced_profile_screen.dart';
import 'screens/discovery/visual_discovery_screen.dart';

import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> initializeBackgroundService() async {
  // Configure background service for location tracking
  // Implementation depends on chosen background service package
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyAg2DE8DzvbqUmHhY1e7ACO2JN9DIn2K04",
          appId: "1:248207776942:ios:f27fee07f5a6aff9f5e13f",
          messagingSenderId: "248207776942",
          storageBucket: "locale-lens-uslei.firebasestorage.app",
          projectId: "locale-lens-uslei"));

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notifications
  final notificationService = NotificationService();
  // await notificationService.initialize();

  // Set up navigation callback
  notificationService.navigateToCircle = (circleId) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => CircleDetailScreen(circleId: circleId),
      ),
    );
  };

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize background service
  await initializeBackgroundService();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _setupNotifications() {
    // Set up navigation callback
    _notificationService.navigateToCircle = (circleId) {
      // Navigate to circle detail screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => CircleDetailScreen(circleId: circleId),
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wandr - AI Place Discovery',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      routes: {
        '/auth': (context) => const EnhancedAuthScreen(),
        '/home': (context) => const EnhancedHomeScreen(),
        '/onboarding': (context) => const OnboardingWelcomeScreen(),
        '/onboarding/vibe-wheel': (context) => const VibeWheelScreen(),
        '/onboarding/contextual-preferences': (context) => const ContextualPreferencesScreen(),
        '/onboarding/social-matching': (context) => const SocialMatchingScreen(),
        '/profile': (context) => const EnhancedProfileScreen(),
        '/discover': (context) => const VisualDiscoveryScreen(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE), // Purple theme
          brightness: Brightness.light,
        ),
        primaryColor: const Color(0xFF6200EE),
        useMaterial3: true,
        fontFamily: 'SF Pro Display', // Uses system font

        // Custom text theme
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            height: 1.5,
          ),
        ),

        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFF6200EE).withOpacity(0.5),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),

        // App bar theme
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: AuthWrapper(),
    );
  }
}
