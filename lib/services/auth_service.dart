// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'user_profile_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserProfileService _userProfileService = UserProfileService();

  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Get display name (from Firestore first, then Google profile)
  Future<String> getDisplayName() async {
    final userData = await getUserData();
    if (userData != null && userData['name'] != null) {
      return userData['name'];
    }
    
    final user = currentUser;
    if (user != null && user.displayName != null) {
      return user.displayName!;
    }
    
    return 'User';
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // User cancelled the sign-in
      if (googleUser == null) {
        return AuthResult(
          success: false,
          error: 'Sign in cancelled',
          authMethod: AuthMethod.google,
        );
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      final bool isNewUser = !userDoc.exists;

      // If existing user, update last login
      if (!isNewUser) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return AuthResult(
        success: true,
        isNewUser: isNewUser,
        user: userCredential.user,
        authMethod: AuthMethod.google,
      );
    } catch (e) {
      print('Error signing in with Google: $e');
      return AuthResult(
        success: false,
        error: e.toString(),
        authMethod: AuthMethod.google,
      );
    }
  }

  // Save user profile
  Future<bool> saveUserProfile(String name) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': user.email,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge to preserve existing data
      
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user account
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create enhanced user profile
      final enhancedUser = await _userProfileService.createEnhancedUserProfile(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        photoUrl: userCredential.user?.photoURL,
      );

      return AuthResult(
        success: true,
        isNewUser: true,
        user: userCredential.user,
        authMethod: AuthMethod.email,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
        authMethod: AuthMethod.email,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
        authMethod: AuthMethod.email,
      );
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      await _firestore.collection('users').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return AuthResult(
        success: true,
        isNewUser: false,
        user: userCredential.user,
        authMethod: AuthMethod.email,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
        authMethod: AuthMethod.email,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'An unexpected error occurred. Please try again.',
        authMethod: AuthMethod.email,
      );
    }
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        message: 'Password reset email sent. Check your inbox.',
        authMethod: AuthMethod.email,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
        authMethod: AuthMethod.email,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to send reset email. Please try again.',
        authMethod: AuthMethod.email,
      );
    }
  }

  // Check if user needs onboarding
  Future<bool> needsOnboarding() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return true;

      final data = doc.data() as Map<String, dynamic>;
      
      // Check if user has completed onboarding
      final onboardingData = data['onboardingData'] as Map<String, dynamic>?;
      if (onboardingData == null) return true;

      final completedSteps = onboardingData['completedSteps'] as List<dynamic>?;
      return completedSteps == null || !completedSteps.contains('completed');
    } catch (e) {
      print('Error checking onboarding status: $e');
      return true; // Default to requiring onboarding
    }
  }

  // Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Validate password strength
  PasswordValidation validatePassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    final isValid = hasMinLength && hasUppercase && hasLowercase && hasNumber;

    return PasswordValidation(
      isValid: isValid,
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecialChar: hasSpecialChar,
    );
  }

  // Get user-friendly error messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been temporarily disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}

// Result class for auth operations
class AuthResult {
  final bool success;
  final bool isNewUser;
  final User? user;
  final String? error;
  final String? message;
  final AuthMethod? authMethod;

  AuthResult({
    required this.success,
    this.isNewUser = false,
    this.user,
    this.error,
    this.message,
    this.authMethod,
  });
}

// Password validation result
class PasswordValidation {
  final bool isValid;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;

  PasswordValidation({
    required this.isValid,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
  });
}

// Authentication methods
enum AuthMethod {
  email,
  google,
}