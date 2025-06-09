// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      );
    } catch (e) {
      print('Error signing in with Google: $e');
      return AuthResult(
        success: false,
        error: e.toString(),
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

  AuthResult({
    required this.success,
    this.isNewUser = false,
    this.user,
    this.error,
  });
}