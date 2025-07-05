// lib/services/vibe_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:myapp/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/search_service.dart';
import 'package:myapp/services/location_service.dart';

class VibeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SearchService _searchService = SearchService();
  final LocationService _locationService = LocationService();
  
  static const String _cloudFunctionUrl = 'https://us-central1-locale-lens-uslei.cloudfunctions.net/generateVibeList';
  
  // Generate a vibe list based on preferences
  Future<VibeList?> generateVibeList({
    required VibePreferences preferences,
    required String userId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Use provided coordinates or get current location
      double lat = latitude ?? _locationService.currentPosition?.latitude ?? 0;
      double lng = longitude ?? _locationService.currentPosition?.longitude ?? 0;
      
      if (lat == 0 || lng == 0) {
        throw Exception('Location not available');
      }

      // Prepare request for AI-powered vibe list generation
      final Map<String, dynamic> requestBody = {
        'preferences': preferences.toJson(),
        'latitude': lat,
        'longitude': lng,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Call cloud function to generate vibe list
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final vibeList = VibeList.fromJson(jsonResponse);
        
        // Save to Firestore
        await _saveVibeListToFirestore(vibeList);
        
        return vibeList;
      } else {
        print('Cloud function error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to generate vibe list: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating vibe list: $e');
      throw e; // Re-throw the error instead of using fallback
    }
  }

  // Vibe list management methods

  Future<void> _saveVibeListToFirestore(VibeList vibeList) async {
    try {
      await _firestore
          .collection('vibe_lists')
          .doc(vibeList.id)
          .set(vibeList.toJson());
    } catch (e) {
      print('Error saving vibe list to Firestore: $e');
    }
  }

  // Get user's saved vibe lists
  Future<List<VibeList>> getUserVibeLists(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('vibe_lists')
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VibeList.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user vibe lists: $e');
      return [];
    }
  }

  // Share vibe list with circles
  Future<bool> shareVibeList(String vibeListId, List<String> circleIds) async {
    try {
      await _firestore
          .collection('vibe_lists')
          .doc(vibeListId)
          .update({
        'isShared': true,
        'sharedWithCircles': circleIds,
      });
      return true;
    } catch (e) {
      print('Error sharing vibe list: $e');
      return false;
    }
  }

  // Delete vibe list
  Future<bool> deleteVibeList(String vibeListId) async {
    try {
      await _firestore
          .collection('vibe_lists')
          .doc(vibeListId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting vibe list: $e');
      return false;
    }
  }
}