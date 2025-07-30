import 'package:flutter/material.dart';

/// Edit Entry screen placeholder.
/// Will handle editing of both travel and work entries using the unified Entry model.
/// Features: Form fields, validation, save/cancel, entry type switching.
class EditEntryScreen extends StatelessWidget {
  final String entryId;
  final String? entryType;

  const EditEntryScreen({
    Key? key,
    required this.entryId,
    this.entryType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayType = entryType ?? 'travel';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${_capitalizeFirst(displayType)} Entry'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Save entry
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _getEntryTypeIcon(displayType),
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Edit ${_capitalizeFirst(displayType)} Entry',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entry ID: $entryId',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This screen will be implemented with the unified Entry model form.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Save entry
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  IconData _getEntryTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'travel':
        return Icons.directions_car;
      case 'work':
        return Icons.work;
      default:
        return Icons.edit;
    }
  }
}