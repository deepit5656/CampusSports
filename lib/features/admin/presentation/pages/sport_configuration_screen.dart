import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/sport_config_comprehensive.dart';
import '../../../../core/models/sport_model.dart';
import '../../../../core/models/scoring_config_model.dart';
import '../../../../core/models/sport_templates.dart';
import '../../../../core/theme/app_theme.dart';

class SportConfigurationScreen extends StatefulWidget {
  final SportModel? sport; // For backward compatibility
  final SportConfigModel? sportConfig; // New sport config
  final bool isReadOnly;

  const SportConfigurationScreen({
    super.key,
    this.sport,
    this.sportConfig,
    this.isReadOnly = false,
  });

  @override
  State<SportConfigurationScreen> createState() =>
      _SportConfigurationScreenState();
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
    if (widget.sportConfig != null) {
      // New sport config mode
      _nameController.text = widget.sportConfig!.name;
      _iconController.text = widget.sportConfig!.icon;
      _descriptionController.text = widget.sportConfig!.description;
      _currentScoringConfig = ScoringConfig.basic(); // Simplified for now
    } else if (widget.sport != null) {
      // Edit mode (backward compatibility)
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
      final updatedFields =
          List<ScoreField>.from(_currentScoringConfig.scoreFields);
      updatedFields.removeAt(index);
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

        _currentScoringConfig =
            _currentScoringConfig.copyWith(scoreFields: fields);
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

        _currentScoringConfig =
            _currentScoringConfig.copyWith(scoreFields: fields);
      });
    }
  }

  void _editFieldName(int index) {
    final field = _currentScoringConfig.scoreFields[index];
    final controller = TextEditingController(text: field.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Edit Field Name',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Field Name',
            labelStyle: TextStyle(color: AppTheme.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.textSecondary),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryGradientStart),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  final fields =
                      List<ScoreField>.from(_currentScoringConfig.scoreFields);
                  fields[index] = fields[index].copyWith(name: controller.text);
                  _currentScoringConfig =
                      _currentScoringConfig.copyWith(scoreFields: fields);
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGradientStart,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editFieldDetails(int index) {
    final field = _currentScoringConfig.scoreFields[index];
    final nameController = TextEditingController(text: field.name);
    final unitController = TextEditingController(text: field.unit ?? '');
    bool isPrimary = field.isPrimary;
    bool showInCard = field.showInCard;
    String fieldType = field.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text('Edit Field Settings',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Field Name',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.textSecondary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppTheme.primaryGradientStart),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Unit (optional)',
                    hintText: 'e.g., pts, goals, runs',
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.textSecondary),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppTheme.primaryGradientStart),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: fieldType,
                  dropdownColor: AppTheme.surfaceDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Field Type',
                    labelStyle: TextStyle(color: AppTheme.textSecondary),
                  ),
                  items: ['number', 'time', 'text'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => fieldType = value!);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Primary Score',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Main score displayed prominently',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  value: isPrimary,
                  activeColor: AppTheme.primaryGradientStart,
                  onChanged: (value) {
                    setDialogState(() => isPrimary = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Show in Card',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Display in match cards',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  value: showInCard,
                  activeColor: AppTheme.primaryGradientStart,
                  onChanged: (value) {
                    setDialogState(() => showInCard = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    final fields = List<ScoreField>.from(
                        _currentScoringConfig.scoreFields);

                    // If making this field primary, unset other primary fields
                    if (isPrimary) {
                      for (int i = 0; i < fields.length; i++) {
                        if (i != index) {
                          fields[i] = fields[i].copyWith(isPrimary: false);
                        }
                      }
                    }

                    fields[index] = fields[index].copyWith(
                      name: nameController.text,
                      unit: unitController.text.isEmpty
                          ? null
                          : unitController.text,
                      type: fieldType,
                      isPrimary: isPrimary,
                      showInCard: showInCard,
                    );
                    _currentScoringConfig =
                        _currentScoringConfig.copyWith(scoreFields: fields);
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGradientStart,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveSport() async {
    if (_formKey.currentState!.validate()) {
      // Validate at least one primary field
      final hasPrimaryField =
          _currentScoringConfig.scoreFields.any((field) => field.isPrimary);
      if (!hasPrimaryField) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('At least one field must be marked as primary')),
        );
        return;
      }

      try {
        final sport = SportModel(
          id: widget.sport?.id ??
              'sport_${DateTime.now().millisecondsSinceEpoch}',
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
          await firestore
              .collection('sports')
              .doc(sport.id)
              .update(sport.toMap());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sport ${widget.sport == null ? 'created' : 'updated'} successfully!'),
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
    if (widget.isReadOnly && widget.sportConfig != null) {
      // Read-only mode for default sports
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.cardDark,
          title: Text(
            '${widget.sportConfig!.name} Configuration',
            style: const TextStyle(color: AppTheme.textColor),
          ),
          iconTheme: const IconThemeData(color: AppTheme.textColor),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Default Sport Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'This is a default sport template and cannot be modified',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sport Info
              _buildReadOnlySportInfo(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: Text(
          widget.sport != null || widget.sportConfig != null
              ? 'Edit Sport'
              : 'Create Sport',
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

  Widget _buildReadOnlySportInfo() {
    final sport = widget.sportConfig!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard('Basic Information', [
          _buildInfoRow('Name', sport.name),
          _buildInfoRow('Description', sport.description),
          _buildInfoRow('Icon', sport.icon),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Match Structure', [
          _buildInfoRow('Type', sport.structureType.toString().split('.').last),
          if (sport.duration != null && sport.duration! > 0)
            _buildInfoRow('Duration', '${sport.duration} minutes'),
          if (sport.overs != null && sport.overs! > 0)
            _buildInfoRow('Overs', '${sport.overs}'),
          if (sport.periods != null && sport.periods! > 0)
            _buildInfoRow('Periods/Sets', '${sport.periods}'),
          if (sport.pointsToWin != null && sport.pointsToWin! > 0)
            _buildInfoRow('Points to Win', '${sport.pointsToWin}'),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Players', [
          _buildInfoRow('Playing Players', '${sport.playingPlayers}'),
          _buildInfoRow('Min Players', '${sport.minPlayers ?? "N/A"}'),
          _buildInfoRow('Max Players', '${sport.maxPlayers ?? "N/A"}'),
          _buildInfoRow('Substitutions',
              sport.allowSubstitutions ? 'Allowed' : 'Not Allowed'),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Scoring System', [
          _buildInfoRow('Primary Score Unit', sport.primaryScoreUnit),
          _buildInfoRow('Score Actions', '${sport.scoreActions.length}'),
          _buildInfoRow(
              'Win Condition', sport.winCondition.toString().split('.').last),
          _buildInfoRow('Supports Tie', sport.supportsTie ? 'Yes' : 'No'),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard('Rules', [
          _buildInfoRow('Has Fouls', sport.hasFouls ? 'Yes' : 'No'),
          _buildInfoRow('Has Timeouts', sport.hasTimeouts ? 'Yes' : 'No'),
          _buildInfoRow('Has Extras', sport.hasExtras ? 'Yes' : 'No'),
        ]),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGradientStart,
                ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
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
                  color: isSelected
                      ? AppTheme.primaryGradientStart
                      : AppTheme.textColor,
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
                child: InkWell(
                  onTap: () => _editFieldName(index),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.name,
                          style: TextStyle(
                            color: field.isPrimary
                                ? AppTheme.primaryGradientStart
                                : AppTheme.textColor,
                            fontWeight: field.isPrimary
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit,
                          size: 16, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              if (field.isPrimary)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              // Edit button
              IconButton(
                onPressed: () => _editFieldDetails(index),
                icon: const Icon(Icons.settings, size: 20),
                color: AppTheme.accentGradientStart,
                tooltip: 'Edit field settings',
              ),
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
                  _nameController.text.isEmpty
                      ? 'Sport Name'
                      : _nameController.text,
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
                        Text('Sample Score',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    Text(
                      _iconController.text.isEmpty ? '⚽' : _iconController.text,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const Column(
                      children: [
                        Text('Team B', style: TextStyle(color: Colors.white70)),
                        Text('Sample Score',
                            style: TextStyle(color: Colors.white)),
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
