import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/enhanced_auth_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is not signed in
        if (snapshot.data == null) {
          return const EnhancedAuthScreen();
        }

        // User is signed in - check if they need onboarding
        return FutureBuilder<bool>(
          future: _authService.needsOnboarding(),
          builder: (context, onboardingSnapshot) {
            if (onboardingSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // User needs onboarding
            if (onboardingSnapshot.data == true) {
              return const OnboardingWelcomeScreen();
            }

            // User is fully set up - show home screen
            return const HomeScreen();
          },
        );
      },
    );
  }
}