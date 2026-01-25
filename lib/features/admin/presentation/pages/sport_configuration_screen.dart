import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/scoring_config_model.dart';
import '../../../../core/models/sport_templates.dart';
import '../../../../core/theme/app_theme.dart';

class SportConfigurationScreen extends StatefulWidget {
  final SportModel? sport; // Null for create, populated for edit

  const SportConfigurationScreen({
    super.key,
    this.sport,
  });

  @override
  State<SportConfigurationScreen> createState() => _SportConfigurationScreenState();
}

class _SportConfigurationScreenState extends State<SportConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final _descriptionController = TextEditingController();

  late ScoringConfig _currentScoringConfig;
  String? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    if (widget.sport != null) {
      // Edit mode
      _nameController.text = widget.sport!.name;
      _iconController.text = widget.sport!.icon;
      _descriptionController.text = widget.sport!.description;
      _currentScoringConfig = widget.sport!.scoringConfig;
    } else {
      // Create mode - start with default template
      _currentScoringConfig = SportTemplate.getDefaultTemplate();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyTemplate(String templateName) {
    setState(() {
      _selectedTemplate = templateName;
      if (templateName != 'Custom') {
        _currentScoringConfig = SportTemplate.getAllTemplates()[templateName]!;
      }
    });
  }

  void _addScoreField() {
    final newField = ScoreField(
      id: 'field_${DateTime.now().millisecondsSinceEpoch}',
      name: 'New Field',
      type: 'number',
      isPrimary: _currentScoringConfig.scoreFields.isEmpty,
      showInCard: true,
      displayOrder: _currentScoringConfig.scoreFields.length + 1,
    );

    setState(() {
      _currentScoringConfig = _currentScoringConfig.copyWith(
        scoreFields: [..._currentScoringConfig.scoreFields, newField],
      );
    });
  }

  void _removeScoreField(int index) {
    setState(() {
      final updatedFields = List<ScoreField>.from(_currentScoringConfig.scoreFields);
      updatedFields.removeAt(index);
      _currentScoringConfig = _currentScoringConfig.copyWith(
        scoreFields: updatedFields,
      );
    });
  }

  void _updateScoreField(int index, ScoreField updatedField) {
    setState(() {
      final updatedFields = List<ScoreField>.from(_currentScoringConfig.scoreFields);
      updatedFields[index] = updatedField;
      _currentScoringConfig = _currentScoringConfig.copyWith(
        scoreFields: updatedFields,
      );
    });
  }

  void _moveFieldUp(int index) {
    if (index > 0) {
      setState(() {
        final fields = List<ScoreField>.from(_currentScoringConfig.scoreFields);
        final field = fields.removeAt(index);
        fields.insert(index - 1, field);
        
        // Update display orders
        for (int i = 0; i < fields.length; i++) {
          fields[i] = fields[i].copyWith(displayOrder: i + 1);
        }
        
        _currentScoringConfig = _currentScoringConfig.copyWith(scoreFields: fields);
      });
    }
  }

  void _moveFieldDown(int index) {
    if (index < _currentScoringConfig.scoreFields.length - 1) {
      setState(() {
        final fields = List<ScoreField>.from(_currentScoringConfig.scoreFields);
        final field = fields.removeAt(index);
        fields.insert(index + 1, field);
        
        // Update display orders
        for (int i = 0; i < fields.length; i++) {
          fields[i] = fields[i].copyWith(displayOrder: i + 1);
        }
        
        _currentScoringConfig = _currentScoringConfig.copyWith(scoreFields: fields);
      });
    }
  }

  void _saveSport() async {
    if (_formKey.currentState!.validate()) {
      // Validate at least one primary field
      final hasPrimaryField = _currentScoringConfig.scoreFields.any((field) => field.isPrimary);
      if (!hasPrimaryField) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least one field must be marked as primary')),
        );
        return;
      }

      try {
        final sport = SportModel(
          id: widget.sport?.id ?? 'sport_${DateTime.now().millisecondsSinceEpoch}',
          name: _nameController.text,
          icon: _iconController.text,
          description: _descriptionController.text,
          scoringConfig: _currentScoringConfig,
          createdAt: widget.sport?.createdAt ?? DateTime.now(),
        );

        // Save to Firebase
        final firestore = FirebaseFirestore.instance;
        if (widget.sport == null) {
          // Creating new sport
          final docRef = firestore.collection('sports').doc(sport.id);
          await docRef.set(sport.toMap());
        } else {
          // Updating existing sport
          await firestore.collection('sports').doc(sport.id).update(sport.toMap());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sport ${widget.sport == null ? 'created' : 'updated'} successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        Navigator.pop(context, sport);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving sport: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: Text(
          widget.sport != null ? 'Edit Sport' : 'Create Sport',
          style: const TextStyle(color: AppTheme.textColor),
        ),
        iconTheme: const IconThemeData(color: AppTheme.textColor),
        actions: [
          TextButton(
            onPressed: _saveSport,
            child: const Text(
              'SAVE',
              style: TextStyle(color: AppTheme.primaryGradientStart),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    
                    // Template Selection
                    _buildTemplateSection(),
                    const SizedBox(height: 24),
                    
                    // Scoring Configuration
                    _buildScoringConfigSection(),
                  ],
                ),
              ),
            ),
            
            // Preview Card
            _buildPreviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
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
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Sport Name',
              hintText: 'e.g., Cricket, Football',
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: AppTheme.textSecondary),
            ),
            style: const TextStyle(color: AppTheme.textColor),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter sport name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _iconController,
            decoration: const InputDecoration(
              labelText: 'Icon (Emoji)',
              hintText: '🏏, ⚽, 🏀',
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: AppTheme.textSecondary),
            ),
            style: const TextStyle(color: AppTheme.textColor),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an icon';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Brief description of the sport',
              border: OutlineInputBorder(),
              labelStyle: TextStyle(color: AppTheme.textSecondary),
            ),
            style: const TextStyle(color: AppTheme.textColor),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateSection() {
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
            'Choose Template',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a template or create custom scoring fields',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SportTemplate.getTemplateNames().map((template) {
              final isSelected = _selectedTemplate == template;
              return FilterChip(
                label: Text(template),
                selected: isSelected,
                onSelected: (selected) => _applyTemplate(template),
                backgroundColor: AppTheme.surfaceDark,
                selectedColor: AppTheme.primaryGradientStart.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryGradientStart : AppTheme.textColor,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoringConfigSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Configure Scoring System',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addScoreField,
                icon: const Icon(Icons.add),
                label: const Text('Add Field'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGradientStart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Score Fields
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentScoringConfig.scoreFields.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildScoreFieldCard(index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScoreFieldCard(int index) {
    final field = _currentScoringConfig.scoreFields[index];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: field.isPrimary
            ? Border.all(color: AppTheme.primaryGradientStart, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.name,
                  style: TextStyle(
                    color: field.isPrimary ? AppTheme.primaryGradientStart : AppTheme.textColor,
                    fontWeight: field.isPrimary ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (field.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGradientStart.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PRIMARY',
                    style: TextStyle(
                      color: AppTheme.primaryGradientStart,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Move buttons
              IconButton(
                onPressed: index > 0 ? () => _moveFieldUp(index) : null,
                icon: const Icon(Icons.keyboard_arrow_up),
                iconSize: 20,
              ),
              IconButton(
                onPressed: index < _currentScoringConfig.scoreFields.length - 1
                    ? () => _moveFieldDown(index)
                    : null,
                icon: const Icon(Icons.keyboard_arrow_down),
                iconSize: 20,
              ),
              IconButton(
                onPressed: () => _removeScoreField(index),
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
                color: AppTheme.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Field configuration form would go here
          // This is a simplified version - you'd want to expand this
          Text(
            'Type: ${field.type} | Unit: ${field.unit ?? 'none'} | Show in card: ${field.showInCard}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          
          // Match card preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _nameController.text.isEmpty ? 'Sport Name' : _nameController.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      children: [
                        Text('Team A', style: TextStyle(color: Colors.white70)),
                        Text('Sample Score', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    Text(
                      _iconController.text.isEmpty ? '⚽' : _iconController.text,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Column(
                      children: [
                        Text('Team B', style: TextStyle(color: Colors.white70)),
                        Text('Sample Score', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}