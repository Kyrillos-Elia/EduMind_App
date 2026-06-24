import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StatsService {
  // ─── Keys ───────────────────────────────────────
  static const _keyQuizScores = 'quiz_scores';     // List<String> of "score/total"
  static const _keyPdfCount   = 'pdf_count';       // int
  static const _keyFirstQuiz  = 'ach_first_quiz';  // bool
  static const _keyPerfectScore = 'ach_perfect';   // bool

  // ─── Save quiz result ────────────────────────────
  /// Call this when the user submits a quiz.
  /// [score] = number of correct answers, [total] = total questions
  static Future<void> saveQuizResult(int score, int total) async {
    final prefs = await SharedPreferences.getInstance();

    // Save score to list
    final raw = prefs.getStringList(_keyQuizScores) ?? [];
    raw.add(jsonEncode({'score': score, 'total': total}));
    await prefs.setStringList(_keyQuizScores, raw);

    // First quiz achievement
    await prefs.setBool(_keyFirstQuiz, true);

    // Perfect score achievement
    if (score == total) {
      await prefs.setBool(_keyPerfectScore, true);
    }
  }

  // ─── Increment PDF count ─────────────────────────
  static Future<void> incrementPdfCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyPdfCount) ?? 0;
    await prefs.setInt(_keyPdfCount, current + 1);
  }

  // ─── Get all stats ───────────────────────────────
  static Future<StatsData> getStats() async {
    final prefs = await SharedPreferences.getInstance();

    // Quiz scores
    final raw = prefs.getStringList(_keyQuizScores) ?? [];
    final scores = raw.map((e) {
      final m = jsonDecode(e) as Map;
      return (m['score'] as int) / (m['total'] as int);
    }).toList();

    final avgScore = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;

    // PDF count
    final pdfCount = prefs.getInt(_keyPdfCount) ?? 0;

    // Quiz count
    final quizCount = scores.length;

    // Level: every 5 quizzes = 1 level, min 1
    final level = (quizCount ~/ 5) + 1;

    // Achievements
    final firstQuiz   = prefs.getBool(_keyFirstQuiz)    ?? false;
    final perfectScore = prefs.getBool(_keyPerfectScore) ?? false;
    final tenPdfs     = pdfCount >= 10;

    return StatsData(
      avgScore: avgScore,
      quizCount: quizCount,
      pdfCount: pdfCount,
      level: level,
      firstQuiz: firstQuiz,
      perfectScore: perfectScore,
      tenPdfs: tenPdfs,
      // Performance history: last 6 scores (or pad with 0)
      scoreHistory: _buildHistory(scores),
    );
  }

  static List<double> _buildHistory(List<double> scores) {
    if (scores.isEmpty) return [0, 0, 0, 0, 0, 0];
    // Make a mutable copy of last 6
    final last6 = List<double>.from(
      scores.length > 6 ? scores.sublist(scores.length - 6) : scores,
    );
    // Pad left with 0s if less than 6
    while (last6.length < 6) {
      last6.insert(0, 0);
    }
    return last6.map((s) => s * 100).toList();
  }
}

// ─── Data model ─────────────────────────────────────
class StatsData {
  final double avgScore;      // 0.0 – 1.0
  final int quizCount;
  final int pdfCount;
  final int level;
  final bool firstQuiz;
  final bool perfectScore;
  final bool tenPdfs;
  final List<double> scoreHistory; // percentages for chart

  StatsData({
    required this.avgScore,
    required this.quizCount,
    required this.pdfCount,
    required this.level,
    required this.firstQuiz,
    required this.perfectScore,
    required this.tenPdfs,
    required this.scoreHistory,
  });
}