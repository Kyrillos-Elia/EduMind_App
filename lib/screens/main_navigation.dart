import 'package:flutter/material.dart';
import 'package:ai_study_app/app_palette.dart';
import '../l10n/app_localizations.dart';

import 'ProfilePage.dart';
import 'StatsPage.dart';
import 'TaskScreen.dart';
import 'home_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(
        onProfileTap: () {
          setState(() {
            _currentIndex = 3;
          });
        },
      ),
      const TaskScreen(),
      const StatsPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.bgTop, palette.bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(top: BorderSide(color: palette.border, width: 0.8)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: palette.primary,
            unselectedItemColor: palette.primarySoft,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            showUnselectedLabels: true,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: localizations.home,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.task_alt_outlined),
                activeIcon: const Icon(Icons.task_alt),
                label: localizations.task,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.bar_chart_outlined),
                activeIcon: const Icon(Icons.bar_chart_rounded),
                label: localizations.stats,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: localizations.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
