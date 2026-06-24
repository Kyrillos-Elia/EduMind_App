import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudyHourService {
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Initialize study hours for new user (called on first login/signup)
  static Future<void> initializeStudyHours() async {
    if (_uid == null) return;

    final userDoc = await _db.collection('users').doc(_uid).get();

    if (!userDoc.exists) {
      // New user - initialize with 0 hours and 0 days
      await _db.collection('users').doc(_uid).set({
        'studyHours': 0,
        'studyDays': 0,
        'lastHourUpdate': FieldValue.serverTimestamp(),
        'lastDayUpdate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      final data = userDoc.data() ?? {};
      final updates = <String, Object>{};

      if (!data.containsKey('studyHours')) {
        updates['studyHours'] = 0;
        updates['lastHourUpdate'] = FieldValue.serverTimestamp();
      }

      if (!data.containsKey('studyDays')) {
        updates['studyDays'] = 0;
        updates['lastDayUpdate'] = FieldValue.serverTimestamp();
      }

      if (updates.isNotEmpty) {
        await _db
            .collection('users')
            .doc(_uid)
            .set(updates, SetOptions(merge: true));
      }
    }
  }

  // Get current study hours
  static Future<int> getStudyHours() async {
    if (_uid == null) return 0;

    try {
      final doc = await _db.collection('users').doc(_uid).get();
      return doc.data()?['studyHours'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get current study days
  static Future<int> getStudyDays() async {
    if (_uid == null) return 0;

    try {
      final doc = await _db.collection('users').doc(_uid).get();
      return doc.data()?['studyDays'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Stream to listen to study hours changes
  static Stream<dynamic> studyHoursStream() {
    final uid = _uid;
    if (uid == null) return Stream<int>.value(0);

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          return doc.data()?['studyHours'] ?? 0;
        })
        .handleError((error) {
          return 0;
        });
  }

  // Stream to listen to study day changes
  static Stream<dynamic> studyDaysStream() {
    final uid = _uid;
    if (uid == null) return Stream<int>.value(0);

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          return doc.data()?['studyDays'] ?? 0;
        })
        .handleError((error) {
          return 0;
        });
  }

  // Manually increment study hours by specified amount
  static Future<void> addStudyHours(int hours) async {
    if (_uid == null) return;

    await _db.collection('users').doc(_uid).update({
      'studyHours': FieldValue.increment(hours),
      'lastHourUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Manually increment study days by specified amount
  static Future<void> addStudyDays(int days) async {
    if (_uid == null) return;

    await _db.collection('users').doc(_uid).update({
      'studyDays': FieldValue.increment(days),
      'lastDayUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Increment by 1 hour if enough time has passed
  static Future<void> updateStudyHourIfTimeElapsed() async {
    if (_uid == null) return;

    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      if (!userDoc.exists) {
        await initializeStudyHours();
        return;
      }

      final data = userDoc.data()!;
      final lastUpdate = data['lastHourUpdate'] as Timestamp?;

      if (lastUpdate == null) {
        // First time - just update the timestamp
        await _db.collection('users').doc(_uid).update({
          'lastHourUpdate': FieldValue.serverTimestamp(),
        });
        return;
      }

      final lastUpdateDate = lastUpdate.toDate();
      final now = DateTime.now();

      // Check if 1 hour has passed
      if (now.difference(lastUpdateDate).inHours >= 1) {
        final hoursPassed = now.difference(lastUpdateDate).inHours;
        await _db.collection('users').doc(_uid).update({
          'studyHours': FieldValue.increment(hoursPassed),
          'lastHourUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  // Increment by 1 day if enough time has passed
  static Future<void> updateStudyDaysIfTimeElapsed() async {
    if (_uid == null) return;

    try {
      final userDoc = await _db.collection('users').doc(_uid).get();
      if (!userDoc.exists) {
        await initializeStudyHours();
        return;
      }

      final data = userDoc.data()!;
      final lastDayUpdate = data['lastDayUpdate'] as Timestamp?;

      if (lastDayUpdate == null) {
        await _db.collection('users').doc(_uid).update({
          'lastDayUpdate': FieldValue.serverTimestamp(),
        });
        return;
      }

      final lastDayUpdateDate = lastDayUpdate.toDate();
      final now = DateTime.now();
      final daysPassed = now.difference(lastDayUpdateDate).inDays;

      if (daysPassed >= 1) {
        await _db.collection('users').doc(_uid).update({
          'studyDays': FieldValue.increment(daysPassed),
          'lastDayUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  // Get formatted study hours (e.g., "48h")
  static Future<String> getFormattedStudyHours() async {
    final hours = await getStudyHours();
    return '${hours}h';
  }

  // Stream to get formatted study hours
  static Stream<String> formattedStudyHoursStream() {
    final uid = _uid;
    if (uid == null) return Stream<String>.value('0h');

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          final hours = doc.data()?['studyHours'] ?? 0;
          return '${hours}h';
        })
        .handleError((error) {
          return '0h';
        });
  }

  // Stream to get formatted study days
  static Stream<String> formattedStudyDaysStream() {
    final uid = _uid;
    if (uid == null) return Stream<String>.value('0 Days');

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          final days = doc.data()?['studyDays'] ?? 0;
          return '$days Days 🔥';
        })
        .handleError((error) {
          return '0 Days 🔥';
        });
  }

  // Reset study hours (admin only or for testing)
  static Future<void> resetStudyHours() async {
    if (_uid == null) return;

    await _db.collection('users').doc(_uid).update({
      'studyHours': 0,
      'lastHourUpdate': FieldValue.serverTimestamp(),
    });
  }
}
