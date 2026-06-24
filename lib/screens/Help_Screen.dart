import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ai_study_app/app_palette.dart';
import '../localization_helper.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  // ignore: unused_field
  String _expandedFaq = '';
  String _page = 'help'; // 'help' or 'report'
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final List<Map<String, String>> _faqs = [
    {'id': 'faq1', 'q': 'faq1_q', 'a': 'faq1_a'},
    {'id': 'faq2', 'q': 'faq2_q', 'a': 'faq2_a'},
    {'id': 'faq3', 'q': 'faq3_q', 'a': 'faq3_a'},
    {'id': 'faq4', 'q': 'faq4_q', 'a': 'faq4_a'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _submitReport() {
    // placeholder for submission logic
    debugPrint('Reported: ${_titleController.text} - ${_descController.text}');
    _titleController.clear();
    _descController.clear();
    setState(() => _page = 'help');
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // floating particles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                return CustomPaint(
                  painter: _ParticlePainter(t, palette.primary),
                );
              },
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: _page == 'help'
                    ? _buildHelp(context)
                    : _buildReport(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelp(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.border),
                ),
                child: Icon(Icons.arrow_back, color: palette.primary),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  CustomLocalizations.of(context).get('helpSupport'),
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  CustomLocalizations.of(context).get('wereHereToHelp'),
                  style: TextStyle(color: palette.textSecondary),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          CustomLocalizations.of(context).get('frequentlyAskedQuestions'),
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        ..._faqs.map((f) {
          final id = f['id']!;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              collapsedIconColor: palette.primary,
              iconColor: palette.primary,
              title: Row(
                children: [
                  Icon(Icons.help_outline, color: palette.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      CustomLocalizations.of(context).get(f['q']!),
                      style: TextStyle(color: palette.textPrimary),
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
                  child: Text(
                    CustomLocalizations.of(context).get(f['a']!),
                    style: TextStyle(color: palette.textSecondary),
                  ),
                ),
              ],
              onExpansionChanged: (open) =>
                  setState(() => _expandedFaq = open ? id : ''),
            ),
          );
        }),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                palette.primary.withOpacity(0.08),
                const Color(0xFF8B5CF6).withOpacity(0.08),
              ],
            ),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                CustomLocalizations.of(context).get('quickHelp'),
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                CustomLocalizations.of(context).get('quickHelpDescription'),
                style: TextStyle(color: palette.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.surface,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: () => setState(() => _page = 'report'),
          child: Row(
            children: [
              Icon(Icons.report_problem, color: palette.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  CustomLocalizations.of(context).get('reportAProblem'),
                  style: TextStyle(color: palette.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReport(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _page = 'help'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Icon(Icons.arrow_back, color: palette.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          CustomLocalizations.of(context).get('reportAProblem'),
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          CustomLocalizations.of(context).get('tellUsWhatWentWrong'),
          style: TextStyle(color: palette.textSecondary),
        ),
        const SizedBox(height: 18),

        TextField(
          controller: _titleController,
          style: TextStyle(color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: CustomLocalizations.of(
              context,
            ).get('briefDescriptionOfIssue'),
            hintStyle: TextStyle(color: palette.textSecondary),
            filled: true,
            fillColor: palette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.primary, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descController,
          maxLines: 8,
          style: TextStyle(color: palette.textPrimary),
          decoration: InputDecoration(
            hintText: CustomLocalizations.of(context).get('reportDetailsHint'),
            hintStyle: TextStyle(color: palette.textSecondary),
            filled: true,
            fillColor: palette.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.primary, width: 1.2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitReport,
            icon: const Icon(Icons.send, color: Colors.white),
            label: Text(
              CustomLocalizations.of(context).get('submitReport'),
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(14),
              backgroundColor: palette.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final Color particleColor;
  _ParticlePainter(this.t, this.particleColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = particleColor.withOpacity(0.12);
    final rnd = Random(42);
    for (int i = 0; i < 30; i++) {
      final dx =
          (rnd.nextDouble() * size.width + sin(t * (0.5 + i * 0.02)) * 20) %
          size.width;
      final dy =
          (rnd.nextDouble() * size.height + cos(t * (0.4 + i * 0.015)) * 24) %
          size.height;
      canvas.drawCircle(Offset(dx, dy), 2 + (i % 3).toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}
