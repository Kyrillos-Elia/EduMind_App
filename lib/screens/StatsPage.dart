import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:ai_study_app/app_palette.dart';
import '../l10n/app_localizations.dart';
import '../services/study_hour_service.dart';
import '../services/stats_service.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  StatsData? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final data = await StatsService.getStats();
    if (mounted) setState(() { _stats = data; _loading = false; });
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Widget _card({required Widget child, bool highlight = false}) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? palette.primary.withOpacity(0.5) : palette.border,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? palette.primary.withOpacity(0.3)
                : Colors.black.withOpacity(0.4),
            blurRadius: 25,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _quickStat(IconData icon, String label, String value) {
    final palette = AppPalette.of(context);
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(color: palette.primary.withOpacity(0.3), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: palette.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _achievement(String icon, String name, bool earned) {
    return Container(
      width: 90,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: earned
            ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)])
            : null,
        color: earned ? null : const Color(0xFF1F2937),
        boxShadow: earned
            ? [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 20)]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: earned ? Colors.black : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insight(String text) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: palette.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: palette.textPrimary))),
        ],
      ),
    );
  }

  // ─── Dynamic insights based on real data ────────────────────────────────────
  List<String> _buildInsights(StatsData s) {
    final insights = <String>[];

    if (s.quizCount == 0) {
      insights.add('Upload a PDF and take your first quiz to get started!');
    } else {
      final pct = (s.avgScore * 100).round();
      if (pct >= 90) {
        insights.add('Excellent! Your average score is $pct% — keep it up!');
      } else if (pct >= 70) {
        insights.add('Good progress! Your average score is $pct%.');
      } else {
        insights.add('Your average is $pct%. Keep practicing to improve!');
      }

      if (s.quizCount >= 5) {
        insights.add('You\'ve completed ${s.quizCount} quizzes — great consistency!');
      } else {
        insights.add('${5 - s.quizCount} more quizzes to reach Level ${s.level + 1}.');
      }

      if (s.pdfCount > 0) {
        insights.add('You\'ve studied ${s.pdfCount} PDF${s.pdfCount > 1 ? "s" : ""} so far.');
      }
    }

    return insights;
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.bgTop, palette.bgBottom, palette.bgTop],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Particles
          ...List.generate(40, (i) {
            final r = Random(i);
            return Positioned(
              left: r.nextDouble() * MediaQuery.of(context).size.width,
              top: r.nextDouble() * MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: 0.3,
                child: Container(
                  width: 2, height: 2,
                  decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.appTitle,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [palette.primary, const Color(0xFF8B5CF6)],
                                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                            ),
                          ),
                          Text(
                            localizations.yourSmartCompanion,
                            style: TextStyle(color: palette.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Content ─────────────────────────────────────────────────
                Expanded(
                  child: _loading
                      ? Center(child: CircularProgressIndicator(color: palette.primary))
                      : RefreshIndicator(
                          onRefresh: _loadStats,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildContent(palette),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppPalette palette) {
    final s = _stats!;
    final scorePct = s.avgScore;
    final scoreLabel = s.quizCount == 0
        ? '—'
        : '${(scorePct * 100).round()}%';

    return Column(
      children: [
        // ── Overall Performance ────────────────────────────────────────────
        _card(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Performance',
                    style: TextStyle(color: palette.textPrimary, fontSize: 18),
                  ),
                  Icon(
                    Icons.trending_up,
                    color: scorePct >= 0.5 ? Colors.green : Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Circular progress
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110, height: 110,
                        child: CircularProgressIndicator(
                          value: s.quizCount == 0 ? 0 : scorePct,
                          strokeWidth: 10,
                          color: palette.primary,
                          backgroundColor: palette.primary.withOpacity(0.2),
                        ),
                      ),
                      Text(
                        scoreLabel,
                        style: TextStyle(color: palette.textPrimary, fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Line chart of last 6 quizzes
                  Expanded(
                    child: SizedBox(
                      height: 100,
                      child: s.quizCount == 0
                          ? Center(
                              child: Text(
                                'No quizzes yet',
                                style: TextStyle(color: palette.textSecondary, fontSize: 12),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(show: false),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: s.scoreHistory
                                        .asMap()
                                        .entries
                                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                                        .toList(),
                                    isCurved: true,
                                    color: palette.primary,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Quick Stats ────────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _quickStat(Icons.gps_fixed, 'Level', '${s.level}'),
            StreamBuilder<String>(
              stream: StudyHourService.formattedStudyHoursStream(),
              builder: (context, snapshot) =>
                  _quickStat(Icons.timer, 'Hours', snapshot.data ?? '0h'),
            ),
            _quickStat(
              Icons.bar_chart,
              'Score',
              s.quizCount == 0 ? '—' : '${(s.avgScore * 100).round()}%',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Achievements ───────────────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Achievements',
                style: TextStyle(color: palette.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _achievement('🎯', 'First Quiz',    s.firstQuiz),
                    _achievement('📚', '10 PDFs',       s.tenPdfs),
                    _achievement('💯', 'Perfect Score', s.perfectScore),
                    _achievement('⚡', 'Speed Master',  false),
                    _achievement('🔥', '7-Day Streak',  false),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Insights ───────────────────────────────────────────────────────
        _card(
          highlight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildInsights(s).map(_insight).toList(),
          ),
        ),

        const SizedBox(height: 100),
      ],
    );
  }
}