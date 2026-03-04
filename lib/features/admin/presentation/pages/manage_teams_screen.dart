import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/models/institute_model.dart';
import '../../../../core/utils/validators.dart';

class ManageTeamsScreen extends StatefulWidget {
  final String? sportId; // Optional sportId filter
  final String? sportName; // Optional sport name for display
  
  const ManageTeamsScreen({
    super.key,
    this.sportId,
    this.sportName,
  });

  @override
  State<ManageTeamsScreen> createState() => _ManageTeamsScreenState();
}

class _ManageTeamsScreenState extends State<ManageTeamsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, InstituteModel> _institutesMap = {};

  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }

  Future<void> _loadInstitutes() async {
    final snapshot = await _firestore.collection('institutes').get();
    setState(() {
      _institutesMap = {
        for (final doc in snapshot.docs)
          doc.id: InstituteModel.fromMap(doc.data()),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.getBackgroundDecoration(context),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
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
                        widget.sportName != null 
                            ? '${widget.sportName} Teams' 
                            : 'Manage Teams',
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

              // Teams List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: widget.sportId != null
                      ? _firestore
                          .collection('teams')
                          .where('sportId', isEqualTo: widget.sportId)
                          .snapshots()
                      : _firestore.collection('teams').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final teams = snapshot.data!.docs
                        .map((doc) => TeamModel.fromSnapshot(doc))
                        .toList();

                    if (teams.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No teams added yet',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add your first team',
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
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index];
                        return _buildTeamCard(team, index)
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
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Team'),
        backgroundColor: AppTheme.accentGradientStart,
      ).animate().scale(delay: 200.ms),
    );
  }

  Widget _buildTeamCard(TeamModel team, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                team.name.substring(0, 1).toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  team.department,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                if (team.instituteId != null &&
                    _institutesMap.containsKey(team.instituteId)) ...[                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.account_balance,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _institutesMap[team.instituteId]!.shortName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.accentGradientStart,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.accentGradientStart),
            onPressed: () => _showAddEditDialog(context, team: team),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppTheme.errorColor),
            onPressed: () => _showDeleteDialog(context, team),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {TeamModel? team}) async {
    final nameController = TextEditingController(text: team?.name ?? '');
    final departmentController = TextEditingController(text: team?.department ?? '');
    String? selectedInstituteId = team?.instituteId;
    
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    // Load institutes
    final institutesSnapshot = await _firestore
        .collection('institutes')
        .orderBy('name')
        .get();
    final institutes = institutesSnapshot.docs
        .map((doc) => InstituteModel.fromMap(doc.data()))
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.getCardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(team == null ? 'Add Team' : 'Edit Team'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Team Name',
                      prefixIcon: Icon(Icons.groups),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Team name'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.school),
                    ),
                    validator: (value) => Validators.validateRequired(value, 'Department'),
                  ),
                  const SizedBox(height: 16),
                  if (institutes.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      value: selectedInstituteId,
                      decoration: const InputDecoration(
                        labelText: 'Institute (Optional)',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Institute'),
                        ),
                        ...institutes.map((inst) => DropdownMenuItem<String?>(
                              value: inst.id,
                              child: Text('${inst.shortName} - ${inst.name}'),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => selectedInstituteId = value);
                      },
                    ),
                  ],
                ],
              ),
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
                          if (team == null) {
                            // Add new team
                            final docRef = _firestore.collection('teams').doc();
                            final newTeam = TeamModel(
                              id: docRef.id,
                              name: nameController.text.trim(),
                              department: departmentController.text.trim(),
                              logo: '',
                              sportId: null,
                              instituteId: selectedInstituteId,
                              createdAt: DateTime.now(),
                            );
                            await docRef.set(newTeam.toMap());
                          } else {
                            // Update existing team
                            await _firestore.collection('teams').doc(team.id).update({
                              'name': nameController.text.trim(),
                              'department': departmentController.text.trim(),
                              'instituteId': selectedInstituteId,
                            });
                          }

                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: Text(
                                team == null
                                    ? 'Team added successfully!'
                                    : 'Team updated successfully!',
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
                  : Text(team == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TeamModel team) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete ${team.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('teams').doc(team.id).delete();
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Team deleted successfully!'),
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
