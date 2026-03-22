import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'dashboard_screen.dart';
import 'report_incident_screen.dart';
import 'search_screen.dart';
import 'marketplace_screen.dart';
import 'my_listings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    ReportIncidentScreen(),
    SearchScreen(),
    MarketplaceScreen(),
    MyListingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUTO DNA', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF3B82F6)),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF1E293B),
          selectedItemColor: const Color(0xFF3B82F6),
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Report'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Market'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Listings'),
          ],
        ),
      ),
    );
  }
}
