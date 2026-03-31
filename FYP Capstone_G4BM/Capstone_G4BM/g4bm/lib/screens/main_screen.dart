import 'package:flutter/material.dart';
import 'home_page.dart';
import 'explore_page.dart';
import 'schedule_page.dart';
import 'profile_page.dart';
import 'community_page.dart';

class MainScreen extends StatefulWidget {
  final bool showSuccessDialog;

  const MainScreen({super.key, this.showSuccessDialog = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(showSuccessDialog: widget.showSuccessDialog),
      const ExplorePage(),
      const SchedulePage(),

      const CommunityPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack remembers the state of all pages so they don't reload!
      body: IndexedStack(index: _currentIndex, children: _pages),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Instantly swaps the view
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[400],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey[700],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "Explore"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Schedule",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
