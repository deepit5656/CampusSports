import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/scoring_config_model.dart';
import '../../../../core/utils/validators.dart';
import 'sport_configuration_screen.dart';

class ManageSportsScreen extends StatefulWidget {
  const ManageSportsScreen({super.key});

  @override
  State<ManageSportsScreen> createState() => _ManageSportsScreenState();
}

class _ManageSportsScreenState extends State<ManageSportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
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
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Manage Sports',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Sports List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('sports').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sports = snapshot.data!.docs
                        .map((doc) => SportModel.fromSnapshot(doc))
                        .toList();

                    if (sports.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No sports added yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add your first sport',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sports.length,
                      itemBuilder: (context, index) {
                        final sport = sports[index];
                        return _buildSportCard(sport, index)
                            .animate(delay: (100 * index).ms)
                            .fadeIn()
                            .slideX(begin: -0.2, end: 0);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToSportConfiguration(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Sport'),
        backgroundColor: AppTheme.primaryGradientStart,
      ).animate().scale(delay: 200.ms),
    );
  }

  Widget _buildSportCard(SportModel sport, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sports, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sport.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  sport.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryGradientStart),
            onPressed: () => _navigateToSportConfiguration(context, sport: sport),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.errorColor),
            onPressed: () => _showDeleteDialog(context, sport),
          ),
        ],
      ),
    );
  }

  void _navigateToSportConfiguration(BuildContext context, {SportModel? sport}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SportConfigurationScreen(sport: sport),
      ),
    );
    
    if (result is SportModel) {
      // Sport was created/updated, refresh the list
      setState(() {});
    }
  }

  void _showAddEditDialog(BuildContext context, {SportModel? sport}) {
    final nameController = TextEditingController(text: sport?.name ?? '');
    final descriptionController = TextEditingController(text: sport?.description ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(sport == null ? 'Add Sport' : 'Edit Sport'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Sport Name',
                    prefixIcon: Icon(Icons.sports),
                  ),
                  validator: (value) => Validators.validateRequired(value, 'Sport name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) => Validators.validateRequired(value, 'Description'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isLoading = true);

                        try {
                          if (sport == null) {
                            // Add new sport
                            final docRef = _firestore.collection('sports').doc();
                            final newSport = SportModel(
                              id: docRef.id,
                              name: nameController.text.trim(),
                              icon: 'sports',
                              description: descriptionController.text.trim(),
                              scoringConfig: ScoringConfig.basic(),
                              createdAt: DateTime.now(),
                            );
                            await docRef.set(newSport.toMap());
                          } else {
                            // Update existing sport
                            await _firestore.collection('sports').doc(sport.id).update({
                              'name': nameController.text.trim(),
                              'description': descriptionController.text.trim(),
                            });
                          }

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                sport == null
                                    ? 'Sport added successfully!'
                                    : 'Sport updated successfully!',
                              ),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(sport == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SportModel sport) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Sport'),
        content: Text('Are you sure you want to delete ${sport.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('sports').doc(sport.id).delete();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sport deleted successfully!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
