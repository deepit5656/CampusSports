import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _matchUpdates = true;
  bool _matchReminders = true;
  bool _newMatches = true;
  bool _standings = false;
  bool _teamUpdates = true;
  bool _sounds = true;
  bool _vibration = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _matchUpdates = prefs.getBool('notif_match_updates') ?? true;
      _matchReminders = prefs.getBool('notif_match_reminders') ?? true;
      _newMatches = prefs.getBool('notif_new_matches') ?? true;
      _standings = prefs.getBool('notif_standings') ?? false;
      _teamUpdates = prefs.getBool('notif_team_updates') ?? true;
      _sounds = prefs.getBool('notif_sounds') ?? true;
      _vibration = prefs.getBool('notif_vibration') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryGradientStart,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Match Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildNotificationToggle(
            title: 'Match Updates',
            subtitle: 'Get notified when match scores update',
            value: _matchUpdates,
            onChanged: (value) {
              setState(() => _matchUpdates = value);
              _savePreference('notif_match_updates', value);
            },
          ),

          _buildNotificationToggle(
            title: 'Match Reminders',
            subtitle: 'Remind before matches start',
            value: _matchReminders,
            onChanged: (value) {
              setState(() => _matchReminders = value);
              _savePreference('notif_match_reminders', value);
            },
          ),

          _buildNotificationToggle(
            title: 'New Matches',
            subtitle: 'Get notified when new matches are scheduled',
            value: _newMatches,
            onChanged: (value) {
              setState(() => _newMatches = value);
              _savePreference('notif_new_matches', value);
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'Event Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildNotificationToggle(
            title: 'Standings Updates',
            subtitle: 'Get notified when standings change',
            value: _standings,
            onChanged: (value) {
              setState(() => _standings = value);
              _savePreference('notif_standings', value);
            },
          ),

          _buildNotificationToggle(
            title: 'Team Updates',
            subtitle: 'Changes to team rosters or details',
            value: _teamUpdates,
            onChanged: (value) {
              setState(() => _teamUpdates = value);
              _savePreference('notif_team_updates', value);
            },
          ),

          const SizedBox(height: 24),

          const Text(
            'Sound & Vibration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildNotificationToggle(
            title: 'Sounds',
            subtitle: 'Play notification sounds',
            value: _sounds,
            onChanged: (value) {
              setState(() => _sounds = value);
              _savePreference('notif_sounds', value);
            },
          ),

          _buildNotificationToggle(
            title: 'Vibration',
            subtitle: 'Vibrate on notifications',
            value: _vibration,
            onChanged: (value) {
              setState(() => _vibration = value);
              _savePreference('notif_vibration', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.successColor,
          ),
        ],
      ),
    );
  }
}
