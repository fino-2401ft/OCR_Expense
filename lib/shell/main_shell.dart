import 'package:flutter/material.dart';

import '../features/analytics/presentation/analytics_screen.dart';
import '../features/expenses/presentation/home_screen.dart';
import '../features/scan/presentation/scan_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _refreshToken = 0;

  void _onTab(int i) {
    setState(() {
      // Refresh list/analytics when leaving scan after potential saves.
      if (_index == 1 && i != 1) {
        _refreshToken++;
      }
      _index = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'Scan', 'Analytics'];
    final body = switch (_index) {
      0 => HomeScreen(refreshToken: _refreshToken),
      1 => const ScanScreen(),
      _ => AnalyticsScreen(refreshToken: _refreshToken),
    };

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
