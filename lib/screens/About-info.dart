import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ai_study_app/app_palette.dart';
// ignore: unused_import
import '../l10n/app_localizations.dart';
import '../localization_helper.dart';
import '../services/rate_service.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  bool _expandedContact = false;
  bool _expandedRating = false;
  int _rating = 0;
  bool _hasSubmittedRating = false;
  final int _hoveredStar = 0;

  final List<Map<String, dynamic>> features = [
    {
      'icon': Icons.chat_bubble_outline,
      'text': 'aiPoweredChatAssistant',
      'color': Color(0xFF3B82F6),
    },
    {
      'icon': Icons.picture_as_pdf_outlined,
      'text': 'smartPdfSummarization',
      'color': Color(0xFF60A5FA),
    },
    {
      'icon': Icons.assignment_outlined,
      'text': 'quizGeneration',
      'color': Color(0xFF3B82F6),
    },
    {
      'icon': Icons.trending_up,
      'text': 'progressTracking',
      'color': Color(0xFF60A5FA),
    },
  ];

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadExistingRating();
  }

  Future<void> _loadExistingRating() async {
    try {
      final state = await RateService.loadRateState();
      if (!mounted) return;
      setState(() {
        _hasSubmittedRating = state.userRating != null;
        if (_hasSubmittedRating) {
          _rating = state.userRating!;
        }
      });
    } catch (_) {
      // Keep UI usable even if rating lookup fails.
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.bgTop, palette.bgBottom],
              ),
            ),
          ),

          // Floating particles
          FloatingParticles(color: palette.primary),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: palette.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: palette.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  _AnimatedFadeSlide(
                    delay: Duration.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          CustomLocalizations.of(context).get('appInfo'),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CustomLocalizations.of(context).get('aboutEduMind'),
                          style: TextStyle(
                            fontSize: 14,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Overview Card
                  _AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 100),
                    child: _GlassCard(
                      child: Column(
                        children: [
                          _PulsingBrainIcon(),
                          const SizedBox(height: 16),
                          Text(
                            'EduMind',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontSize: 13,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            CustomLocalizations.of(
                              context,
                            ).get('edumindDescription'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: palette.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Features
                  _AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CustomLocalizations.of(context).get('keyFeatures'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...features.asMap().entries.map((entry) {
                            final i = entry.key;
                            final f = entry.value;
                            return _AnimatedFadeSlide(
                              delay: Duration(milliseconds: 300 + i * 80),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    _GlowIconBox(
                                      icon: f['icon'] as IconData,
                                      color: f['color'] as Color,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      CustomLocalizations.of(
                                        context,
                                      ).get(f['text'] as String),
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Developer
                  _AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: palette.surfaceAlt,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Title
                                Row(
                                  children: [
                                    Icon(
                                      Icons.code,
                                      color: palette.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      CustomLocalizations.of(
                                        context,
                                      ).get('developers'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                /// Subtitle
                                Text(
                                  CustomLocalizations.of(
                                    context,
                                  ).get('developedByZenithDevsTeam'),
                                  style: TextStyle(
                                    color: palette.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),

                                Divider(color: palette.border, height: 20),

                                /// Names
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: palette.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Abram Anwer',
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: palette.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Kyrillos Elia',
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: palette.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Demiana Morice',
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: palette.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Farah Mohammed',
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: palette.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Mariem Hamdy',
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Links
                  _AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: Column(
                      children: [
                        _NavButton(
                          icon: Icons.shield_outlined,
                          label: CustomLocalizations.of(
                            context,
                          ).get('privacyPolicy'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrivacyScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _NavButton(
                          icon: Icons.fact_check_outlined,
                          label: CustomLocalizations.of(
                            context,
                          ).get('termsOfService'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TermsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Contact Us
                  _AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: Column(
                      children: [
                        _ExpandableButton(
                          icon: Icons.email_outlined,
                          label: CustomLocalizations.of(
                            context,
                          ).get('contactUs'),
                          expanded: _expandedContact,
                          onTap: () {
                            setState(() {
                              _expandedContact = !_expandedContact;
                              _expandedRating = false;
                            });
                          },
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _GlassCard(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    color: palette.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'edumindt@gmail.com',
                                    style: TextStyle(
                                      color: palette.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          crossFadeState: _expandedContact
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                        const SizedBox(height: 10),

                        // Rate App
                        _ExpandableButton(
                          icon: Icons.star_outline,
                          label: CustomLocalizations.of(context).get('rateApp'),
                          expanded: _expandedRating,
                          onTap: () {
                            setState(() {
                              _expandedRating = !_expandedRating;
                              _expandedContact = false;
                            });
                          },
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _GlassCard(
                              child: Column(
                                children: [
                                  Text(
                                    CustomLocalizations.of(
                                      context,
                                    ).get('rateYourExperience'),
                                    style: TextStyle(
                                      color: palette.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(5, (i) {
                                      final star = i + 1;
                                      final filled =
                                          star <=
                                          (_hoveredStar > 0
                                              ? _hoveredStar
                                              : _rating);
                                      return GestureDetector(
                                        onTap: _hasSubmittedRating
                                            ? null
                                            : () => setState(
                                                () => _rating = star,
                                              ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Icon(
                                            filled
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: filled
                                                ? palette.primary
                                                : palette.textSecondary,
                                            size: 32,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  if (_hasSubmittedRating) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      CustomLocalizations.of(
                                        context,
                                      ).get('ratingAlreadySubmittedOnce'),
                                      style: TextStyle(
                                        color: palette.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  if (_rating > 0 && !_hasSubmittedRating) ...[
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          try {
                                            await RateService.submitRating(
                                              _rating,
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    CustomLocalizations.of(
                                                      context,
                                                    ).get(
                                                      'ratingSubmittedSuccessfully',
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      palette.primary,
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                              setState(() {
                                                _hasSubmittedRating = true;
                                                _expandedRating = false;
                                              });
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              final isAlreadySubmitted = e
                                                  .toString()
                                                  .contains(
                                                    'Rating already submitted',
                                                  );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    isAlreadySubmitted
                                                        ? CustomLocalizations.of(
                                                            context,
                                                          ).get(
                                                            'ratingAlreadySubmittedOnce',
                                                          )
                                                        : 'Error: ${e.toString()}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      isAlreadySubmitted
                                                      ? palette.primary
                                                      : Colors.red[600],
                                                  duration: const Duration(
                                                    seconds: 3,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                              if (isAlreadySubmitted) {
                                                setState(() {
                                                  _hasSubmittedRating = true;
                                                  _expandedRating = false;
                                                });
                                              }
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: palette.primary,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          shadowColor: palette.primary,
                                          elevation: 8,
                                        ),
                                        child: Text(
                                          CustomLocalizations.of(
                                            context,
                                          ).get('submitRating'),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          crossFadeState: _expandedRating
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Privacy Screen
// ─────────────────────────────────────────────
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<Map<String, dynamic>> _items = [
    {
      'title': 'weRespectYourPrivacyAndProtectYourData',
      'content': null,
      'icon': Icons.shield_outlined,
    },
    {
      'title': 'dataWeCollect',
      'content': 'dataWeCollectContent',
      'icon': Icons.description_outlined,
    },
    {
      'title': 'howWeUseData',
      'content': 'howWeUseDataContent',
      'icon': Icons.psychology_outlined,
    },
    {
      'title': 'dataSharing',
      'content': 'dataSharingContent',
      'icon': Icons.shield_outlined,
    },
    {
      'title': 'security',
      'content': 'securityContent',
      'icon': Icons.fact_check_outlined,
    },
    {
      'title': 'yourRights',
      'content': 'yourRightsContent',
      'icon': Icons.star_outline,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _DetailScreen(
      title: 'privacyPolicy',
      subtitle: 'howWeProtectYourData',
      items: _items,
    );
  }
}

// ─────────────────────────────────────────────
// Terms Screen
// ─────────────────────────────────────────────
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const List<Map<String, dynamic>> _items = [
    {
      'title': 'introduction',
      'content': 'termsAgree',
      'icon': Icons.fact_check_outlined,
    },
    {
      'title': 'useOfApp',
      'content': 'forPersonalUseOnly',
      'icon': Icons.psychology_outlined,
    },
    {
      'title': 'userContent',
      'content': 'youAreResponsible',
      'icon': Icons.description_outlined,
    },
    {
      'title': 'aiDisclaimer',
      'content': 'resultsMayNotBeAccurate',
      'icon': Icons.chat_bubble_outline,
    },
    {
      'title': 'account',
      'content': 'youMustKeepYourAccountSecure',
      'icon': Icons.shield_outlined,
    },
    {
      'title': 'termination',
      'content': 'accountsMayBeSuspended',
      'icon': Icons.star_outline,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return _DetailScreen(
      title: 'termsOfService',
      subtitle: 'termsAgree',
      items: _items,
    );
  }
}

// ─────────────────────────────────────────────
// Reusable Detail Screen (Privacy / Terms)
// ─────────────────────────────────────────────
class _DetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> items;

  const _DetailScreen({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.bgTop, palette.bgBottom],
              ),
            ),
          ),
          FloatingParticles(color: palette.primary),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.arrow_back, color: palette.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    CustomLocalizations.of(context).get(title),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CustomLocalizations.of(context).get(subtitle),
                    style: TextStyle(
                      fontSize: 14,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _AnimatedFadeSlide(
                          delay: Duration(milliseconds: index * 80),
                          child: _GlassCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _GlowIconBox(
                                  icon: item['icon'] as IconData,
                                  color: palette.primary,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: palette.textPrimary,
                                        ),
                                      ),
                                      if (item['content'] != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          item['content'] as String,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: palette.textSecondary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────

class FloatingParticles extends StatefulWidget {
  final Color color;

  const FloatingParticles({super.key, required this.color});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) {
      _particles.add(
        _Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          duration: 3000 + _random.nextInt(2000),
          delay: _random.nextInt(2000),
        ),
      );
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            _particles,
            _controller.value,
            widget.color,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final int duration;
  final int delay;

  _Particle({
    required this.x,
    required this.y,
    required this.duration,
    required this.delay,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter(this.particles, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.delay / 5000) % 1.0;
      final wave = sin(t * 2 * pi);
      final opacity = (0.2 + 0.6 * ((wave + 1) / 2)).clamp(0.0, 1.0);
      final dy = -30 * wave;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height + dy),
        2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withOpacity(0.15),
            blurRadius: 32,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GlowIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _GlowIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 15)],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(_hovered ? 0.3 : 0.1),
              blurRadius: _hovered ? 32 : 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: palette.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(color: palette.textPrimary, fontSize: 14),
              ),
            ),
            Icon(Icons.chevron_right, color: palette.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ExpandableButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final VoidCallback onTap;

  const _ExpandableButton({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_ExpandableButton> createState() => _ExpandableButtonState();
}

class _ExpandableButtonState extends State<_ExpandableButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(_hovered ? 0.3 : 0.1),
              blurRadius: _hovered ? 32 : 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: palette.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(color: palette.textPrimary, fontSize: 14),
              ),
            ),
            Icon(
              widget.expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: palette.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingBrainIcon extends StatefulWidget {
  const _PulsingBrainIcon();

  @override
  State<_PulsingBrainIcon> createState() => _PulsingBrainIconState();
}

class _PulsingBrainIconState extends State<_PulsingBrainIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 8,
      end: 20,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, _) => Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.primary, const Color(0xFF2563EB)],
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(0.6),
              blurRadius: _glow.value,
              spreadRadius: _glow.value / 4,
            ),
          ],
        ),
        child: const Icon(Icons.psychology, color: Colors.white, size: 44),
      ),
    );
  }
}

class _AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedFadeSlide({required this.child, required this.delay});

  @override
  State<_AnimatedFadeSlide> createState() => _AnimatedFadeSlideSate();
}

class _AnimatedFadeSlideSate extends State<_AnimatedFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
