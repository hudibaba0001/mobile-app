import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/absence.dart';
import '../providers/absence_provider.dart';

/// Screen for managing absence entries (vacation, sick leave, VAB, etc.)
class AbsenceManagementScreen extends StatefulWidget {
  const AbsenceManagementScreen({super.key});

  @override
  State<AbsenceManagementScreen> createState() => _AbsenceManagementScreenState();
}

class _AbsenceManagementScreenState extends State<AbsenceManagementScreen> {
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbsences();
    });
  }

  Future<void> _loadAbsences() async {
    final absenceProvider = context.read<AbsenceProvider>();
    await absenceProvider.loadAbsences(year: _selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absences'),
        actions: [
          // Year selector
          PopupMenuButton<int>(
            icon: Text('$_selectedYear'),
            onSelected: (year) {
              setState(() {
                _selectedYear = year;
              });
              _loadAbsences();
            },
            itemBuilder: (context) {
              final currentYear = DateTime.now().year;
              return List.generate(3, (index) {
                final year = currentYear - 1 + index;
                return PopupMenuItem(
                  value: year,
                  child: Text('$year'),
                );
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAbsenceDialog(context),
            tooltip: 'Add Absence',
          ),
        ],
      ),
      body: Consumer<AbsenceProvider>(
        builder: (context, absenceProvider, child) {
          if (absenceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (absenceProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading absences',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    absenceProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAbsences,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final absences = absenceProvider.absencesForYear(_selectedYear);

          if (absences.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No absences for $_selectedYear',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add vacation, sick leave, or VAB',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Group absences by month
          final absencesByMonth = <int, List<AbsenceEntry>>{};
          for (final absence in absences) {
            final month = absence.date.month;
            absencesByMonth.putIfAbsent(month, () => []).add(absence);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: absencesByMonth.length,
            itemBuilder: (context, index) {
              final month = absencesByMonth.keys.toList()..sort();
              final monthAbsences = absencesByMonth[month[index]]!;
              final monthName = DateFormat('MMMM yyyy').format(
                DateTime(_selectedYear, month[index], 1),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      monthName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...monthAbsences.map((absence) => _buildAbsenceCard(
                        context,
                        absence,
                        absenceProvider,
                      )),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAbsenceCard(
    BuildContext context,
    AbsenceEntry absence,
    AbsenceProvider absenceProvider,
  ) {
    final dateFormat = DateFormat('EEEE, MMMM d', 'en_US');
    final dateStr = dateFormat.format(absence.date);

    String typeLabel;
    IconData typeIcon;
    Color typeColor;

    switch (absence.type) {
      case AbsenceType.vacationPaid:
        typeLabel = 'Vacation (Paid)';
        typeIcon = Icons.beach_access;
        typeColor = Colors.blue;
        break;
      case AbsenceType.sickPaid:
        typeLabel = 'Sick Leave (Paid)';
        typeIcon = Icons.medical_services;
        typeColor = Colors.red;
        break;
      case AbsenceType.vabPaid:
        typeLabel = 'VAB (Paid)';
        typeIcon = Icons.child_care;
        typeColor = Colors.orange;
        break;
      case AbsenceType.unpaid:
        typeLabel = 'Unpaid Leave';
        typeIcon = Icons.event_busy;
        typeColor = Colors.grey;
        break;
    }

    final hours = absence.minutes == 0
        ? 'Full day'
        : '${(absence.minutes / 60.0).toStringAsFixed(1)} hours';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.1),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Text(typeLabel),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr),
            Text('Duration: $hours'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditAbsenceDialog(context, absence),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context, absence),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAbsenceDialog(BuildContext context) {
    _showAbsenceDialog(context);
  }

  void _showEditAbsenceDialog(BuildContext context, AbsenceEntry absence) {
    _showAbsenceDialog(context, absence: absence);
  }

  void _showAbsenceDialog(BuildContext context, {AbsenceEntry? absence}) {
    final isEditing = absence != null;
    DateTime selectedDate = absence?.date ?? DateTime.now();
    AbsenceType selectedType = absence?.type ?? AbsenceType.vacationPaid;
    int selectedMinutes = absence?.minutes ?? 0;
    bool isFullDay = selectedMinutes == 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Absence' : 'Add Absence'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date picker
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(_selectedYear, 1, 1),
                      lastDate: DateTime(_selectedYear, 12, 31),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                const Divider(),

                // Type selector
                ListTile(
                  leading: const Icon(Icons.category),
                  title: const Text('Type'),
                  subtitle: Text(_getTypeLabel(selectedType)),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.beach_access, color: Colors.blue),
                            title: const Text('Vacation (Paid)'),
                            onTap: () {
                              setState(() {
                                selectedType = AbsenceType.vacationPaid;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.medical_services, color: Colors.red),
                            title: const Text('Sick Leave (Paid)'),
                            onTap: () {
                              setState(() {
                                selectedType = AbsenceType.sickPaid;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.child_care, color: Colors.orange),
                            title: const Text('VAB (Paid)'),
                            onTap: () {
                              setState(() {
                                selectedType = AbsenceType.vabPaid;
                              });
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.event_busy, color: Colors.grey),
                            title: const Text('Unpaid Leave'),
                            onTap: () {
                              setState(() {
                                selectedType = AbsenceType.unpaid;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(),

                // Duration selector
                CheckboxListTile(
                  title: const Text('Full day'),
                  value: isFullDay,
                  onChanged: (value) {
                    setState(() {
                      isFullDay = value ?? true;
                      if (isFullDay) {
                        selectedMinutes = 0;
                      }
                    });
                  },
                ),
                if (!isFullDay) ...[
                  const SizedBox(height: 8),
                  Text('Hours: ${(selectedMinutes / 60.0).toStringAsFixed(1)}'),
                  Slider(
                    value: selectedMinutes.toDouble(),
                    min: 60,
                    max: 480,
                    divisions: 7,
                    label: '${(selectedMinutes / 60.0).toStringAsFixed(1)} hours',
                    onChanged: (value) {
                      setState(() {
                        selectedMinutes = value.round();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final absenceProvider = context.read<AbsenceProvider>();
                final entry = AbsenceEntry(
                  id: absence?.id,
                  date: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
                  minutes: selectedMinutes,
                  type: selectedType,
                );

                try {
                  if (isEditing) {
                    await absenceProvider.updateAbsenceEntry(entry);
                  } else {
                    await absenceProvider.addAbsenceEntry(entry);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEditing
                              ? 'Absence updated successfully'
                              : 'Absence added successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AbsenceEntry absence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Absence'),
        content: Text(
          'Are you sure you want to delete this absence entry for ${DateFormat('MMMM d, yyyy').format(absence.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final absenceProvider = context.read<AbsenceProvider>();
              try {
                await absenceProvider.deleteAbsenceEntry(absence.id!, absence.date.year);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Absence deleted successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(AbsenceType type) {
    switch (type) {
      case AbsenceType.vacationPaid:
        return 'Vacation (Paid)';
      case AbsenceType.sickPaid:
        return 'Sick Leave (Paid)';
      case AbsenceType.vabPaid:
        return 'VAB (Paid)';
      case AbsenceType.unpaid:
        return 'Unpaid Leave';
    }
  }
}

