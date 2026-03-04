import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/institute_model.dart';
import '../../../../core/utils/validators.dart';

class ManageInstitutesScreen extends StatefulWidget {
  const ManageInstitutesScreen({super.key});

  @override
  State<ManageInstitutesScreen> createState() => _ManageInstitutesScreenState();
}

class _ManageInstitutesScreenState extends State<ManageInstitutesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Color options for institutes
  static const List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Blue', 'hex': '#2196F3'},
    {'name': 'Red', 'hex': '#F44336'},
    {'name': 'Green', 'hex': '#4CAF50'},
    {'name': 'Orange', 'hex': '#FF9800'},
    {'name': 'Purple', 'hex': '#9C27B0'},
    {'name': 'Teal', 'hex': '#009688'},
    {'name': 'Indigo', 'hex': '#3F51B5'},
    {'name': 'Pink', 'hex': '#E91E63'},
    {'name': 'Amber', 'hex': '#FFC107'},
    {'name': 'Cyan', 'hex': '#00BCD4'},
    {'name': 'Deep Orange', 'hex': '#FF5722'},
    {'name': 'Light Green', 'hex': '#8BC34A'},
  ];

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
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
                        'Manage Institutes',
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

              // Institute List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('institutes')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final institutes = snapshot.data!.docs
                        .map((doc) => InstituteModel.fromSnapshot(doc))
                        .toList();

                    if (institutes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 80,
                              color: AppTheme.textSecondary.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Institutes Added',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to add your first institute',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary.withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: institutes.length,
                      itemBuilder: (context, index) {
                        return _buildInstituteCard(institutes[index], index)
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 100 * index))
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryGradientStart,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildInstituteCard(InstituteModel institute, int index) {
    final color = institute.color != null
        ? _hexToColor(institute.color!)
        : AppTheme.primaryGradientStart;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              institute.shortName,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          '${institute.shortName} - ${institute.name}',
          style: const TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: FutureBuilder<QuerySnapshot>(
          future: _firestore
              .collection('teams')
              .where('instituteId', isEqualTo: institute.id)
              .get(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            return Text(
              '$count teams registered',
              style: const TextStyle(color: AppTheme.textSecondary),
            );
          },
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          color: AppTheme.cardDark,
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(institute: institute);
            } else if (value == 'delete') {
              _showDeleteDialog(institute);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppTheme.textColor, size: 20),
                  SizedBox(width: 8),
                  Text('Edit', style: TextStyle(color: AppTheme.textColor)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppTheme.errorColor, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog({InstituteModel? institute}) {
    final isEditing = institute != null;
    final nameController = TextEditingController(text: institute?.name ?? '');
    final shortNameController =
        TextEditingController(text: institute?.shortName ?? '');
    String selectedColor = institute?.color ?? _colorOptions.first['hex'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEditing ? 'Edit Institute' : 'Add Institute',
            style: const TextStyle(color: AppTheme.textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: const InputDecoration(
                    labelText: 'Institute Name',
                    hintText: 'e.g., CSPIT, DEPSTAR',
                    prefixIcon: Icon(Icons.school),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: shortNameController,
                  style: const TextStyle(color: AppTheme.textColor),
                  decoration: const InputDecoration(
                    labelText: 'Department Short Name',
                    hintText: 'e.g., IT, CSE, ME',
                    prefixIcon: Icon(Icons.abc),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Institute Color',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorOptions.map((opt) {
                    final isSelected = opt['hex'] == selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = opt['hex']);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hexToColor(opt['hex']),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _hexToColor(opt['hex'])
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final shortName = shortNameController.text.trim();

                if (name.isEmpty || shortName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all required fields'),
                    ),
                  );
                  return;
                }

                try {
                  if (isEditing) {
                    await _firestore
                        .collection('institutes')
                        .doc(institute.id)
                        .update({
                      'name': name,
                      'shortName': shortName,
                      'color': selectedColor,
                    });
                  } else {
                    final docRef = _firestore.collection('institutes').doc();
                    final newInstitute = InstituteModel(
                      id: docRef.id,
                      name: name,
                      shortName: shortName,
                      color: selectedColor,
                      createdAt: DateTime.now(),
                    );
                    await docRef.set(newInstitute.toMap());
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? 'Institute updated!'
                          : 'Institute added!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGradientStart,
              ),
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(InstituteModel institute) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Institute',
          style: TextStyle(color: AppTheme.textColor),
        ),
        content: Text(
          'Are you sure you want to delete "${institute.name}"?\n\nTeams belonging to this institute will not be deleted but will lose their institute association.',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Remove instituteId from teams belonging to this institute
                final teamsSnapshot = await _firestore
                    .collection('teams')
                    .where('instituteId', isEqualTo: institute.id)
                    .get();

                final batch = _firestore.batch();
                for (final doc in teamsSnapshot.docs) {
                  batch.update(doc.reference, {'instituteId': FieldValue.delete()});
                }

                // Delete the institute
                batch.delete(
                    _firestore.collection('institutes').doc(institute.id));
                await batch.commit();

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Institute deleted'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
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
