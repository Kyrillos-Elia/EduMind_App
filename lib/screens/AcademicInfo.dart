import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ai_study_app/app_palette.dart';
import '../localization_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcademicScreen extends StatefulWidget {
  final Map<String, String> personalData;
  final String? imagePath;

  const AcademicScreen({super.key, required this.personalData, this.imagePath});

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen>
    with TickerProviderStateMixin {
  final Map<String, String> formData = {
    'university': '',
    'faculty': '',
    'major': '',
    'academicYear': '',
    'gpa': '',
  };

  // Controllers to reflect loaded data
  final _universityController = TextEditingController();
  final _facultyController = TextEditingController();
  final _majorController = TextEditingController();
  final _gpaController = TextEditingController();

  String gpaError = '';
  String focusedField = '';
  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAcademicInfo();
  }

  Future<void> _loadAcademicInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          // Load academic data if it exists
          formData['university'] = data['university'] ?? '';
          formData['faculty'] = data['faculty'] ?? '';
          formData['major'] = data['major'] ?? '';
          formData['academicYear'] = data['academicYear'] ?? '';
          formData['gpa'] = data['gpa'] ?? '';

          // Update controllers
          _universityController.text = formData['university']!;
          _facultyController.text = formData['faculty']!;
          _majorController.text = formData['major']!;
          _gpaController.text = formData['gpa']!;

          // Check if academic data already exists (if university is not empty)
          if (data['university'] != null &&
              data['university'].toString().isNotEmpty &&
              data['academicYear'] != null &&
              data['academicYear'].toString().isNotEmpty) {
            _isSaved = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading academic info: $e');
    }
  }

  @override
  void dispose() {
    _universityController.dispose();
    _facultyController.dispose();
    _majorController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  void handleGpaChange(String value) {
    final regex = RegExp(r'^\d+\.?\d*$');
    if (value.isNotEmpty && regex.hasMatch(value)) {
      setState(() {
        formData['gpa'] = value;
        final numValue = double.tryParse(value);
        if (numValue == null) {
          gpaError = 'Please enter a valid number';
        } else if (numValue < 0 || numValue > 4) {
          gpaError = 'GPA must be between 0.0 and 4.0';
        } else {
          gpaError = '';
        }
      });
    } else {
      setState(() {
        formData['gpa'] = value;
        gpaError = '';
      });
    }
  }

  bool get isGpaValid {
    final gpa = formData['gpa']!;
    final val = double.tryParse(gpa);
    return gpa.isNotEmpty &&
        gpaError.isEmpty &&
        val != null &&
        val >= 0 &&
        val <= 4;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.bgTop, palette.bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const Particles(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header(),
                  const SizedBox(height: 32),
                  formCard(),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Powered by EduMind AI',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
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

  Widget header() {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surface,
              border: Border.all(color: palette.border),
            ),
            child: Icon(
              Icons.arrow_back,
              color: palette.textSecondary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Academic Information',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        Text(
          CustomLocalizations.of(context).get('yourEducationalDetails'),
          style: TextStyle(color: palette.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget formCard() {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildField(
            CustomLocalizations.of(context).get('universityName'),
            'university',
            CustomLocalizations.of(context).get('enterYourUniversity'),
            controller: _universityController,
          ),
          const SizedBox(height: 16),
          buildField(
            CustomLocalizations.of(context).get('facultyCollege'),
            'faculty',
            CustomLocalizations.of(context).get('enterYourFaculty'),
            controller: _facultyController,
          ),
          const SizedBox(height: 16),
          buildField(
            CustomLocalizations.of(context).get('majorFieldOfStudy'),
            'major',
            CustomLocalizations.of(context).get('enterYourMajor'),
            controller: _majorController,
          ),
          const SizedBox(height: 16),
          buildDropdown(),
          const SizedBox(height: 16),
          gpaField(),
          const SizedBox(height: 28),
          saveButton(),
        ],
      ),
    );
  }

  Widget buildField(
    String label,
    String key,
    String placeholder, {
    TextEditingController? controller,
  }) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (v) => formData[key] = v,
          style: TextStyle(color: palette.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: palette.textSecondary, fontSize: 14),
            filled: true,
            fillColor: palette.surfaceAlt,
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
              borderSide: BorderSide(color: palette.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDropdown() {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CustomLocalizations.of(context).get('academicYear'),
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            dropdownColor: palette.surfaceAlt,
            initialValue: formData['academicYear']!.isEmpty
                ? null
                : formData['academicYear'],
            items: [
              DropdownMenuItem(
                value: '1',
                child: Text(
                  '${CustomLocalizations.of(context).get('academicYear')} 1',
                ),
              ),
              DropdownMenuItem(
                value: '2',
                child: Text(
                  '${CustomLocalizations.of(context).get('academicYear')} 2',
                ),
              ),
              DropdownMenuItem(
                value: '3',
                child: Text(
                  '${CustomLocalizations.of(context).get('academicYear')} 3',
                ),
              ),
              DropdownMenuItem(
                value: '4',
                child: Text(
                  '${CustomLocalizations.of(context).get('academicYear')} 4',
                ),
              ),
              DropdownMenuItem(
                value: 'graduate',
                child: Text(CustomLocalizations.of(context).get('graduate')),
              ),
            ],
            onChanged: (v) =>
                setState(() => formData['academicYear'] = v ?? ''),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              isDense: true,
            ),
            style: TextStyle(color: palette.textPrimary, fontSize: 14),
            icon: Icon(Icons.arrow_drop_down, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget gpaField() {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          CustomLocalizations.of(context).get('gpa'),
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            TextField(
              controller: _gpaController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: handleGpaChange,
              style: TextStyle(color: palette.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: CustomLocalizations.of(context).get('gpaRangeHint'),
                hintStyle: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: palette.surfaceAlt,
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
                  borderSide: BorderSide(color: palette.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            if (isGpaValid)
              const Positioned(
                right: 15,
                top: 16,
                child: Icon(Icons.check_circle, color: Colors.green, size: 20),
              ),
          ],
        ),
        if (gpaError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              gpaError,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget saveButton() {
    final palette = AppPalette.of(context);
    if (_isSaved) {
      return const SizedBox.shrink(); // Hide the button after saving
    }
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving
            ? null
            : () async {
                setState(() => _isSaving = true);
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    throw 'User not logged in';
                  }
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({
                        'fullName': widget.personalData['fullName'] ?? '',
                        'username': widget.personalData['username'] ?? '',
                        'age': widget.personalData['age'] ?? '',
                        'sex': widget.personalData['sex'] ?? '',
                        'phone': widget.personalData['phone'] ?? '',
                        'imagePath': widget.imagePath ?? '',
                        'university': formData['university'] ?? '',
                        'faculty': formData['faculty'] ?? '',
                        'major': formData['major'] ?? '',
                        'academicYear': formData['academicYear'] ?? '',
                        'gpa': formData['gpa'] ?? '',
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                  if (!mounted) return;
                  setState(() => _isSaved = true); // Mark as saved
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All information saved successfully'),
                    ),
                  );
                  // Removed Navigator.pop(context) to stay on the page
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                CustomLocalizations.of(context).get('saveInformation'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class Particles extends StatefulWidget {
  const Particles({super.key});

  @override
  State<Particles> createState() => _ParticlesState();
}

class _ParticlesState extends State<Particles>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        return CustomPaint(painter: ParticlePainter(), child: Container());
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final rand = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.withOpacity(0.3);
    for (int i = 0; i < 20; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
