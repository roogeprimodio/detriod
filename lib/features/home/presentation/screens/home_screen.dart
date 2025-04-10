import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/providers/theme_provider.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';
import 'package:frenzy/core/widgets/common_bottom_nav.dart';
// Import placeholder screens (create these files if they don't exist)
import 'package:frenzy/features/home/presentation/screens/dashboard_screen.dart';
import 'package:frenzy/features/home/presentation/screens/live_view_screen.dart';
import 'package:frenzy/features/home/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;

  // Define the screens for the tabs
  final List<Widget> _screens = [
    const DashboardScreen(), // Screen containing the game grid
    const LiveViewScreen(), // Placeholder for Live View
    const ProfileScreen(), // Placeholder for Profile
  ];

  // Define the items for the bottom navigation
  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.live_tv_outlined),
      activeIcon: Icon(Icons.live_tv),
      label: 'Live',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _screens.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      } else if (_tabController.index != _currentIndex) {
        // Handle programmatic changes if needed, or ensure sync
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Live View';
      case 2:
        return 'Profile';
      default:
        return 'Frenzy';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme provider is available via CommonAppBar/CommonBottomNav contexts

    return Scaffold(
      // Use CommonAppBar with dynamic title
      appBar: CommonAppBar(
        title: _getTitleForIndex(_currentIndex),
        // Add any specific actions for the home screen if needed
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none), // Example action
            onPressed: () {
              // TODO: Implement notifications action
            },
          ),
        ],
      ),
      // Use TabBarView for the main content
      body: TabBarView(
        controller: _tabController,
        children: _screens,
      ),
      // Use CommonBottomNav
      bottomNavigationBar: CommonBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _tabController.animateTo(index);
          });
        },
        items: _navItems,
      ),
    );
  }
}
