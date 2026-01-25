import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/match_model.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/team_score_model.dart';
import '../../../../core/models/scoring_config_model.dart';
import '../../../../core/theme/app_theme.dart';

class UpdateMatchScoreScreen extends StatefulWidget {
  final MatchModel match;
  final SportModel sport;
  final TeamModel team1;
  final TeamModel team2;

  const UpdateMatchScoreScreen({
    super.key,
    required this.match,
    required this.sport,
    required this.team1,
    required this.team2,
  });

  @override
  State<UpdateMatchScoreScreen> createState() => _UpdateMatchScoreScreenState();
}

class _UpdateMatchScoreScreenState extends State<UpdateMatchScoreScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late Map<String, Map<String, TextEditingController>> _scoreControllers;
  String? _selectedWinnerId;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingScores();
  }

  void _initializeControllers() {
    _scoreControllers = {};
    
    // Initialize controllers for both teams
    for (final teamId in [widget.team1.id, widget.team2.id]) {
      _scoreControllers[teamId] = {};
      
      // Create a controller for each score field
      for (final field in widget.sport.allFieldsSorted) {
        _scoreControllers[teamId]![field.id] = TextEditingController();
      }
    }
  }

  void _loadExistingScores() {
    if (widget.match.hasDetailedScore) {
      // Load from detailed scores
      widget.match.detailedScore!.forEach((teamId, teamScore) {
        teamScore.scores.forEach((fieldId, value) {
          if (_scoreControllers[teamId]?[fieldId] != null) {
            _scoreControllers[teamId]![fieldId]!.text = value.toString();
          }
        });
        
        if (teamScore.isWinner) {
          _selectedWinnerId = teamId;
        }
      });
    } else if (widget.match.score != null) {
      // Load from legacy scores (map to primary field)
      final primaryField = widget.sport.primaryScoreField;
      
      widget.match.score!.forEach((teamId, score) {
        if (_scoreControllers[teamId]?[primaryField.id] != null) {
          _scoreControllers[teamId]![primaryField.id]!.text = score.toString();
        }
      });
      
      if (widget.match.winnerId != null) {
        _selectedWinnerId = widget.match.winnerId;
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _scoreControllers.values.forEach((teamControllers) {
      teamControllers.values.forEach((controller) => controller.dispose());
    });
    super.dispose();
  }

  void _saveScore() {
    if (_formKey.currentState!.validate()) {
      // Build detailed score map
      final Map<String, TeamScore> detailedScore = {};
      
      for (final teamId in [widget.team1.id, widget.team2.id]) {
        final Map<String, dynamic> scores = {};
        
        // Collect scores from controllers
        _scoreControllers[teamId]!.forEach((fieldId, controller) {
          if (controller.text.isNotEmpty) {
            final field = widget.sport.allFieldsSorted.firstWhere((f) => f.id == fieldId);
            
            // Parse based on field type
            switch (field.type) {
              case 'number':
                scores[fieldId] = int.tryParse(controller.text) ?? 0;
                break;
              case 'percentage':
                scores[fieldId] = double.tryParse(controller.text) ?? 0.0;
                break;
              default:
                scores[fieldId] = controller.text;
            }
          }
        });
        
        detailedScore[teamId] = TeamScore(
          teamId: teamId,
          scores: scores,
          isWinner: _selectedWinnerId == teamId,
        );
      }
      
      // Auto-determine winner if not manually set
      if (_selectedWinnerId == null) {
        _selectedWinnerId = _autoDetectWinner(detailedScore);
      }
      
      // Update match with new scores
      final updatedMatch = widget.match.copyWith(
        detailedScore: detailedScore,
        winnerId: _selectedWinnerId,
        status: 'completed', // Mark as completed when scores are updated
      );
      
      // TODO: Implement BLoC event to update match
      // context.read<MatchBloc>().add(UpdateMatchScoreEvent(updatedMatch));
      
      Navigator.pop(context, updatedMatch);
    }
  }

  String? _autoDetectWinner(Map<String, TeamScore> detailedScore) {
    final primaryField = widget.sport.primaryScoreField;
    final winCondition = widget.sport.scoringConfig.winCondition ?? 'highest';
    
    final team1Score = detailedScore[widget.team1.id]?.getPrimaryScore(primaryField.id) ?? 0;
    final team2Score = detailedScore[widget.team2.id]?.getPrimaryScore(primaryField.id) ?? 0;
    
    switch (winCondition) {
      case 'highest':
        if (team1Score > team2Score) return widget.team1.id;
        if (team2Score > team1Score) return widget.team2.id;
        break;
      case 'lowest':
        if (team1Score < team2Score) return widget.team1.id;
        if (team2Score < team1Score) return widget.team2.id;
        break;
      case 'best_of':
        // For best_of, the primary field should already represent games/sets won
        if (team1Score > team2Score) return widget.team1.id;
        if (team2Score > team1Score) return widget.team2.id;
        break;
    }
    
    return null; // Draw/tie
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: Text(
          'Update ${widget.sport.name} Score',
          style: const TextStyle(color: AppTheme.textColor),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textColor),
        actions: [
          TextButton(
            onPressed: _saveScore,
            child: const Text(
              'SAVE',
              style: TextStyle(color: AppTheme.primaryGradientStart),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Match Info Header
              _buildMatchInfoHeader(),
              const SizedBox(height: 24),
              
              // Team 1 Score Input
              _buildTeamScoreSection(widget.team1, widget.team1.id),
              const SizedBox(height: 20),
              
              // Team 2 Score Input
              _buildTeamScoreSection(widget.team2, widget.team2.id),
              const SizedBox(height: 24),
              
              // Winner Selection
              _buildWinnerSection(),
              const SizedBox(height: 24),
              
              // Score Preview
              _buildScorePreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                widget.sport.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.sport.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.match.venue} • ${widget.match.category ?? 'All'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.team1.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.team2.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScoreSection(TeamModel team, String teamId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: _selectedWinnerId == teamId
            ? Border.all(color: AppTheme.successColor, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  team.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedWinnerId == teamId 
                        ? AppTheme.successColor 
                        : AppTheme.textColor,
                  ),
                ),
              ),
              if (_selectedWinnerId == teamId)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'WINNER',
                    style: TextStyle(
                      color: AppTheme.successColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            team.department,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          
          // Score input fields
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: widget.sport.allFieldsSorted.length,
            itemBuilder: (context, index) {
              final field = widget.sport.allFieldsSorted[index];
              return _buildScoreInputField(field, teamId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInputField(ScoreField field, String teamId) {
    final controller = _scoreControllers[teamId]![field.id]!;
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: field.name,
        hintText: field.unit != null ? 'Enter ${field.unit}' : 'Enter value',
        suffixText: field.unit,
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(
          color: field.isPrimary ? AppTheme.primaryGradientStart : AppTheme.textSecondary,
          fontWeight: field.isPrimary ? FontWeight.bold : FontWeight.normal,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      style: const TextStyle(color: AppTheme.textColor),
      keyboardType: field.type == 'percentage' 
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: field.type == 'number' 
          ? [FilteringTextInputFormatter.digitsOnly]
          : field.type == 'percentage'
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))]
              : [],
      validator: (value) {
        if (field.isPrimary && (value == null || value.isEmpty)) {
          return 'Required';
        }
        
        if (value != null && value.isNotEmpty) {
          final numValue = double.tryParse(value);
          if (numValue == null) {
            return 'Invalid number';
          }
          
          if (field.minValue != null && numValue < field.minValue!) {
            return 'Min: ${field.minValue}';
          }
          
          if (field.maxValue != null && numValue > field.maxValue!) {
            return 'Max: ${field.maxValue}';
          }
        }
        
        return null;
      },
    );
  }

  Widget _buildWinnerSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Result',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    widget.team1.name,
                    style: const TextStyle(color: AppTheme.textColor),
                  ),
                  value: widget.team1.id,
                  groupValue: _selectedWinnerId,
                  onChanged: (value) {
                    setState(() {
                      _selectedWinnerId = value;
                    });
                  },
                  activeColor: AppTheme.successColor,
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: Text(
                    widget.team2.name,
                    style: const TextStyle(color: AppTheme.textColor),
                  ),
                  value: widget.team2.id,
                  groupValue: _selectedWinnerId,
                  onChanged: (value) {
                    setState(() {
                      _selectedWinnerId = value;
                    });
                  },
                  activeColor: AppTheme.successColor,
                ),
              ),
            ],
          ),
          
          Row(
            children: [
              Expanded(
                child: RadioListTile<String?>(
                  title: const Text(
                    'Draw/Tie',
                    style: TextStyle(color: AppTheme.textColor),
                  ),
                  value: null,
                  groupValue: _selectedWinnerId,
                  onChanged: (value) {
                    setState(() {
                      _selectedWinnerId = null;
                    });
                  },
                  activeColor: AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScorePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // Preview how scores will appear
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTeamScorePreview(widget.team1, widget.team1.id),
              Text(
                widget.sport.icon,
                style: const TextStyle(fontSize: 20),
              ),
              _buildTeamScorePreview(widget.team2, widget.team2.id),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamScorePreview(TeamModel team, String teamId) {
    final cardDisplayFields = widget.sport.cardDisplayFields;
    final scoreText = cardDisplayFields.map((field) {
      final controller = _scoreControllers[teamId]![field.id]!;
      return controller.text.isEmpty ? '0' : controller.text;
    }).join('/');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          team.name,
          style: TextStyle(
            color: _selectedWinnerId == teamId ? AppTheme.successColor : AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          scoreText,
          style: TextStyle(
            color: _selectedWinnerId == teamId ? AppTheme.successColor : AppTheme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}