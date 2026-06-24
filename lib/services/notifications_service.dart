import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NotificationSettings {
  const NotificationSettings({
    this.pushNotifications = true,
    this.studyReminders = true,
    this.quizAlerts = true,
    this.aiSuggestions = false,
  });

  final bool pushNotifications;
  final bool studyReminders;
  final bool quizAlerts;
  final bool aiSuggestions;

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? studyReminders,
    bool? quizAlerts,
    bool? aiSuggestions,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      studyReminders: studyReminders ?? this.studyReminders,
      quizAlerts: quizAlerts ?? this.quizAlerts,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
    );
  }

  factory NotificationSettings.fromMap(Map<String, dynamic>? data) {
    return NotificationSettings(
      pushNotifications: data?['pushNotifications'] as bool? ?? true,
      studyReminders: data?['studyReminders'] as bool? ?? true,
      quizAlerts: data?['quizAlerts'] as bool? ?? true,
      aiSuggestions: data?['aiSuggestions'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushNotifications': pushNotifications,
      'studyReminders': studyReminders,
      'quizAlerts': quizAlerts,
      'aiSuggestions': aiSuggestions,
    };
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.iconCodePoint,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.isUnread,
  });

  final String id;
  final int iconCodePoint;
  final String title;
  final String description;
  final DateTime? createdAt;
  final bool isUnread;

  static final Map<int, IconData> _iconMapFromCodePoint = {
    Icons.notifications_outlined.codePoint: Icons.notifications_outlined,
  };

  IconData get icon =>
      _iconMapFromCodePoint[iconCodePoint] ?? Icons.notifications_outlined;

  AppNotification copyWith({bool? isUnread}) {
    return AppNotification(
      id: id,
      iconCodePoint: iconCodePoint,
      title: title,
      description: description,
      createdAt: createdAt,
      isUnread: isUnread ?? this.isUnread,
    );
  }

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AppNotification(
      id: doc.id,
      iconCodePoint:
          (data['iconCodePoint'] as int?) ??
          Icons.notifications_outlined.codePoint,
      title: (data['title'] as String?) ?? 'Notification',
      description: (data['description'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isUnread: (data['isUnread'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'iconCodePoint': iconCodePoint,
      'title': title,
      'description': description,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'isUnread': isUnread,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class NotificationService {
  NotificationService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static String? _tokenRefreshUserId;
  static const int _defaultNotificationIconCodePoint = 0xe7f4;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static DocumentReference<Map<String, dynamic>>? get _userDocument {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  static CollectionReference<Map<String, dynamic>>?
  get _notificationsCollection {
    final userDocument = _userDocument;
    if (userDocument == null) return null;
    return userDocument.collection('notifications');
  }

  static Stream<NotificationSettings> watchSettings() {
    final userDocument = _userDocument;
    if (userDocument == null) {
      return Stream<NotificationSettings>.value(const NotificationSettings());
    }

    return userDocument.snapshots().map((snapshot) {
      final data = snapshot.data();
      return NotificationSettings.fromMap(
        data?['notificationSettings'] as Map<String, dynamic>?,
      );
    });
  }

  static Future<void> saveSettings(NotificationSettings settings) async {
    final userDocument = _userDocument;
    if (userDocument == null) return;

    await userDocument.set({
      'notificationSettings': settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<List<AppNotification>> watchNotifications() {
    final notificationsCollection = _notificationsCollection;
    if (notificationsCollection == null) {
      return Stream<List<AppNotification>>.value(const <AppNotification>[]);
    }

    return notificationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AppNotification.fromDoc).toList());
  }

  static Future<void> markAsRead(String notificationId) async {
    final notificationsCollection = _notificationsCollection;
    if (notificationsCollection == null) return;

    await notificationsCollection.doc(notificationId).set({
      'isUnread': false,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> markAllAsRead() async {
    final notificationsCollection = _notificationsCollection;
    if (notificationsCollection == null) return;

    final snapshot = await notificationsCollection
        .where('isUnread', isEqualTo: true)
        .get();
    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {
        'isUnread': false,
        'readAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  static Future<void> clearAll() async {
    final notificationsCollection = _notificationsCollection;
    if (notificationsCollection == null) return;

    final snapshot = await notificationsCollection.get();
    if (snapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<AppNotification?> createNotificationForUser({
    required String userId,
    required String title,
    required String description,
    required int iconCodePoint,
    DateTime? createdAt,
  }) async {
    final notificationRef = _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc();

    final notification = AppNotification(
      id: notificationRef.id,
      iconCodePoint: iconCodePoint,
      title: title,
      description: description,
      createdAt: createdAt ?? DateTime.now().toUtc(),
      isUnread: true,
    );

    await notificationRef.set(notification.toMap());
    return notification;
  }

  static Future<AppNotification?> sendTestNotificationToUser({
    required String userId,
    String title = 'New notification',
    String description = 'You have a new notification.',
    int iconCodePoint = _defaultNotificationIconCodePoint,
  }) {
    return createNotificationForUser(
      userId: userId,
      title: title,
      description: description,
      iconCodePoint: iconCodePoint,
    );
  }

  static Future<void> broadcastNotificationToAllUsers({
    required String title,
    required String description,
    int iconCodePoint = _defaultNotificationIconCodePoint,
  }) async {
    final usersSnapshot = await _db.collection('users').get();
    if (usersSnapshot.docs.isEmpty) return;

    final batch = _db.batch();
    for (final userDoc in usersSnapshot.docs) {
      final notificationRef = userDoc.reference
          .collection('notifications')
          .doc();
      batch.set(notificationRef, {
        'iconCodePoint': iconCodePoint,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'isUnread': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  static Future<void> initializeForCurrentUser() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      if (_tokenRefreshUserId != uid) {
        await _tokenRefreshSubscription?.cancel();
        _tokenRefreshSubscription = null;
        _tokenRefreshUserId = uid;
      }

      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      await _messaging.subscribeToTopic('all_users');

      final token = await _messaging.getToken();
      if (token != null) {
        await _saveToken(uid, token);
      }

      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((
        refreshedToken,
      ) {
        _saveToken(uid, refreshedToken);
      });
    } catch (_) {
      // Notification setup should never block navigation.
    }
  }

  static Future<void> _saveToken(String uid, String token) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
