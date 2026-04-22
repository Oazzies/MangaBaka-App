import 'package:flutter/material.dart';
import 'package:bakahyou/features/browse/screens/browse_screen.dart';
import 'package:bakahyou/features/library/screens/library_screen.dart';
import 'package:bakahyou/features/news/screens/news_screen.dart';
import 'package:bakahyou/features/profile/screens/profile_screen.dart';
import 'package:bakahyou/utils/constants/app_constants.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    Placeholder(),
    LibraryScreen(),
    BrowseScreen(),
    NewsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.secondaryBackground,
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppConstants.secondaryBackground,
            labelTextStyle: WidgetStateProperty.all(
              TextStyle(color: AppConstants.textColor, fontSize: 12),
            ),
            iconTheme: WidgetStateProperty.all(
              IconThemeData(color: AppConstants.textColor, size: 28),
            ),
          ),
          child: NavigationBar(
            backgroundColor: AppConstants.secondaryBackground,
            indicatorColor: AppConstants.accentColor,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: "Home",
              ),
              NavigationDestination(
                icon: Icon(Icons.library_books_outlined),
                selectedIcon: Icon(Icons.library_books),
                label: "Library",
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: "Browse",
              ),
              NavigationDestination(
                icon: Icon(Icons.article_outlined),
                selectedIcon: Icon(Icons.article),
                label: "News",
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
