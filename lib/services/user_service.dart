import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ============ READ ============
  static Future<Map<String, dynamic>?> getUserData() async {
    if (_uid == null) return null;
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.exists ? doc.data() : null;
  }

  // ============ WRITE - Edit Profile ============
  static Future<void> saveProfile({
    required String fullName,
    required String username,
    required String phone,
    required String about,
  }) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set({
      'fullName': fullName,
      'username': username,
      'phone': phone,
      'about': about,
      'email': FirebaseAuth.instance.currentUser?.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============ WRITE - Personal Info ============
  static Future<void> savePersonalInfo({
    required String fullName,
    required String username,
    required String age,
    required String phone,
    required String sex,
  }) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set({
      'fullName': fullName,
      'username': username,
      'age': age,
      'phone': phone,
      'sex': sex,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ============ WRITE - Academic Info ============
  static Future<void> saveAcademicInfo({
    required String university,
    required String faculty,
    required String major,
    required String academicYear,
    required String gpa,
  }) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).set({
      'university': university,
      'faculty': faculty,
      'major': major,
      'academicYear': academicYear,
      'gpa': gpa,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}