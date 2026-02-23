import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/app_theme.dart';

/// Central admin configuration screen for managing sport-specific settings
/// This allows admins to configure:
/// - Points needed to win (sets, frames, rounds, etc.)
/// - Number of sets/matches/rounds
/// - Other sport-specific parameters
class SportConfigAdminScreen extends StatefulWidget {
  final String matchId;
  final String sportId;
  final String sportName;
  final Map<String, dynamic> currentConfig;
  final Function(Map<String, dynamic>) onConfigUpdated;

  const SportConfigAdminScreen({
    Key? key,
    required this.matchId,
    required this.sportId,
    required this.sportName,
    required this.currentConfig,
    required this.onConfigUpdated,
  }) : super(key: key);

  @override
  State<SportConfigAdminScreen> createState() => _SportConfigAdminScreenState();
}

class _SportConfigAdminScreenState extends State<SportConfigAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, dynamic> _config;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _config = Map.from(widget.currentConfig);
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isLoading = true);
    try {
      // Save to Firestore
      await _firestore.collection('matches').doc(widget.matchId).update({
        '${widget.sportName.toLowerCase()}MatchData': _config,
      });

      widget.onConfigUpdated(_config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration updated successfully!'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildConfigField(
    String label,
    String key,
    String description, {
    int? minValue,
    int? maxValue,
  }) {
    final currentValue = _config[key] ?? 0;
    final TextEditingController controller = TextEditingController(
      text: currentValue.toString(),
    );

    return Card(
      color: AppTheme.getCardColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) return;
                      final intValue = int.tryParse(value) ?? currentValue;
                      final validValue = intValue;
                      
                      if (minValue != null && validValue < minValue) return;
                      if (maxValue != null && validValue > maxValue) return;
                      
                      setState(() {
                        _config[key] = validValue;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                      onPressed: () {
                        int newValue = (int.tryParse(controller.text) ?? currentValue) + 1;
                        if (maxValue != null && newValue > maxValue) return;
                        setState(() {
                          _config[key] = newValue;
                          controller.text = newValue.toString();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove, color: AppTheme.primaryColor),
                      onPressed: () {
                        int newValue = (int.tryParse(controller.text) ?? currentValue) - 1;
                        if (minValue != null && newValue < minValue) return;
                        setState(() {
                          _config[key] = newValue;
                          controller.text = newValue.toString();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigForSport() {
    switch (widget.sportName.toLowerCase()) {
      case 'badminton':
        return Column(
          children: [
            _buildConfigField(
              'Points to Win Set',
              'pointsToWinSet',
              'Points needed to win a badminton set (default: 21, can go to 30)',
              minValue: 15,
              maxValue: 30,
            ),
            const SizedBox(height: 16),
            _buildConfigField(
              'Sets to Win Match',
              'setsToWinMatch',
              'Number of sets to win the match (default: 2 for best-of-3)',
              minValue: 1,
              maxValue: 5,
            ),
          ],
        );
      
      case 'tennis':
        return Column(
          children: [
            _buildConfigField(
              'Games per Set',
              'gamesPerSet',
              'Games needed to win a tennis set (default: 6)',
              minValue: 4,
              maxValue: 10,
            ),
            const SizedBox(height: 16),
            _buildConfigField(
              'Tiebreak Points',
              'tiebreakPoints',
              'Points needed to win a tiebreak (default: 7)',
              minValue: 5,
              maxValue: 10,
            ),
            const SizedBox(height: 16),
            _buildConfigField(
              'Sets to Win Match',
              'setsToWinMatch',
              'Sets needed to win the match (default: 2 for best-of-3)',
              minValue: 1,
              maxValue: 5,
            ),
          ],
        );
      
      case 'volleyball':
        return Column(
          children: [
            _buildConfigField(
              'Points per Set',
              'pointsPerSet',
              'Points needed to win a regular set (default: 25)',
              minValue: 15,
              maxValue: 50,
            ),
            const SizedBox(height: 16),
            _buildConfigField(
              'Points for Final Set',
              'pointsForFinalSet',
              'Points needed for the final/5th set (default: 15)',
              minValue: 10,
              maxValue: 30,
            ),
            const SizedBox(height: 16),
            _buildConfigField(
              'Sets to Win Match',
              'setsToWinMatch',
              'Sets needed to win the match (default: 3 for best-of-5)',
              minValue: 1,
              maxValue: 5,
            ),
          ],
        );
      
      case 'table tennis':
        return Column(
          children: [
            _buildConfigField(
              'Points per Set',
              'pointsPerSet',
              'Points needed to win a table tennis set (default: 11)',
              minValue: 7,
              maxValue: 21,
            ),
            const SizedBox(height: 16),
            _buildConfigField(
              'Sets to Win Match',
              'setsToWinMatch',
              'Sets needed to win the match (default: 3 for best-of-5)',
              minValue: 1,
              maxValue: 5,
            ),
          ],
        );
      
      case 'frisbee':
        return Column(
          children: [
            _buildConfigField(
              'Points to Win',
              'pointsToWinMatch',
              'Points needed to win the ultimate frisbee match (default: 15)',
              minValue: 10,
              maxValue: 25,
            ),
          ],
        );
      
      default:
        return Center(
          child: Text(
            'No configurable parameters for ${widget.sportName}',
            style: const TextStyle(color: Colors.white),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text('${widget.sportName} Settings'),
        backgroundColor: AppTheme.primaryGradientStart,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adjust sport-specific settings for this match. Changes are saved in real-time.',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildConfigForSport(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveConfiguration,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
