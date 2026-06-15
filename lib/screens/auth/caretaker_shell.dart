import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../profile/profile_screen.dart';
import '../caretaker/task_hub_screen.dart';
import '../caretaker/application_review_screen.dart';
import '../caretaker/maintenance_board_screen.dart';

class CaretakerShell extends StatefulWidget {
  const CaretakerShell({super.key});

  @override
  State<CaretakerShell> createState() => _CaretakerShellState();
}

class _CaretakerShellState extends State<CaretakerShell> {
  int _currentIndex = 0;

  final _screens = [
    const CaretakerTaskHub(),
    const ApplicationReviewScreen(),
    const MaintenanceBoardScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) {
          setState(() => _currentIndex = i);
          HapticFeedback.selectionClick();
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Hub'),
          NavigationDestination(
              icon: Icon(Icons.pending_actions_outlined),
              selectedIcon: Icon(Icons.pending_actions),
              label: 'Apps'),
          NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build),
              label: 'Maintenance'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
