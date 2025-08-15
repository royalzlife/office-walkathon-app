import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Admin functions
  Future<void> startCompetition() async {
    await _dbRef.child('participants').remove();
    await _dbRef.child('competition').set({
      'status': 'in_progress',
      'startTime': ServerValue.timestamp,
    });
  }

  Future<void> stopCompetition() async {
    await _dbRef.child('competition').update({
      'status': 'finished',
    });
  }

  // Participant functions
  Future<void> addParticipant(String name) async {
    await _dbRef.child('participants').child(name).set({
      'name': name,
      'steps': 0,
    });
  }

  Future<void> updateStepCount(String name, int steps) async {
    await _dbRef.child('participants').child(name).update({
      'steps': steps,
    });
  }

  // Streams for real-time updates
  Stream<Map<String, dynamic>> getCompetitionState() {
    return _dbRef.child('competition').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.map((key, value) => MapEntry(key.toString(), value));
    });
  }

  Stream<Map<String, dynamic>> getParticipantsStream() {
    return _dbRef.child('participants').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return data.map((key, value) => MapEntry(key.toString(), value));
    });
  }
}