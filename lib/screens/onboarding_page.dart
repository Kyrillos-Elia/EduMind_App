import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_study_app/app_palette.dart';
import 'login_screen.dart';
import '../l10n/app_localizations.dart';
import '../localization_helper.dart';

class Slide {
  final String title;
  final String description;
  final IconData icon;

  Slide({required this.title, required this.description, required this.icon});
}

const int totalSlides = 3;

List<Slide> getLocalizedSlides(
  AppLocalizations localizations,
  BuildContext context,
) {
  final customLoc = CustomLocalizations.of(context);
  return [
    Slide(
      title: customLoc.get('studySmarterTitle'),
      description: localizations.description1,
      icon: Icons.auto_awesome,
    ),
    Slide(
      title: customLoc.get('turnPdfsTitle'),
      description: localizations.description2,
      icon: Icons.article,
    ),
    Slide(
      title: customLoc.get('trackProgressTitle'),
      description: localizations.description3,
      icon: Icons.trending_up,
    ),
  ];
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int currentSlide = 0;

  late AnimationController mainController;
  late AnimationController glowController;
  late AnimationController floatingController;

  @override
  void initState() {
    super.initState();

    mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    mainController.dispose();
    glowController.dispose();
    floatingController.dispose();
    super.dispose();
  }

  Future<void> finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void handleNext() {
    if (currentSlide < totalSlides - 1) {
      setState(() {
        currentSlide++;
        mainController.forward(from: 0); // restart animation
      });
    } else {
      finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final localizations = AppLocalizations.of(context)!;
    final slideList = getLocalizedSlides(localizations, context);
    final slide = slideList[currentSlide];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          /// SKIP
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: finishOnboarding,
              child: Text(
                localizations.skip,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          /// MAIN CONTENT
          Center(
            child: AnimatedBuilder(
              animation: mainController,
              builder: (_, _) {
                double slideX = 100 * (1 - mainController.value);

                return Opacity(
                  opacity: mainController.value,
                  child: Transform.translate(
                    offset: Offset(slideX, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        /// CIRCLE (Illustration)
                        AnimatedBuilder(
                          animation: glowController,
                          builder: (_, _) {
                            return Container(
                              width: 256,
                              height: 256,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    palette.primary.withOpacity(0.1),
                                    palette.primary.withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: palette.primary.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.primary.withOpacity(
                                      0.1 + glowController.value * 0.1,
                                    ),
                                    blurRadius: 40 + glowController.value * 20,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    slide.icon,
                                    size: 80,
                                    color: palette.primary,
                                  ),

                                  /// TOP RIGHT FLOAT
                                  Positioned(
                                    top: -16,
                                    right: -16,
                                    child: AnimatedBuilder(
                                      animation: floatingController,
                                      builder: (_, _) {
                                        double scale =
                                            1 +
                                            (sin(
                                                  floatingController.value * pi,
                                                ) *
                                                0.5);

                                        return Transform.scale(
                                          scale: scale,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: palette.primary
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  /// BOTTOM LEFT FLOAT
                                  Positioned(
                                    bottom: -24,
                                    left: -24,
                                    child: AnimatedBuilder(
                                      animation: floatingController,
                                      builder: (_, _) {
                                        double scale =
                                            1 +
                                            (sin(
                                                  floatingController.value * pi,
                                                ) *
                                                0.3);

                                        return Transform.scale(
                                          scale: scale,
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: palette.primary
                                                  .withOpacity(0.2),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        /// TITLE + DESC
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            children: [
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                slide.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// BOTTOM CONTROLS
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                /// INDICATORS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    slideList.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: currentSlide == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: currentSlide == index
                            ? palette.primary
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// NEXT BUTTON
                ElevatedButton(
                  onPressed: handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primary,
                    minimumSize: const Size.fromHeight(55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentSlide == slideList.length - 1
                            ? localizations.getStarted
                            : localizations.next,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
