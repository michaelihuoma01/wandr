import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:myapp/models/models.dart';

class BoardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create a new board
  Future<Board> createBoard({
    required String name,
    required String description,
    required String createdBy,
    required BoardType type,
    List<String> tags = const [],
    String? coverPhotoUrl,
    List<PlaceDetails> places = const [],
    List<ItineraryStop>? itineraryStops,
    String? groupType,
    String? specialOccasion,
    bool isPublic = false,
  }) async {
    final now = DateTime.now();
    final board = Board(
      id: _firestore.collection('boards').doc().id,
      name: name,
      description: description,
      coverPhotoUrl: coverPhotoUrl,
      tags: tags,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      isPublic: isPublic,
      type: type,
      places: places,
      itineraryStops: itineraryStops,
      groupType: groupType,
      specialOccasion: specialOccasion,
    );

    await _firestore.collection('boards').doc(board.id).set(board.toJson());
    return board;
  }

  // Save vibe list as board
  Future<Board> saveVibeListAsBoard({
    required VibeList vibeList,
    required String name,
    required String description,
    List<String>? customTags,
    String? coverPhotoUrl,
  }) async {
    final type = vibeList.isMultiStop ? BoardType.itinerary : BoardType.normal;
    
    return await createBoard(
      name: name.isNotEmpty ? name : vibeList.title,
      description: description.isNotEmpty ? description : vibeList.description,
      createdBy: vibeList.createdBy,
      type: type,
      tags: customTags ?? vibeList.tags,
      coverPhotoUrl: coverPhotoUrl,
      places: vibeList.places,
      itineraryStops: vibeList.itineraryStops,
      groupType: vibeList.groupType,
      specialOccasion: vibeList.specialOccasion,
    );
  }

  // Get user's boards
  Future<List<Board>> getUserBoards(String userId, {BoardType? filterType}) async {
    Query query = _firestore
        .collection('boards')
        .where('createdBy', isEqualTo: userId)
        .orderBy('updatedAt', descending: true);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Board.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  // Update board
  Future<Board> updateBoard(Board board) async {
    final updatedBoard = Board(
      id: board.id,
      name: board.name,
      description: board.description,
      coverPhotoUrl: board.coverPhotoUrl,
      tags: board.tags,
      createdBy: board.createdBy,
      createdAt: board.createdAt,
      updatedAt: DateTime.now(),
      isPublic: board.isPublic,
      type: board.type,
      places: board.places,
      itineraryStops: board.itineraryStops,
      groupType: board.groupType,
      specialOccasion: board.specialOccasion,
    );

    await _firestore.collection('boards').doc(board.id).update(updatedBoard.toJson());
    return updatedBoard;
  }

  // Delete board
  Future<void> deleteBoard(String boardId) async {
    await _firestore.collection('boards').doc(boardId).delete();
  }

  // Upload cover photo
  Future<String> uploadCoverPhoto(File imageFile, String boardId) async {
    final ref = _storage.ref().child('board_covers').child('$boardId.jpg');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  // Get board by ID
  Future<Board?> getBoardById(String boardId) async {
    final doc = await _firestore.collection('boards').doc(boardId).get();
    if (doc.exists) {
      return Board.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Add place to board
  Future<void> addPlaceToBoard(String boardId, PlaceDetails place) async {
    final boardRef = _firestore.collection('boards').doc(boardId);
    await boardRef.update({
      'places': FieldValue.arrayUnion([place.toJson()]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Remove place from board
  Future<void> removePlaceFromBoard(String boardId, PlaceDetails place) async {
    final boardRef = _firestore.collection('boards').doc(boardId);
    await boardRef.update({
      'places': FieldValue.arrayRemove([place.toJson()]),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Update itinerary stops
  Future<void> updateItineraryStops(String boardId, List<ItineraryStop> stops) async {
    final boardRef = _firestore.collection('boards').doc(boardId);
    await boardRef.update({
      'itineraryStops': stops.map((stop) => stop.toJson()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // Search boards
  Future<List<Board>> searchBoards(String query, {BoardType? filterType}) async {
    // Note: Firestore doesn't support full-text search, so this is a basic implementation
    // For production, consider using Algolia or similar service
    Query firestoreQuery = _firestore
        .collection('boards')
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .limit(50);

    if (filterType != null) {
      firestoreQuery = firestoreQuery.where('type', isEqualTo: filterType.name);
    }

    final snapshot = await firestoreQuery.get();
    final boards = snapshot.docs.map((doc) => Board.fromJson(doc.data() as Map<String, dynamic>)).toList();

    // Filter by query in memory (not ideal for large datasets)
    final lowercaseQuery = query.toLowerCase();
    return boards.where((board) {
      return board.name.toLowerCase().contains(lowercaseQuery) ||
             board.description.toLowerCase().contains(lowercaseQuery) ||
             board.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}