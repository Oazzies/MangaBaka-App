import 'package:flutter/material.dart';
import 'package:mangabaka_app/screens/browse_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    Placeholder(),
    Placeholder(),
    BrowseScreen(),
    Placeholder(),
    Placeholder(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: const Color(0xFF18181B),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
            iconTheme: WidgetStateProperty.all(
              const IconThemeData(color: Colors.white, size: 28),
            ),
          ),
          child: NavigationBar(
            backgroundColor: const Color(0xFF18181B),
            indicatorColor: Color(0xFF1b9f70),
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