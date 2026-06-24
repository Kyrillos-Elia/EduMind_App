import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateRecord {
  final String id;
  final String userId;
  final int rating; // 1-5
  final DateTime createdAt;
  final DateTime updatedAt;

  RateRecord({
    required this.id,
    required this.userId,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RateRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return RateRecord(
      id: doc.id,
      userId: data['userId'] as String,
      rating: data['rating'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'rating': rating,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class RateState {
  final int? userRating; // Current user's rating (1-5 or null if not rated)
  final double appAverage; // App-wide average rating

  RateState({required this.userRating, required this.appAverage});
}

class RateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit a rating from the current user (one-time only)
  static Future<void> submitRating(int rating) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    try {
      final ratingsCollection = _firestore.collection('ratings');

      // Query to find existing rating for this user
      final existingRating = await ratingsCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingRating.docs.isNotEmpty) {
        throw Exception('Rating already submitted');
      }

      // Create new rating
      await ratingsCollection.add({
        'userId': userId,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  /// Load the current user's rating and app average
  static Future<RateState> loadRateState() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final ratingsCollection = _firestore.collection('ratings');

      // Get current user's rating
      final userRatingSnapshot = await ratingsCollection
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      int? userRating;
      if (userRatingSnapshot.docs.isNotEmpty) {
        userRating = userRatingSnapshot.docs.first['rating'] as int?;
      }

      // Calculate app average
      final allRatingsSnapshot = await ratingsCollection.get();
      double appAverage = 0.0;

      if (allRatingsSnapshot.docs.isNotEmpty) {
        final sum = allRatingsSnapshot.docs
            .map((doc) => doc['rating'] as int)
            .fold<int>(0, (prev, rating) => prev + rating);
        appAverage = sum / allRatingsSnapshot.docs.length;
      }

      return RateState(userRating: userRating, appAverage: appAverage);
    } catch (e) {
      throw Exception('Failed to load rate state: $e');
    }
  }

  /// Get a stream of the app-wide average rating
  /// Emits updates whenever ratings change
  static Stream<double> appAverageStream() {
    return _firestore.collection('ratings').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      final sum = snapshot.docs
          .map((doc) => doc['rating'] as int)
          .fold<int>(0, (prev, rating) => prev + rating);

      return sum / snapshot.docs.length;
    });
  }

  /// Get the current user's rating as a stream
  static Stream<int?> userRatingStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('ratings')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }
          return snapshot.docs.first['rating'] as int?;
        });
  }

  /// Get total number of ratings
  static Stream<int> totalRatingsCountStream() {
    return _firestore
        .collection('ratings')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
