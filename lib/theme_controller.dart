import 'package:flutter/material.dart';

/// Global notifier to switch app theme at runtime.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.dark,
);

/// Global notifier for app locale.
final ValueNotifier<Locale> localeNotifier = ValueNotifier(
  const Locale('en'), // Default to English
);

final ThemeData appLightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  primaryColor: const Color(0xFF2563EB), // blue-600
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6D28D9),
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
    iconTheme: IconThemeData(color: Color(0xFF2563EB)),
  ),
  cardColor: const Color(0xFFF8FAFC),
  listTileTheme: const ListTileThemeData(
    iconColor: Color(0xFF2563EB),
    textColor: Colors.black,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

final ThemeData appDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0B0F2A),
  primaryColor: const Color(0xFF3B82F6),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF8B5CF6),
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0B0F2A),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardColor: const Color(0xFF0F1724).withOpacity(0.6),
  listTileTheme: const ListTileThemeData(
    iconColor: Color(0xFF3B82F6),
    textColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
  ),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);
