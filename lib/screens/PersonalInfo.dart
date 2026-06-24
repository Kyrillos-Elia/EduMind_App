import 'dart:math';
import 'dart:io';

import 'package:ai_study_app/app_palette.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import 'AcademicInfo.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen>
    with TickerProviderStateMixin {
  final Map<String, String> formData = {
    'fullName': '',
    'username': '',
    'age': '',
    'phone': '',
    'sex': '',
  };

  String ageError = '';
  String phoneError = '';
  String sexError = '';

  final Random random = Random();

  // 🟢 image picker
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _imagePath = image.path;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPersonalInfo();
  }

  Future<void> _loadPersonalInfo() async {
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
          // Load personal data if it exists
          formData['fullName'] = data['fullName'] ?? '';
          formData['username'] = data['username'] ?? '';
          formData['age'] = data['age'] ?? '';
          formData['phone'] = data['phone'] ?? '';
          formData['sex'] = data['sex'] ?? '';
          _imagePath = data['imagePath'];

          // Update controllers
          _fullNameController.text = formData['fullName']!;
          _usernameController.text = formData['username']!;
          _ageController.text = formData['age']!;
          _phoneController.text = formData['phone']!;
        });
      }
    } catch (e) {
      debugPrint('Error loading personal info: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> saveData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User not logged in")));
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': formData['fullName'],
        'username': formData['username'],
        'age': formData['age'],
        'phone': formData['phone'],
        'sex': formData['sex'],
        'imagePath': _imagePath ?? '', // مؤقت
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Saved to Firestore ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
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
                  const SizedBox(height: 24),

                  // 🟢 صورة البروفايل
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: palette.surfaceAlt,
                          backgroundImage: _imagePath == null
                              ? null
                              : FileImage(File(_imagePath!)),
                          child: _imagePath == null
                              ? Icon(
                                  Icons.person,
                                  size: 40,
                                  color: palette.primary,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: palette.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  formCard(),

                  const SizedBox(height: 40),

                  Center(
                    child: Text(
                      AppLocalizations.of(context)!.poweredByEduMindAI,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
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
          AppLocalizations.of(context)!.personalInformation,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
        Text(
          AppLocalizations.of(context)!.tellUsAboutYourself,
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
            AppLocalizations.of(context)!.fullName,
            'fullName',
            AppLocalizations.of(context)!.enterYourFullName,
          ),
          const SizedBox(height: 16),
          buildField(
            AppLocalizations.of(context)!.username,
            'username',
            AppLocalizations.of(context)!.enterYourUsername,
          ),
          const SizedBox(height: 16),
          buildField(
            AppLocalizations.of(context)!.age,
            'age',
            AppLocalizations.of(context)!.enterYourAge,
          ),
          const SizedBox(height: 16),
          buildField(
            AppLocalizations.of(context)!.phoneNumber,
            'phoneNumber',
            AppLocalizations.of(context)!.enterYourPhoneNumber,
          ),
          const SizedBox(height: 16),
          buildSexDropdown(),
          const SizedBox(height: 28),

          // 🔴 زرار Save بدل Next
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AcademicScreen(
                      personalData: formData,
                      imagePath: _imagePath,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: palette.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Next",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildField(String label, String key, String placeholder) {
    final palette = AppPalette.of(context);

    TextEditingController? controller;
    if (key == 'fullName') {
      controller = _fullNameController;
    } else if (key == 'username')
      controller = _usernameController;
    else if (key == 'age')
      controller = _ageController;
    else if (key == 'phone')
      controller = _phoneController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: palette.textPrimary, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: (value) => setState(() => formData[key] = value),
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: palette.surfaceAlt,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget buildSexDropdown() {
    final palette = AppPalette.of(context);
    return InkWell(
      onTap: showSexPicker,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          formData['sex']!.isEmpty ? "Choose your sex" : formData['sex']!,
        ),
      ),
    );
  }

  void showSexPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text("Male"),
            onTap: () {
              setState(() => formData['sex'] = 'male');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text("Female"),
            onTap: () {
              setState(() => formData['sex'] = 'female');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class Particles extends StatelessWidget {
  const Particles({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
