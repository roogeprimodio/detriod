import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frenzy/core/widgets/common_app_bar.dart';
import 'package:frenzy/core/widgets/common_bottom_nav.dart';
import 'package:frenzy/core/providers/auth_provider.dart';
import 'package:frenzy/features/home/presentation/screens/dashboard_screen.dart';
import 'package:frenzy/features/home/presentation/screens/live_view_screen.dart';
import 'package:frenzy/features/home/presentation/screens/profile_screen.dart';
import 'package:frenzy/features/home/presentation/widgets/custom_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late TabController _tabController;

  late List<Widget> _screens;

  void _initializeScreens(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    _screens = [
      const DashboardScreen(), // Screen containing the game grid
      const LiveViewScreen(), // Placeholder for Live View
      ProfileScreen(userId: authProvider.user?.uid ?? '', email: authProvider.user?.email ?? ''),
    ];
  }

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
    _tabController = TabController(length: 3, vsync: this);
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
    // Initialize screens with auth context
    _initializeScreens(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Home',
      ),
      body: TabBarView(
        controller: _tabController,
        children: _screens,
      ),
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
