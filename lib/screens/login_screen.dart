import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ai_study_app/app_palette.dart';
import 'signup_screen.dart';
import 'main_navigation.dart';
import '../l10n/app_localizations.dart';
import '../localization_helper.dart';
import '../theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool showPassword = false;

  late AnimationController glowController;
  late Animation<double> glowAnimation;

  @override
  void initState() {
    super.initState();

    /// ✨ Glow Animation
    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    )..repeat(reverse: true);

    glowAnimation = Tween<double>(
      begin: 0.2,
      end: 1,
    ).animate(CurvedAnimation(parent: glowController, curve: Curves.easeInOut));
  }

  /// ================= Google =================
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? user = await GoogleSignIn().signIn();
    if (user == null) return null;

    final auth = await user.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// ================= Theme Toggle =================
  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    prefs.setString(
      'theme',
      themeModeNotifier.value == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  /// ================= Language Dialog =================
  void _showLanguageDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    final prefs = await SharedPreferences.getInstance();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                localeNotifier.value = const Locale('en');
                prefs.setString('language', 'en');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('العربية'),
              onTap: () {
                localeNotifier.value = const Locale('ar');
                prefs.setString('language', 'ar');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          /// 🔥 BACKGROUND
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.bgTop, palette.bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// � SETTINGS ICONS
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                // Language Icon
                IconButton(
                  icon: Icon(
                    Icons.language,
                    color: palette.textPrimary,
                    size: 28,
                  ),
                  onPressed: () => _showLanguageDialog(context),
                ),
                const SizedBox(width: 10),
                // Theme Icon
                IconButton(
                  icon: Icon(
                    palette.isDark ? Icons.light_mode : Icons.dark_mode,
                    color: palette.textPrimary,
                    size: 28,
                  ),
                  onPressed: () => _toggleTheme(),
                ),
              ],
            ),
          ),

          /// �💎 CONTENT
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  Text(
                    localizations.appTitle,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    localizations.yourSmartCompanion,
                    style: TextStyle(color: palette.textSecondary),
                  ),

                  const SizedBox(height: 40),

                  /// ✨✨ الكارد بالـ Glow ✨✨
                  AnimatedBuilder(
                    animation: glowAnimation,
                    builder: (context, child) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(24),

                          /// 🔥 glow
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withOpacity(
                                0.4 * glowAnimation.value,
                              ),
                              blurRadius: 25 * glowAnimation.value,
                              spreadRadius: 2,
                            ),
                          ],

                          /// 🔥 border بيشع
                          border: Border.all(
                            color: palette.primary.withOpacity(
                              0.3 * glowAnimation.value,
                            ),
                          ),
                        ),
                        child: child,
                      );
                    },

                    /// 👇 المحتوى جوه الكارد
                    child: Column(
                      children: [
                        CustomInput(
                          icon: Icons.email,
                          hint: localizations.email,
                          controller: emailController,
                        ),

                        const SizedBox(height: 20),

                        CustomInput(
                          icon: Icons.lock,
                          hint: localizations.password,
                          controller: passwordController,
                          obscure: !showPassword,
                          suffix: IconButton(
                            icon: Icon(
                              showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: palette.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 30),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: palette.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                final credential = await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                      email: emailController.text.trim(),
                                      password: passwordController.text.trim(),
                                    );

                                final user = credential.user;

                                /// تحقق من التفعيل
                                if (user!.emailVerified) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MainNavigation(),
                                    ),
                                  );
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/verify-email',
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                            child: Text(
                              localizations.signIn,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: palette.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () async {
                              final user = await signInWithGoogle();
                              if (user != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      CustomLocalizations.of(
                                        context,
                                      ).get('googleSuccess'),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              localizations.continueWithGoogle,
                              style: TextStyle(color: palette.textPrimary),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              localizations.noAccount,
                              style: TextStyle(color: palette.textSecondary),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignUpScreenNew(),
                                  ),
                                );
                              },
                              child: Text(
                                localizations.signUp,
                                style: TextStyle(color: palette.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Text(
                    localizations.agreeTerms,
                    style: TextStyle(color: palette.textSecondary),
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

class FloatingParticles extends StatelessWidget {
  const FloatingParticles({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Stack(
      children: List.generate(30, (index) {
        return Positioned(
          left: (index * 13.0) % MediaQuery.of(context).size.width,
          top: (index * 29.0) % MediaQuery.of(context).size.height,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 20.0),
            duration: Duration(seconds: 3 + index % 5),
            curve: Curves.easeInOut,
            builder: (_, value, _) {
              return Transform.translate(
                offset: Offset(0, -value),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.2, end: 1.0),
                  duration: Duration(seconds: 2 + (index % 3)),
                  curve: Curves.easeInOut,
                  builder: (_, opacityValue, _) {
                    return Opacity(
                      opacity: opacityValue,
                      child: Container(
                        width:
                            4 + (index % 3).toDouble(), // اختلاف بسيط في الحجم
                        height: 4 + (index % 3).toDouble(),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.primary.withOpacity(0.4),
                          boxShadow: [
                            BoxShadow(
                              color: palette.primary.withOpacity(0.6),
                              blurRadius: 8, // 👈 ده ال glow الحقيقي
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
