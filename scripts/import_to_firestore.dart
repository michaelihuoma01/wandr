// This script can be run in Flutter to import the generated test data into Firestore
// Run this from your Flutter app's main function temporarily

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreImporter {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> importAllTestData() async {
    print('🚀 Starting Firestore import...');
    
    try {
      await importUsers();
      await importCircles();
      await importBoards();
      await importCheckIns();
      
      print('✅ All data imported successfully!');
    } catch (e) {
      print('❌ Error importing data: $e');
    }
  }

  Future<void> importUsers() async {
    print('👥 Importing users...');
    
    final file = File('scripts/test_data/users.json');
    final content = await file.readAsString();
    final List<dynamic> users = jsonDecode(content);
    
    final batch = _firestore.batch();
    
    for (final user in users) {
      final docRef = _firestore.collection('users').doc(user['uid']);
      batch.set(docRef, {
        ...user,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
    print('  ✓ Imported ${users.length} users');
  }

  Future<void> importCircles() async {
    print('⭕ Importing circles...');
    
    final file = File('scripts/test_data/circles.json');
    final content = await file.readAsString();
    final List<dynamic> circles = jsonDecode(content);
    
    final batch = _firestore.batch();
    
    for (final circle in circles) {
      final docRef = _firestore.collection('circles').doc(circle['id']);
      batch.set(docRef, {
        ...circle,
        'createdAt': DateTime.parse(circle['createdAt']),
        'updatedAt': DateTime.parse(circle['updatedAt']),
      });
    }
    
    await batch.commit();
    print('  ✓ Imported ${circles.length} circles');
  }

  Future<void> importBoards() async {
    print('📋 Importing boards...');
    
    final file = File('scripts/test_data/boards.json');
    final content = await file.readAsString();
    final List<dynamic> boards = jsonDecode(content);
    
    final batch = _firestore.batch();
    
    for (final board in boards) {
      final docRef = _firestore.collection('boards').doc(board['id']);
      batch.set(docRef, {
        ...board,
        'createdAt': DateTime.parse(board['createdAt']),
        'updatedAt': DateTime.parse(board['updatedAt']),
      });
    }
    
    await batch.commit();
    print('  ✓ Imported ${boards.length} boards');
  }

  Future<void> importCheckIns() async {
    print('📍 Importing check-ins...');
    
    final file = File('scripts/test_data/checkins.json');
    final content = await file.readAsString();
    final List<dynamic> checkIns = jsonDecode(content);
    
    // Process in batches of 500 (Firestore limit)
    for (int i = 0; i < checkIns.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < checkIns.length) ? i + 500 : checkIns.length;
      
      for (int j = i; j < end; j++) {
        final checkIn = checkIns[j];
        final docRef = _firestore.collection('checkins').doc(checkIn['id']);
        batch.set(docRef, {
          ...checkIn,
          'timestamp': DateTime.parse(checkIn['timestamp']),
        });
      }
      
      await batch.commit();
      print('  ✓ Imported batch ${(i ~/ 500) + 1}');
    }
    
    print('  ✓ Imported ${checkIns.length} check-ins total');
  }
}

// Usage example:
// Add this to your main.dart temporarily and run it once
Future<void> runImport() async {
  final importer = FirestoreImporter();
  await importer.importAllTestData();
}