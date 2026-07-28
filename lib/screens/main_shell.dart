import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/farms_tab.dart';
import 'tabs/home_tab.dart';
import '../widgets/app_drawer.dart';

/// The signed-in shell: three peer tabs behind a bottom nav.
/// Detail screens (farm detail, evaluation wizard) are pushed here
/// OVER this shell with Navigator.push — they are not tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 0 = Farms, 1 = Home, 2 = Analytics. Home is the center default.
  int _index = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //drawer
      drawer: const AppDrawer(),
      body: SafeArea(
        // IndexedStack keeps all three tabs alive; switching tabs
        // shows another child without rebuilding it, so scroll
        // positions and typed search text survive tab hops.
        child: IndexedStack(
          index: _index,
          children: const [
            FarmsTab(),
            HomeTab(),
            AnalyticsTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF181818),
        selectedItemColor: AppColors.greenLight,
        unselectedItemColor: AppColors.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Farms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}