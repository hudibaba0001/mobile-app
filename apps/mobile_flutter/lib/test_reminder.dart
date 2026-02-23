import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/settings_provider.dart';
import 'services/reminder_service.dart';

// Test page to explicitly print errors during reminder scheduling
class TestReminderScreen extends StatefulWidget {
  const TestReminderScreen({super.key});

  @override
  State<TestReminderScreen> createState() => _TestReminderScreenState();
}

class _TestReminderScreenState extends State<TestReminderScreen> {
  String _status = 'Idle';

  Future<void> _testSchedule() async {
    setState(() => _status = 'Requesting permissions...');
    final reminderService = context.read<ReminderService>();

    final granted = await reminderService.requestPermissions();
    if (!granted) {
      setState(() => _status = 'Permissions denied');
      return;
    }

    setState(() => _status = 'Scheduling daily reminder...');
    try {
      await reminderService.scheduleDailyReminder(
        hour: 12,
        minute: 0,
        message: 'Test message',
      );
      setState(() => _status = 'Success!\nScheduled for 12:00 PM.');
    } catch (e, stack) {
      setState(() => _status = 'Error:\n$e\n$stack');
      debugPrint('TEST ERROR: $e\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testSchedule,
              child: const Text('Run Test Schedule'),
            ),
            const SizedBox(height: 16),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
