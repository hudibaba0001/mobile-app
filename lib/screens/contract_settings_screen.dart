import 'package:flutter/material.dart';

/// Contract Settings screen placeholder.
/// Will host the form for Contract % and Full-time Hours.
/// Features: Contract percentage slider, full-time hours input, save/reset.
class ContractSettingsScreen extends StatelessWidget {
  const ContractSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contract Settings'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Save settings
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.work_outline),
                        const SizedBox(width: 8),
                        Text(
                          'Contract Settings',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Configure your contract percentage and full-time hours for accurate work time tracking.',
                    ),
                    const SizedBox(height: 24),
                    const Text('Contract Percentage'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Slider for contract % (0-100%)'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Full-time Hours per Week'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Input field for hours (e.g., 40)'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'ContractSettingsScreen coming soon',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}