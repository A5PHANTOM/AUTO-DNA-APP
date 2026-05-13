import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import 'dashboard_screen.dart';
import 'report_incident_screen.dart';
import 'search_screen.dart';
import 'marketplace_screen.dart';
import 'my_listings_screen.dart';
import 'spare_parts_screen.dart';
import 'repair_requests_screen.dart';
import 'chat_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> _getPages(String role) {
    if (role == 'workshop') {
      return [
        DashboardScreen(),
        ReportIncidentScreen(),
        RepairRequestsScreen(),
        SparePartsScreen(),
        ChatListScreen(),
      ];
    }
    return [
      DashboardScreen(),
      ReportIncidentScreen(),
      SearchScreen(),
      MarketplaceScreen(),
      MyListingsScreen(),
      SparePartsScreen(),
      RepairRequestsScreen(),
      ChatListScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getNavItems(String role) {
    if (role == 'workshop') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Report'),
        BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'Repairs'),
        BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Parts'),
        BottomNavigationBarItem(icon: Icon(Icons.message_rounded), label: 'Messages'),
      ];
    }
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Report'),
      BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
      BottomNavigationBarItem(icon: Icon(Icons.storefront_rounded), label: 'Market'),
      BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Listings'),
      BottomNavigationBarItem(icon: Icon(Icons.build_circle), label: 'Parts'),
      BottomNavigationBarItem(icon: Icon(Icons.handyman), label: 'Repairs'),
      BottomNavigationBarItem(icon: Icon(Icons.message_rounded), label: 'Messages'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AuthProvider>(context).role;
    final pages = _getPages(role);
    final navItems = _getNavItems(role);

    if (_currentIndex >= pages.length) _currentIndex = 0;

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
        child: pages[_currentIndex],
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
          selectedFontSize: 10,
          unselectedFontSize: 10,
          elevation: 0,
          items: navItems,
        ),
      ),
    );
  }
}
