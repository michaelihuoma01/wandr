import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models.dart'; // Import your data models
import 'package:geolocator/geolocator.dart'; // For location

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}); // Added const constructor

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceDetails> _searchResults = []; // Use your data model
  bool _isLoading = false; // Loading indicator
  String? _errorMessage; // To display errors

  // Replace with your actual Cloud Function URL
  final String _cloudFunctionUrl = 'YOUR_CLOUD_FUNCTION_URL'; // <<<--- IMPORTANT: REPLACE THIS URL

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _performSearch() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Position position = await _getCurrentLocation();

      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'textInput': _searchController.text,
          'inputType': 'text',
          'latitude': position.latitude,
          'longitude': position.longitude,
          // Add other input parameters if needed
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final output = AnalyzeInputAndSuggestLocationsOutput.fromJson(jsonResponse);
        setState(() {
          _searchResults = output.locations;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode} - ${response.body}';
          _isLoading = false;
          _searchResults = [];
        });
        print('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
        _isLoading = false;
        _searchResults = [];
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibe Search'), // Added const
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter your vibe or place',
                suffixIcon: _isLoading
                    ? const CircularProgressIndicator() // Added const
                    : IconButton(
                        icon: const Icon(Icons.search), // Added const
                        onPressed: _performSearch,
                      ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red), // Added const
                ),
              ),
            const SizedBox(height: 20), // Added const
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    title: Text(place.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.description),
                        if (place.rating != null)
                          Text('Rating: ${place.rating!.toStringAsFixed(1)}'),
                        if (place.priceLevel != null)
                          Text('Price: ${place.priceLevel}'),
                        // Add more details you want to display
                      ],
                    ),
                    // You can add leading/trailing widgets for images, icons, etc.
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
