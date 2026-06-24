import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ai_study_app/app_palette.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with TickerProviderStateMixin {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _academicYearController = TextEditingController();
  final _gpaController = TextEditingController();
  final _aboutController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _defaultImageUrl =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde';
  final _imagePicker = ImagePicker();

  bool _showPasswordFields = false;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _emailChanged = false;
  String? _pickedImagePath;
  String? _currentImagePath;

  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _emailController.addListener(_onEmailChanged);
    _loadUserData();
  }

  @override
  void dispose() {
    _particleController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _academicYearController.dispose();
    _gpaController.dispose();
    _aboutController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _emailChanged = _emailController.text.trim() != (user.email ?? '');
      });
    }
  }

  Future<void> _loadUserData() async {
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
          _fullNameController.text = data['fullName'] ?? '';
          _usernameController.text = data['username'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = data['phone'] ?? '';
          _academicYearController.text = data['academicYear'] ?? '';
          _gpaController.text = data['gpa'] ?? '';
          _aboutController.text = data['about'] ?? '';
          _currentImagePath = data['imagePath'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _emailController.text = user.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in')));
        return;
      }

      // Reauthenticate if email or password is being changed
      if (_emailChanged || _newPasswordController.text.isNotEmpty) {
        if (_currentPasswordController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please enter your current password to confirm changes',
              ),
            ),
          );
          setState(() => _isSaving = false);
          return;
        }

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'academicYear': _academicYearController.text.trim(),
        'gpa': _gpaController.text.trim(),
        'about': _aboutController.text.trim(),
        'imagePath': _pickedImagePath ?? _currentImagePath ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update Auth if email changed
      // if (_emailChanged) {
      //   await user.updateEmail(_emailController.text.trim());
      // }

      // Update password if provided
      if (_newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text == _confirmPasswordController.text) {
          await user.updatePassword(_newPasswordController.text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match')),
          );
          setState(() => _isSaving = false);
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted || image == null) return;

    setState(() {
      _pickedImagePath = image.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
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
          Particles(color: palette.primary),
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBackButton(),
                        const SizedBox(height: 10),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 28,
                            color: palette.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage your personal information',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Center(child: _buildProfileImage()),
                        const SizedBox(height: 22),
                        _buildFormCard(),
                        const SizedBox(height: 20),
                        _buildButtons(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    final palette = AppPalette.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: _goBack,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.surface,
            border: Border.all(color: palette.border),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: palette.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final palette = AppPalette.of(context);
    final ImageProvider imageProvider = _pickedImagePath != null
        ? FileImage(File(_pickedImagePath!))
        : _currentImagePath != null && _currentImagePath!.isNotEmpty
        ? FileImage(File(_currentImagePath!))
        : NetworkImage(_defaultImageUrl);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 142,
          height: 142,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: palette.primary.withOpacity(0.55),
                blurRadius: 28,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        CircleAvatar(
          key: ValueKey(
            _pickedImagePath ?? _currentImagePath ?? _defaultImageUrl,
          ),
          radius: 60,
          backgroundColor: palette.surfaceAlt,
          backgroundImage: imageProvider,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: PopupMenuButton<String>(
            tooltip: 'Change profile photo',
            color: palette.surfaceAlt,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: palette.border),
            ),
            offset: const Offset(0, 44),
            onSelected: (value) {
              if (value == 'Upload') {
                _pickImageFromGallery();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'Upload',
                child: Row(
                  children: [
                    Icon(Icons.upload, color: palette.primary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Upload',
                      style: TextStyle(color: palette.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _field(
            label: 'Full Name',
            icon: Icons.person_outline,
            controller: _fullNameController,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Username',
            icon: Icons.alternate_email,
            controller: _usernameController,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Email Address',
            icon: Icons.email_outlined,
            controller: _emailController,
          ),
          const SizedBox(height: 14),
          if (_emailChanged || _showPasswordFields) ...[
            _passwordField(
              label: 'Enter current password to confirm',
              controller: _currentPasswordController,
            ),
            const SizedBox(height: 14),
          ],
          _field(
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            controller: _phoneController,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Academic Year',
            icon: Icons.school_outlined,
            controller: _academicYearController,
          ),
          const SizedBox(height: 14),
          _field(
            label: 'GPA',
            icon: Icons.grade_outlined,
            controller: _gpaController,
          ),
          const SizedBox(height: 14),
          _passwordSection(),
          const SizedBox(height: 14),
          _field(
            label: 'About Me',
            icon: Icons.info_outline,
            controller: _aboutController,
            maxLines: 3,
            alignTop: true,
          ),
        ],
      ),
    );
  }

  Widget _passwordSection() {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _showPasswordFields = !_showPasswordFields),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Change Password',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                _showPasswordFields ? Icons.expand_less : Icons.expand_more,
                color: palette.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_showPasswordFields) ...[
          _passwordField(
            label: 'Enter new password',
            controller: _newPasswordController,
          ),
          const SizedBox(height: 14),
          _passwordField(
            label: 'Confirm password',
            controller: _confirmPasswordController,
          ),
        ],
      ],
    );
  }

  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    bool alignTop = false,
  }) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: palette.textPrimary, fontSize: 15),
          textAlignVertical: alignTop
              ? TextAlignVertical.top
              : TextAlignVertical.center,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: palette.primary, size: 20),
            filled: true,
            fillColor: palette.surfaceAlt,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: palette.primary, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
  }) {
    final palette = AppPalette.of(context);
    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: palette.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock_outline, color: palette.primary, size: 20),
        hintText: label,
        hintStyle: TextStyle(color: palette.textSecondary),
        filled: true,
        fillColor: palette.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: palette.primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    final palette = AppPalette.of(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: Text(
              _isSaving ? 'Saving...' : 'Save Changes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: _goBack,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: palette.primary, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: palette.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // TextButton(
        //   onPressed: () {},
        //   child: const Text(
        //     'Delete Account',
        //     style: TextStyle(
        //       color: Color(0xFFFF5B5B),
        //       fontSize: 14,
        //       fontWeight: FontWeight.w600,
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

class Particles extends StatefulWidget {
  final Color color;

  const Particles({super.key, required this.color});

  @override
  State<Particles> createState() => _ParticlesState();
}

class _ParticlesState extends State<Particles>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
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
        return CustomPaint(
          painter: ParticlePainter(controller.value, widget.color),
          size: Size.infinite,
        );
      },
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.45);
    final rand = Random(7);

    for (int i = 0; i < 28; i++) {
      final x = rand.nextDouble() * size.width;
      final y =
          ((rand.nextDouble() * size.height) + (progress * 20)) % size.height;
      canvas.drawCircle(Offset(x, y), 1.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
