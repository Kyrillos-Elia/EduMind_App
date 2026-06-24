import 'package:ai_study_app/screens/EmailVerificationScreen.dart';
import 'package:ai_study_app/screens/login_screen.dart';
import 'package:ai_study_app/screens/main_navigation.dart';
import 'package:ai_study_app/screens/onboarding_page.dart';
import 'package:ai_study_app/screens/splash_screen.dart';

import 'package:flutter/material.dart';
import 'theme_controller.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _loadSavedSettings();
  runApp(const MyApp());
}

Future<void> _loadSavedSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString('language');
  final themeCode = prefs.getString('theme');

  if (languageCode == 'ar') {
    localeNotifier.value = const Locale('ar');
  } else if (languageCode == 'en') {
    localeNotifier.value = const Locale('en');
  }

  if (themeCode == 'light') {
    themeModeNotifier.value = ThemeMode.light;
  } else if (themeCode == 'dark') {
    themeModeNotifier.value = ThemeMode.dark;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'AI Study App',
              theme: appLightTheme,
              darkTheme: appDarkTheme,
              themeMode: mode,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],

              /// 🔥 هنا التحكم في الفلو كله
              home: const AuthWrapper(),

              routes: {
                '/onboarding': (context) => const OnboardingScreen(),
                '/login': (context) => const LoginScreen(),
                '/home': (context) => const MainNavigation(),
                '/verify-email': (context) => const EmailVerificationScreen(),
              },
            );
          },
        );
      },
    );
  }
}

////////////////////////////////////////////////////////////
/// 🔥 Auth Wrapper
////////////////////////////////////////////////////////////

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool isLoading = true;
  Widget? screen;

  @override
  void initState() {
    super.initState();
    checkUser();
  }

  Future<void> checkUser() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash effect

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    if (!seenOnboarding) {
      /// ❌ مش شاف الـ Onboarding
      screen = const OnboardingScreen();
    } else {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        /// ❌ مفيش يوزر
        screen = const LoginScreen();
      } else {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (user!.emailVerified) {
          /// ✅ مفعل
          screen = const MainNavigation();
        } else {
          /// ❌ مش مفعل → يروح شاشة التفعيل
          screen = const EmailVerificationScreen();
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SplashScreen();
    } else {
      return screen!;
    }
  }
}
