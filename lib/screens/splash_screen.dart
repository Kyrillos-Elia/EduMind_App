import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ai_study_app/app_palette.dart';
import '../l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController glowController;
  late AnimationController scaleController;
  late AnimationController dotsController;
  late AnimationController rotateController;

  @override
  void initState() {
    super.initState();

    /// Animations
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    /// Start app flow
    _startApp();
  }

  Future<void> _startApp() async {
    await Future.delayed(const Duration(seconds: 5));

    // No navigation logic here anymore - handled by AuthWrapper
  }

  @override
  void dispose() {
    glowController.dispose();
    scaleController.dispose();
    dotsController.dispose();
    rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.bgTop, palette.bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            /// Glow Background
            Center(
              child: AnimatedBuilder(
                animation: scaleController,
                builder: (_, _) {
                  return Transform.scale(
                    scale: 1 + (scaleController.value * 0.2),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.primary.withOpacity(0.2),
                        boxShadow: [
                          BoxShadow(
                            color: palette.primary.withOpacity(0.3),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// Main Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Logo Box
                  AnimatedBuilder(
                    animation: glowController,
                    builder: (_, _) {
                      return Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            colors: [
                              palette.primary.withOpacity(0.2),
                              palette.primary.withOpacity(0.2),
                            ],
                          ),
                          border: Border.all(
                            color: palette.primary.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withOpacity(
                                0.3 + glowController.value * 0.3,
                              ),
                              blurRadius: 20 + glowController.value * 20,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.psychology,
                              size: 50,
                              color: Colors.blueAccent,
                            ),

                            /// rotating spark
                            Positioned(
                              top: 10,
                              right: 10,
                              child: AnimatedBuilder(
                                animation: rotateController,
                                builder: (_, _) {
                                  return Transform.rotate(
                                    angle: rotateController.value * 2 * pi,
                                    child: Icon(
                                      Icons.auto_awesome,
                                      size: 24,
                                      color: Colors.blue[200],
                                    ),
                                  );
                                },
                              ),
                            ),

                            const Positioned(
                              bottom: 10,
                              right: 10,
                              child: Icon(
                                Icons.menu_book,
                                size: 22,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  /// App Name
                  AnimatedBuilder(
                    animation: glowController,
                    builder: (_, _) {
                      return Column(
                        children: [
                          Text(
                            localizations.eduMind,
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..shader =
                                    LinearGradient(
                                      colors: [
                                        palette.primary,
                                        Colors.lightBlueAccent,
                                      ],
                                    ).createShader(
                                      const Rect.fromLTWH(0, 0, 200, 70),
                                    ),
                              shadows: [
                                Shadow(
                                  blurRadius: 20 + glowController.value * 10,
                                  color: palette.primary.withOpacity(0.6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            localizations.smartLearning,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  /// Loading dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: dotsController,
                        builder: (_, _) {
                          double delay = index * 0.2;
                          double value = (dotsController.value - delay).clamp(
                            0.0,
                            1.0,
                          );

                          return Transform.scale(
                            scale: 1 + (sin(value * pi) * 0.5),
                            child: Opacity(
                              opacity: 0.3 + (sin(value * pi) * 0.7),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
