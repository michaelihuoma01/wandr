import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import the home screen

void main() {
  runApp(const MyApp()); // Added const
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Added const constructor

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe Search App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Optional: enable Material 3
      ),
      home: const HomeScreen(), // Set HomeScreen as the home, added const
    );
  }
}
