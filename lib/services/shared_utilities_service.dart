// import 'dart:math' as math;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:geolocator/geolocator.dart';

// // ============================================================================
// // SHARED UTILITIES SERVICE - Eliminates Code Duplication
// // ============================================================================

// class SharedUtilitiesService {
//   static final SharedUtilitiesService _instance = SharedUtilitiesService._internal();
//   factory SharedUtilitiesService() => _instance;
//   SharedUtilitiesService._internal();

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // ============================================================================
//   // DISTANCE CALCULATIONS - Consolidates 4 different implementations
//   // ============================================================================

//   /// Calculate distance between two coordinates using Haversine formula
//   /// Replaces duplicate implementations in search_service.dart and unified_search_service.dart
//   double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const double earthRadius = 6371; // km
    
//     final double dLat = _degreesToRadians(lat2 - lat1);
//     final double dLon = _degreesToRadians(lon2 - lon1);
    
//     final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
//         math.sin(dLon / 2) * math.sin(dLon / 2);
    
//     final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
//     return earthRadius * c;
//   }

//   /// Calculate distance using Geolocator (for more precise calculations)
//   Future<double> calculatePreciseDistance(double lat1, double lon1, double lat2, double lon2) async {
//     return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
//   }

//   double _degreesToRadians(double degrees) => degrees * (math.pi / 180);

//   // ============================================================================
//   // FIREBASE UTILITIES - Consolidates repeated Firestore patterns
//   // ============================================================================

//   /// Standardized collection references
//   CollectionReference get usersCollection => _firestore.collection('users');
//   CollectionReference get circlesCollection => _firestore.collection('circles');
//   CollectionReference get boardsCollection => _firestore.collection('boards');
//   CollectionReference get placesCollection => _firestore.collection('places');
//   CollectionReference get vibeTagsCollection => _firestore.collection('vibe_tags');
//   CollectionReference get vibeAssociationsCollection => _firestore.collection('vibe_associations');

//   /// Get current user ID - Replaces repeated patterns across services
//   String? get currentUserId => _auth.currentUser?.uid;
//   User? get currentUser => _auth.currentUser;

//   /// Check if user is authenticated
//   bool get isAuthenticated => currentUser != null;

//   /// Get user document reference
//   DocumentReference? getUserDocRef([String? userId]) {
//     final uid = userId ?? currentUserId;
//     return uid != null ? usersCollection.doc(uid) : null;
//   }

//   /// Batch write helper for common operations
//   WriteBatch createBatch() => _firestore.batch();

//   /// Common error handling for Firestore operations
//   Future<T?> executeWithErrorHandling<T>(
//     Future<T> Function() operation,
//     String operationName,
//   ) async {
//     try {
//       return await operation();
//     } catch (e) {
//       print('Error in $operationName: $e');
//       return null;
//     }
//   }

//   // ============================================================================
//   // URL AND EXTERNAL APP UTILITIES
//   // ============================================================================

//   /// Format phone number for calling
//   String formatPhoneForCall(String phone) {
//     return phone.replaceAll(RegExp(r'[^\d+]'), '');
//   }

//   /// Extract domain from URL
//   String? extractDomain(String? url) {
//     if (url == null || url.isEmpty) return null;
//     try {
//       final uri = Uri.parse(url);
//       return uri.host;
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Validate URL format
//   bool isValidUrl(String? url) {
//     if (url == null || url.isEmpty) return false;
//     try {
//       final uri = Uri.parse(url);
//       return uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https'));
//     } catch (e) {
//       return false;
//     }
//   }

//   // ============================================================================
//   // STRING UTILITIES
//   // ============================================================================

//   /// Capitalize first letter of string
//   String capitalize(String text) {
//     if (text.isEmpty) return text;
//     return text[0].toUpperCase() + text.substring(1);
//   }

//   /// Generate unique ID
//   String generateId() => _firestore.collection('temp').doc().id;

//   /// Format timestamp for display
//   String formatTimestamp(DateTime timestamp) {
//     final now = DateTime.now();
//     final difference = now.difference(timestamp);

//     if (difference.inDays > 7) {
//       return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
//     } else if (difference.inDays > 0) {
//       return '${difference.inDays}d ago';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h ago';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m ago';
//     } else {
//       return 'Just now';
//     }
//   }

//   // ============================================================================
//   // VALIDATION UTILITIES
//   // ============================================================================

//   /// Validate email format
//   bool isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }

//   /// Validate required fields
//   bool isNotEmpty(String? value) => value != null && value.trim().isNotEmpty;

//   /// Validate list not empty
//   bool isListNotEmpty<T>(List<T>? list) => list != null && list.isNotEmpty;

//   // ============================================================================
//   // LOADING STATE MIXIN PATTERN
//   // ============================================================================

//   /// Creates a standard loading state management pattern
//   /// Usage: Use in StatefulWidget to manage loading states consistently
// }

// // ============================================================================
// // LOADING STATE MIXIN - Eliminates repeated loading patterns
// // ============================================================================

// mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
//   bool _isLoading = false;
//   String? _error;

//   bool get isLoading => _isLoading;
//   String? get error => _error;

//   void setLoading(bool loading) {
//     if (mounted) {
//       setState(() {
//         _isLoading = loading;
//         if (loading) _error = null; // Clear error when starting new operation
//       });
//     }
//   }

//   void setError(String? error) {
//     if (mounted) {
//       setState(() {
//         _error = error;
//         _isLoading = false;
//       });
//     }
//   }

//   void clearError() {
//     if (mounted) {
//       setState(() => _error = null);
//     }
//   }

//   /// Execute operation with loading state management
//   Future<T?> executeWithLoading<T>(
//     Future<T> Function() operation, {
//     String? errorMessage,
//   }) async {
//     setLoading(true);
//     try {
//       final result = await operation();
//       setLoading(false);
//       return result;
//     } catch (e) {
//       setError(errorMessage ?? 'Operation failed: ${e.toString()}');
//       return null;
//     }
//   }
// }