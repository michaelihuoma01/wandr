// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profile_setup_screen.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success) {
      if (result.isNewUser) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else if (result.error != null && result.error != 'Sign in cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in failed: ${result.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.explore,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // App name
                  const Text(
                    'Wandr',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Tagline
                  const Text(
                    'Discover Places That Match Your Vibe',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  
                  // Sign in button
                  _buildGoogleSignInButton(),
                  const SizedBox(height: 20),
                  
                  // Terms text
                  Text(
                    'By signing in, you agree to our Terms of Service\nand Privacy Policy',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png', // You'll need to add this asset
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.login, size: 24);
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}