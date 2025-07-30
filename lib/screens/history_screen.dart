import 'package:flutter/material.dart';

/// History screen placeholder.
/// Will display unified history of both travel and work entries.
/// Features: Filtering, search, export, detailed entry views.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Show search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filters
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'HistoryScreen',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming soon - Unified entry history with filtering',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}