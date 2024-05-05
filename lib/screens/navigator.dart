import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:harvest_guardian/constants.dart';
import 'package:harvest_guardian/screens/community_screen.dart';
import 'package:harvest_guardian/screens/home_screen.dart';
import 'package:harvest_guardian/screens/profile_screen.dart';

class PageNavigator extends StatefulWidget {
  const PageNavigator({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PageNavigatorState createState() => _PageNavigatorState();
}

class _PageNavigatorState extends State<PageNavigator> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const CommunityPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 50,
        backgroundColor: Colors.transparent,
        color: Constants.primaryColor,
        buttonBackgroundColor: Constants.primaryColor,
        animationDuration: const Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.group, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}
