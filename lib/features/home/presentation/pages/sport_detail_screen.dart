import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/match_model.dart';
import '../widgets/match_card.dart';

class SportDetailScreen extends StatefulWidget {
  final SportModel sport;

  const SportDetailScreen({super.key, required this.sport});

  @override
  State<SportDetailScreen> createState() => _SportDetailScreenState();
}

class _SportDetailScreenState extends State<SportDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                pinned: true,
                expandedHeight: 150,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            Icons.sports,
                            size: 50,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.sport.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Upcoming', 'upcoming'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Live', 'live'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Completed', 'completed'),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),
              ),

              // Matches List
              StreamBuilder<QuerySnapshot>(
                stream: _getMatchesStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('Error: ${snapshot.error}'),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  var matches = snapshot.data!.docs
                      .map((doc) => MatchModel.fromSnapshot(doc))
                      .toList();

                  // Apply filter
                  if (_selectedFilter != 'all') {
                    matches = matches
                        .where((match) => match.status == _selectedFilter)
                        .toList();
                  }

                  if (matches.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 64,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No matches found',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            bottom: 12.0,
                          ),
                          child: MatchCard(
                            match: matches[index],
                            sport: widget.sport,
                          )
                              .animate(delay: (200 + (index * 50)).ms)
                              .fadeIn()
                              .slideX(begin: -0.2, end: 0),
                        );
                      },
                      childCount: matches.length,
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGradientStart.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _getMatchesStream() {
    return _firestore
        .collection('matches')
        .where('sportId', isEqualTo: widget.sport.id)
        .orderBy('dateTime', descending: true)
        .snapshots();
  }
}
