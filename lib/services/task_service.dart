import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskRecord {
  TaskRecord({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.colorValue,
    required this.createdAt,
    required this.completed,
    required this.completedAt,
  });

  final String id;
  final String title;
  final int iconCodePoint;
  final int colorValue;
  final int createdAt;
  final bool completed;
  final int? completedAt;
}

class TaskState {
  TaskState({
    required this.fullName,
    required this.tasks,
    required this.completedCount,
  });

  final String? fullName;
  final List<TaskRecord> tasks;
  final int completedCount;
}

class TaskService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const Duration _completedVisibilityDuration = Duration(hours: 24);

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _db.collection('tasks');

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate().toUtc();
    return null;
  }

  static bool _isVisibleTask(Map<String, dynamic> data) {
    final completed = data['completed'] == true;
    if (!completed) return true;

    final now = DateTime.now().toUtc();
    final completedAt =
        _timestampToDate(data['completedAt']) ??
        _timestampToDate(data['updatedAt']);

    if (completedAt == null) return true;
    return now.difference(completedAt) < _completedVisibilityDuration;
  }

  static int _visibleCompletedCount(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      return data['completed'] == true && _isVisibleTask(data);
    }).length;
  }

  static Stream<int> completedTaskCountStream() {
    final uid = _uid;
    if (uid == null) return Stream<int>.value(0);

    late final StreamController<int> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? snapshotSub;
    Timer? timer;

    Future<void> emitCount() async {
      try {
        final snapshot = await _tasksCollection
            .where('userId', isEqualTo: uid)
            .get();
        if (!controller.isClosed) {
          controller.add(_visibleCompletedCount(snapshot.docs));
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller = StreamController<int>.broadcast(
      onListen: () {
        emitCount();
        snapshotSub = _tasksCollection
            .where('userId', isEqualTo: uid)
            .snapshots()
            .listen((_) {
              emitCount();
            });
        timer = Timer.periodic(const Duration(minutes: 15), (_) => emitCount());
      },
      onCancel: () async {
        await snapshotSub?.cancel();
        timer?.cancel();
      },
    );

    return controller.stream;
  }

  static DocumentReference<Map<String, dynamic>>? get _userDocument {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid);
  }

  static TaskRecord _taskFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    return TaskRecord(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      iconCodePoint:
          (data['iconCodePoint'] as int?) ?? Icons.task_alt.codePoint,
      colorValue: (data['colorValue'] as int?) ?? Colors.blueAccent.toARGB32(),
      createdAt: (data['createdAt'] as int?) ?? 0,
      completed: (data['completed'] as bool?) ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.millisecondsSinceEpoch,
    );
  }

  static Future<TaskState> loadTaskState() async {
    final userDocument = _userDocument;

    if (userDocument == null) {
      return TaskState(
        fullName: null,
        tasks: <TaskRecord>[],
        completedCount: 0,
      );
    }

    final userDoc = await userDocument.get();
    final userData = userDoc.data();
    final fullName = userData?['fullName'] as String?;
    final snapshot = await _tasksCollection
        .where('userId', isEqualTo: _uid)
        .get();
    final tasks = snapshot.docs.map(_taskFromDoc).where((task) {
      if (!task.completed) return true;
      final completedAt = task.completedAt;
      if (completedAt == null) return true;
      return DateTime.now().toUtc().difference(
            DateTime.fromMillisecondsSinceEpoch(completedAt, isUtc: true),
          ) <
          _completedVisibilityDuration;
    }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final completedCount = tasks.where((task) => task.completed).length;

    return TaskState(
      fullName: fullName,
      tasks: tasks,
      completedCount: completedCount,
    );
  }

  static Future<TaskRecord?> addTask({
    required String title,
    required int iconCodePoint,
    required int colorValue,
    required int createdAt,
  }) async {
    final userDocument = _userDocument;
    final uid = _uid;
    if (userDocument == null || uid == null) return null;

    final userDoc = await userDocument.get();
    final userData = userDoc.data();
    final fullName = userData?['fullName'] as String?;

    final docRef = _tasksCollection.doc();
    await docRef.set({
      'userId': uid,
      'fullName': fullName,
      'title': title,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'createdAt': createdAt,
      'completed': false,
      'completedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return TaskRecord(
      id: docRef.id,
      title: title,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      createdAt: createdAt,
      completed: false,
      completedAt: null,
    );
  }

  static Future<void> deleteTask(String taskId) async {
    await _tasksCollection.doc(taskId).delete();
  }

  static Future<void> completeTask(String taskId) async {
    await _tasksCollection.doc(taskId).set({
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
