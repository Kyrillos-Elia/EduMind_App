import 'dart:math';

import 'package:ai_study_app/app_palette.dart';
import 'package:ai_study_app/services/notifications_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../localization_helper.dart';

// ─────────────────────────────────────────────
// Notifications Screen
// ─────────────────────────────────────────────

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _formatNotificationTime(DateTime? createdAt) {
    final time = createdAt ?? DateTime.now();
    return DateFormat('MMM d, h:mm a').format(time.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [palette.bgTop, palette.bgBottom],
              ),
            ),
          ),

          // Particles
          const FloatingParticles(),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: StreamBuilder<NotificationSettings>(
                stream: NotificationService.watchSettings(),
                builder: (context, settingsSnapshot) {
                  final settings =
                      settingsSnapshot.data ?? const NotificationSettings();

                  return StreamBuilder<List<AppNotification>>(
                    stream: NotificationService.watchNotifications(),
                    builder: (context, notificationsSnapshot) {
                      final notifications =
                          notificationsSnapshot.data ??
                          const <AppNotification>[];
                      final unreadCount = notifications
                          .where((notification) => notification.isUnread)
                          .length;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SlideIn(
                              delay: Duration.zero,
                              child: GestureDetector(
                                onTap: () => Navigator.maybePop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: palette.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: palette.textPrimary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SlideIn(
                              delay: const Duration(milliseconds: 80),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: palette.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: palette.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    CustomLocalizations.of(
                                      context,
                                    ).get('notifications'),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            _SlideIn(
                              delay: const Duration(milliseconds: 120),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 52),
                                child: Text(
                                  CustomLocalizations.of(
                                    context,
                                  ).get('stayUpdatedWithYourActivity'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _SlideIn(
                              delay: const Duration(milliseconds: 160),
                              child: _GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        12,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            color: palette.primary,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            CustomLocalizations.of(
                                              context,
                                            ).get('notificationSettings'),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(color: palette.border, height: 1),
                                    _NotificationToggle(
                                      icon: Icons.notifications_outlined,
                                      label: CustomLocalizations.of(
                                        context,
                                      ).get('pushNotifications'),
                                      enabled: settings.pushNotifications,
                                      onToggle: () =>
                                          NotificationService.saveSettings(
                                            settings.copyWith(
                                              pushNotifications:
                                                  !settings.pushNotifications,
                                            ),
                                          ),
                                    ),
                                    Divider(color: palette.border, height: 1),
                                    _NotificationToggle(
                                      icon: Icons.calendar_today_outlined,
                                      label: CustomLocalizations.of(
                                        context,
                                      ).get('studyReminders'),
                                      enabled: settings.studyReminders,
                                      onToggle: () =>
                                          NotificationService.saveSettings(
                                            settings.copyWith(
                                              studyReminders:
                                                  !settings.studyReminders,
                                            ),
                                          ),
                                    ),
                                    Divider(color: palette.border, height: 1),
                                    _NotificationToggle(
                                      icon: Icons.emoji_events_outlined,
                                      label: CustomLocalizations.of(
                                        context,
                                      ).get('quizAlerts'),
                                      enabled: settings.quizAlerts,
                                      onToggle: () =>
                                          NotificationService.saveSettings(
                                            settings.copyWith(
                                              quizAlerts: !settings.quizAlerts,
                                            ),
                                          ),
                                    ),
                                    Divider(color: palette.border, height: 1),
                                    _NotificationToggle(
                                      icon: Icons.psychology_outlined,
                                      label: CustomLocalizations.of(
                                        context,
                                      ).get('aiSuggestions'),
                                      enabled: settings.aiSuggestions,
                                      onToggle: () =>
                                          NotificationService.saveSettings(
                                            settings.copyWith(
                                              aiSuggestions:
                                                  !settings.aiSuggestions,
                                            ),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            _SlideIn(
                              delay: const Duration(milliseconds: 200),
                              child: Row(
                                children: [
                                  Text(
                                    CustomLocalizations.of(
                                      context,
                                    ).get('recentNotifications'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  if (unreadCount > 0) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: palette.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (notifications.isNotEmpty)
                              _SlideIn(
                                delay: const Duration(milliseconds: 240),
                                child: Row(
                                  children: [
                                    _ActionButton(
                                      label: CustomLocalizations.of(
                                        context,
                                      ).get('markAllAsRead'),
                                      color: palette.primary,
                                      borderColor: palette.primary.withOpacity(
                                        0.3,
                                      ),
                                      bgColor: palette.primary.withOpacity(0.1),
                                      onTap: unreadCount > 0
                                          ? () =>
                                                NotificationService.markAllAsRead()
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    _ActionButton(
                                      label: CustomLocalizations.of(
                                        context,
                                      ).get('clearAll'),
                                      color: const Color(0xFFEF4444),
                                      borderColor: const Color(
                                        0xFFEF4444,
                                      ).withOpacity(0.3),
                                      bgColor: const Color(
                                        0xFFEF4444,
                                      ).withOpacity(0.1),
                                      onTap: () =>
                                          NotificationService.clearAll(),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 14),
                            if (notifications.isEmpty)
                              _SlideIn(
                                delay: const Duration(milliseconds: 280),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 48,
                                  ),
                                  decoration: BoxDecoration(
                                    color: palette.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: palette.border),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.notifications_off_outlined,
                                        color: palette.textSecondary,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        CustomLocalizations.of(
                                          context,
                                        ).get('noNotificationsYet'),
                                        style: TextStyle(
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: notifications.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final notification = entry.value;
                                  return _SlideIn(
                                    delay: Duration(
                                      milliseconds: 280 + index * 50,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: _NotificationCard(
                                        notification: notification,
                                        timeLabel: _formatNotificationTime(
                                          notification.createdAt,
                                        ),
                                        onTap: () =>
                                            NotificationService.markAsRead(
                                              notification.id,
                                            ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Notification Toggle Row
// ─────────────────────────────────────────────
class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onToggle;

  const _NotificationToggle({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: palette.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: palette.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 26,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: enabled
                    ? palette.primary
                    : palette.textSecondary.withOpacity(0.6),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: palette.primary.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: enabled
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Notification Card
// ─────────────────────────────────────────────
class _NotificationCard extends StatefulWidget {
  final AppNotification notification;
  final String timeLabel;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.timeLabel,
    required this.onTap,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final n = widget.notification;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isUnread
              ? palette.primary.withOpacity(0.08)
              : palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: n.isUnread
                ? palette.primary.withOpacity(0.3)
                : palette.border,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withOpacity(
                _pressed
                    ? 0.25
                    : n.isUnread
                    ? 0.15
                    : 0.05,
              ),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: palette.primary.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(n.icon, color: palette.primary, size: 20),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          CustomLocalizations.of(context).get(n.title),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      if (n.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: palette.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: palette.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.timeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSecondary,
                    ),
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

// ─────────────────────────────────────────────
// Action Button
// ─────────────────────────────────────────────
class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final Color borderColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.borderColor,
    required this.bgColor,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.borderColor),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.onTap != null
                  ? widget.color
                  : widget.color.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Glass Card
// ─────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(color: palette.primary.withOpacity(0.1), blurRadius: 30),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: child),
    );
  }
}

// ─────────────────────────────────────────────
// Floating Particles
// ─────────────────────────────────────────────
class FloatingParticles extends StatefulWidget {
  const FloatingParticles({super.key});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final List<_Particle> _particles = [];
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 20; i++) {
      _particles.add(
        _Particle(
          x: _rng.nextDouble(),
          y: _rng.nextDouble(),
          phaseOffset: _rng.nextDouble(),
          speedFactor: 0.6 + _rng.nextDouble() * 0.8,
        ),
      );
    }
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        painter: _ParticlePainter(_particles, _ctrl.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  final double x, y, phaseOffset, speedFactor;
  _Particle({
    required this.x,
    required this.y,
    required this.phaseOffset,
    required this.speedFactor,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speedFactor + p.phaseOffset) % 1.0;
      final wave = sin(t * 2 * pi);
      final opacity = (0.15 + 0.65 * ((wave + 1) / 2)).clamp(0.0, 1.0);
      final dy = -30 * wave;

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height + dy),
        2,
        Paint()
          ..color = const Color(0xFF60A5FA).withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─────────────────────────────────────────────
// Slide-In Animation Wrapper
// ─────────────────────────────────────────────
class _SlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _SlideIn({required this.child, required this.delay});

  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.07),
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
