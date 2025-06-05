import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
class WelcomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
   WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to the App!',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: () async {
                try {
                  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
                  if (googleUser == null) {
                    // User cancelled the sign-in
                    return;
                  }

                  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

                  final credential = GoogleAuthProvider.credential(
                    accessToken: googleAuth.accessToken,
                    idToken: googleAuth.idToken,
                  );

                  UserCredential userCredential = await _auth.signInWithCredential(credential);
                  
                  // Check if it's a new user
                  if (userCredential.additionalUserInfo?.isNewUser == true) {
                    // Navigate to profile setup for new users
                    Navigator.pushReplacementNamed(context, '/profileSetup');
                  } else {
                    Navigator.pushReplacementNamed(context, '/home');
                  }
                } catch (e) {
                  // Handle sign-in errors
                  print('Error signing in with Google: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing in: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Sign in with Google'),
            ),
          ],
        ),
      ),
    );
  }
}