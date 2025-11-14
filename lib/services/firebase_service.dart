import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _initialized = false;

  /// Inicializa Firebase. Llamar en main() antes de runApp
  static Future<void> init() async {
    if (_initialized) return;
    await Firebase.initializeApp();
    _initialized = true;
    if (kDebugMode) print('Firebase inicializado');
  }

  /// Guarda un puntaje en la colección 'scores'
  static Future<void> saveScore({required String username, required int score}) async {
    final col = FirebaseFirestore.instance.collection('scores');
    await col.add({
      'username': username,
      'score': score,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Obtiene top N puntajes ordenados desc
  static Future<List<Map<String, dynamic>>> topScores({int limit = 10}) async {
    final q = await FirebaseFirestore.instance.collection('scores')
        .orderBy('score', descending: true)
        .limit(limit)
        .get();
    return q.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}

