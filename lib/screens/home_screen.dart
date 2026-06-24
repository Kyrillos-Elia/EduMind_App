import 'package:ai_study_app/screens/ProfilePage.dart';
import 'package:ai_study_app/screens/ai_chat.dart';
import 'package:ai_study_app/screens/pdf_page.dart';
import 'package:ai_study_app/app_palette.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../l10n/app_localizations.dart';
import '../localization_helper.dart';
import '../services/task_service.dart';
import '../services/study_hour_service.dart';

void main() {
  runApp(const HomePage());
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const HomeScreen({super.key, this.onProfileTap});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool orbExpanded = false;

  late final AnimationController _orbController;
  late final AnimationController _pulseController;

  late final Animation<double> _orbAnimationY;
  late final Animation<double> _pulse;
  late final Animation<double> _orbScale;

  @override
  void initState() {
    super.initState();

    _setupStudyTracking();

    // حركة لفوق وتحت
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _orbAnimationY = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _orbController, curve: Curves.easeInOut));

    // Pulse للأيقونات
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pulse للـ Orb
    _orbScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _orbController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _setupStudyTracking() async {
    await StudyHourService.initializeStudyHours();
    await StudyHourService.updateStudyHourIfTimeElapsed();
    await StudyHourService.updateStudyDaysIfTimeElapsed();
  }

  final Random random = Random();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ⭐ Stars
          ...List.generate(
            30,
            (i) => Positioned(
              left: random.nextDouble() * MediaQuery.of(context).size.width,
              top: random.nextDouble() * MediaQuery.of(context).size.height,
              child: Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: palette.primary.withAlpha(80),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.appTitle,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            localizations.yourSmartCompanion,
                            style: TextStyle(color: palette.primary),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.onProfileTap != null) {
                            widget.onProfileTap!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: palette.primary,
                          child: Icon(
                            Icons.person,
                            color: palette.isDark ? Colors.white : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Study Streak
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.surface,
                      border: Border.all(color: palette.border),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CustomLocalizations.of(
                                    context,
                                  ).get('studyStreak'),
                                  style: TextStyle(
                                    color: palette.textSecondary,
                                  ),
                                ),
                                StreamBuilder<String>(
                                  stream:
                                      StudyHourService.formattedStudyDaysStream(),
                                  builder: (context, snapshot) {
                                    final studyDays =
                                        snapshot.data ?? '0 Days 🔥';
                                    return Text(
                                      studyDays,
                                      style: TextStyle(
                                        color: palette.textPrimary,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          CustomLocalizations.of(context).get('keepItUp'),
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ORB + ICONS
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        orbExpanded = !orbExpanded;
                      });
                    },
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _orbController,
                        _pulseController,
                      ]),
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _orbAnimationY.value),
                          child: Transform.scale(
                            scale: _orbScale.value,
                            child: SizedBox(
                              width: 300,
                              height: 220,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  // 🔥 3D ORB
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: const RadialGradient(
                                          colors: [
                                            Color(0xFF6EC6FF),
                                            Color(0xFF1E88E5),
                                            Color(0xFF6A1B9A),
                                          ],
                                          center: Alignment(-0.3, -0.3),
                                          radius: 0.9,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: palette.primary.withAlpha(
                                              150,
                                            ),
                                            blurRadius: 25,
                                            spreadRadius: 5,
                                            offset: const Offset(0, 10),
                                          ),
                                          BoxShadow(
                                            color: Colors.purple.withAlpha(100),
                                            blurRadius: 40,
                                            spreadRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.psychology,
                                            color: Colors.white,
                                            size: 60,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            CustomLocalizations.of(
                                              context,
                                            ).get('orbClick'),
                                            style: const TextStyle(
                                              color: Color(0xFFE6F2FF),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Icons فوق — Chat و Upload بس
                                  if (orbExpanded)
                                    Positioned(
                                      bottom: 140,
                                      child: Row(
                                        children: [
                                          pulseIcon(
                                            Icons.chat,
                                            localizations.chat,
                                            palette,
                                          ),
                                          const SizedBox(width: 20),
                                          pulseIcon(
                                            Icons.upload,
                                            localizations.upload,
                                            palette,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Spacer(),

                  // Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StreamBuilder<int>(
                        stream: TaskService.completedTaskCountStream(),
                        builder: (context, snapshot) {
                          final completedTasks = snapshot.data ?? 0;
                          return statCard(
                            Icons.menu_book,
                            localizations.tasks,
                            completedTasks.toString(),
                            palette,
                          );
                        },
                      ),
                      StreamBuilder<String>(
                        stream: StudyHourService.formattedStudyHoursStream(),
                        builder: (context, snapshot) {
                          final studyHours = snapshot.data ?? '0h';
                          return statCard(
                            Icons.timer,
                            localizations.days,
                            studyHours,
                            palette,
                          );
                        },
                      ),
                      statCard(
                        Icons.emoji_events,
                        localizations.points,
                        "94%",
                        palette,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget pulseIcon(IconData icon, String label, AppPalette palette) {
    return GestureDetector(
      onTap: () {
        if (icon == Icons.chat) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatPage()),
          );
        } else if (icon == Icons.upload) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PdfPage()),
          );
        }
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulse.value,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primary.withAlpha(40),
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary.withAlpha(120),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(color: palette.textPrimary, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget statCard(
    IconData icon,
    String title,
    String value,
    AppPalette palette,
  ) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: palette.textPrimary)),
          Text(value, style: TextStyle(color: palette.textSecondary)),
        ],
      ),
    );
  }
}