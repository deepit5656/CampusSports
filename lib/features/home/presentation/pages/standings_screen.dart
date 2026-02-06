import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/standing_model.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/services/standings_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({super.key});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StandingsService _standingsService = StandingsService();
  String? _selectedSportId;
  String _selectedCategory = 'Boys';
  bool _isCalculating = false;

  final List<String> _categories = ['Boys', 'Girls', 'Faculty'];

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;

    return Scaffold(
      body: Container(
        decoration: AppTheme.getBackgroundDecoration(context),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Standings',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    if (isAdmin && _selectedSportId != null) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isCalculating ? null : _calculateStandings,
                        icon: _isCalculating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(
                            _isCalculating ? 'Calculating...' : 'Recalculate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Sport Selector
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('sports').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }

                        // Parse sports and deduplicate by ID
                        final sportsMap = <String, SportModel>{};
                        for (var doc in snapshot.data!.docs) {
                          try {
                            final sport = SportModel.fromSnapshot(doc);
                            // Use document ID to ensure uniqueness
                            if (!sportsMap.containsKey(doc.id)) {
                              sportsMap[doc.id] = sport;
                            }
                          } catch (e) {
                            print('Error parsing sport ${doc.id}: $e');
                          }
                        }

                        final sports = sportsMap.values.toList();

                        if (sports.isEmpty) {
                          return const Text(
                            'No sports available',
                            style: TextStyle(color: Colors.white70),
                          );
                        }

                        // Get unique sport IDs from the map keys
                        final sportIds = sportsMap.keys.toList();

                        // Ensure selected sport exists in the list
                        if (_selectedSportId == null ||
                            !sportIds.contains(_selectedSportId)) {
                          SchedulerBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _selectedSportId =
                                    sportIds.isNotEmpty ? sportIds.first : null;
                              });
                            }
                          });
                          _selectedSportId =
                              sportIds.isNotEmpty ? sportIds.first : null;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedSportId,
                            isExpanded: true,
                            dropdownColor: AppTheme.getCardColor(context),
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.white),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white,
                                    ),
                            items: sports.map((sport) {
                              return DropdownMenuItem(
                                value: sport.id,
                                child: Text(sport.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSportId = value;
                              });
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Category Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        dropdownColor: AppTheme.cardDark,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                            ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text('$category Category'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 16),

              // Standings Table
              Expanded(
                child: _selectedSportId == null
                    ? const Center(
                        child: Text('Select a sport to view standings'),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('standings')
                              .where('sportId', isEqualTo: _selectedSportId)
                              .where('category', isEqualTo: _selectedCategory)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            var standings = snapshot.data!.docs
                                .map((doc) => StandingModel.fromSnapshot(doc))
                                .toList();

                            // Sort by points, then goal difference
                            standings.sort((a, b) {
                              if (a.points != b.points) {
                                return b.points.compareTo(a.points);
                              }
                              return b.goalDifference
                                  .compareTo(a.goalDifference);
                            });

                            if (standings.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.emoji_events_outlined,
                                      size: 64,
                                      color: AppTheme.textSecondary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No standings available',
                                      style:
                                          Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // Table Header
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardDark,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 40),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            'Team',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                        _buildHeaderCell(context, 'P'),
                                        _buildHeaderCell(context, 'W'),
                                        _buildHeaderCell(context, 'L'),
                                        _buildHeaderCell(context, 'Pts'),
                                      ],
                                    ),
                                  ),

                                  // Table Rows
                                  ...standings.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final standing = entry.value;
                                    final isTopFour = index < 4;

                                    return FutureBuilder<TeamModel?>(
                                      future: _getTeam(standing.teamId),
                                      builder: (context, teamSnapshot) {
                                        final team = teamSnapshot.data;
                                        final teamName =
                                            team?.name ?? 'Loading...';

                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: isTopFour
                                                ? AppTheme.primaryGradientStart
                                                    .withOpacity(0.1)
                                                : AppTheme.cardDark,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: AppTheme.backgroundDark,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              // Position
                                              SizedBox(
                                                width: 40,
                                                child: Text(
                                                  '${index + 1}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isTopFour
                                                            ? AppTheme
                                                                .primaryGradientStart
                                                            : null,
                                                      ),
                                                ),
                                              ),

                                              // Team
                                              Expanded(
                                                flex: 3,
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: AppTheme
                                                            .surfaceDark,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          teamName.isNotEmpty
                                                              ? teamName
                                                                  .substring(
                                                                      0, 1)
                                                                  .toUpperCase()
                                                              : '?',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        teamName,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              _buildDataCell(
                                                  context, standing.played),
                                              _buildDataCell(
                                                  context, standing.won),
                                              _buildDataCell(
                                                  context, standing.lost),
                                              _buildDataCell(
                                                context,
                                                standing.points,
                                                isHighlight: true,
                                              ),
                                            ],
                                          ),
                                        )
                                            .animate(
                                                delay: (200 + (index * 50)).ms)
                                            .fadeIn()
                                            .slideX(begin: -0.2, end: 0);
                                      },
                                    );
                                  }).toList(),

                                  // Table Footer
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.cardDark,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGradientStart
                                                .withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Top 4 teams qualify',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _calculateStandings() async {
    if (_selectedSportId == null) return;

    setState(() => _isCalculating = true);

    try {
      await _standingsService.updateStandingsForSport(_selectedSportId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Standings recalculated successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCalculating = false);
      }
    }
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    return SizedBox(
      width: 40,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(BuildContext context, int value,
      {bool isHighlight = false}) {
    return SizedBox(
      width: 40,
      child: Text(
        value.toString(),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight ? AppTheme.primaryGradientStart : null,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<TeamModel?> _getTeam(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (doc.exists) {
        return TeamModel.fromSnapshot(doc);
      }
    } catch (e) {
      print('Error fetching team: $e');
    }
    return null;
  }
}
