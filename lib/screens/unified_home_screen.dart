import 'package:flutter/material.dart';

/// Unified Home screen placeholder.
/// Will be the main entry point combining travel and work time tracking.
/// Features: Quick entry forms, recent entries, navigation tabs, summary cards.
class UnifiedHomeScreen extends StatelessWidget {
  const UnifiedHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time,
              size: 64,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'UnifiedHomeScreen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon - Unified travel and work time tracking',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Show quick entry dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}