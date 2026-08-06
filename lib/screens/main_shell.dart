import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'tabs/analytics_tab.dart';
import 'tabs/farms_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/visits_tab.dart';

/// The signed-in shell: four peer tabs behind a bottom nav.
/// Detail screens (farm detail, the evaluation wizard, visit detail)
/// are pushed OVER this shell — they are not tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 0 = Home, 1 = Farms, 2 = Visits, 3 = Analytics.
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: SafeArea(
        // IndexedStack keeps every tab alive; switching shows another
        // child without rebuilding it, so scroll positions and typed
        // search text survive tab hops.
        child: IndexedStack(
          index: _index,
          children: const [
            HomeTab(),
            FarmsTab(),
            VisitsTab(),
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Farms',
          ),
          BottomNavigationBarItem(
            // ImageIcon takes its colour from the nav bar, so the same
            // asset renders muted when unselected and green when active.
            icon: ImageIcon(AssetImage('assets/icons/bull_head.png')),
            label: 'Visits',
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