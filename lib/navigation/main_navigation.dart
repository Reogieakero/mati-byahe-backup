import 'package:flutter/material.dart';
import 'widgets/passenger_nav_bar.dart';
import 'widgets/driver_nav_bar.dart';
import 'navigation_screens.dart';

class MainNavigation extends StatefulWidget {
  final String email;
  final String role;

  const MainNavigation({super.key, required this.email, required this.role});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    bool isDriver = widget.role.toLowerCase() == 'driver';
    final screens = NavigationScreens.getScreens(widget.email, widget.role);

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: !isDriver,
      body: IndexedStack(index: _selectedIndex, children: screens),
      floatingActionButton: isDriver
          ? null
          : PassengerFloatingButton(
              animation: _floatingAnimation,
              onTap: () => _onItemTapped(2),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isDriver
          ? DriverNavBar(selectedIndex: _selectedIndex, onTap: _onItemTapped)
          : PassengerNavBar(
              selectedIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
    );
  }
}
