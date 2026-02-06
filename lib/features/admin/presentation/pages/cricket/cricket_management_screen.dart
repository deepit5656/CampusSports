import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import 'cricket_teams_tab.dart';
import 'cricket_matches_tab.dart';
import 'cricket_history_tab.dart';

class CricketManagementScreen extends StatefulWidget {
  final String sportId;
  final String sportName;

  const CricketManagementScreen({
    Key? key,
    required this.sportId,
    required this.sportName,
  }) : super(key: key);

  @override
  State<CricketManagementScreen> createState() => _CricketManagementScreenState();
}

class _CricketManagementScreenState extends State<CricketManagementScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _tabs = [
      CricketMatchesTab(sportId: widget.sportId),
      CricketTeamsTab(sportId: widget.sportId),
      CricketHistoryTab(sportId: widget.sportId),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.sports_cricket, color: Color(0xFF10b981)),
            const SizedBox(width: 8),
            Text(
              '${widget.sportName} Management',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF10b981),
          unselectedItemColor: AppTheme.textSecondary,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'New Match',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups),
              label: 'Teams',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}
