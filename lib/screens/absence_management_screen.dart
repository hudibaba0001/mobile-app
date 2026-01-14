import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/generated/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.absence_title),
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
            tooltip: t.absence_addAbsence,
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
                    t.absence_errorLoading,
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
                    child: Text(t.common_retry),
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
                    t.absence_noAbsences(_selectedYear),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.absence_addHint,
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
    final t = AppLocalizations.of(context);
    final dateFormat = DateFormat('EEEE, MMMM d');
    final dateStr = dateFormat.format(absence.date);

    final (typeLabel, typeIcon, typeColor) = _getTypeInfo(context, absence.type);

    final hours = absence.minutes == 0
        ? t.absence_fullDay
        : '${(absence.minutes / 60.0).toStringAsFixed(1)} h';

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
            Text('${t.entry_duration}: $hours'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditAbsenceDialog(context, absence),
              tooltip: t.common_edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmation(context, absence),
              tooltip: t.common_delete,
            ),
          ],
        ),
      ),
    );
  }

  (String, IconData, Color) _getTypeInfo(BuildContext context, AbsenceType type) {
    final t = AppLocalizations.of(context);
    switch (type) {
      case AbsenceType.vacationPaid:
        return (t.leave_paidVacation, Icons.beach_access, Colors.blue);
      case AbsenceType.sickPaid:
        return (t.leave_sickLeave, Icons.medical_services, Colors.red);
      case AbsenceType.vabPaid:
        return (t.leave_vab, Icons.child_care, Colors.orange);
      case AbsenceType.unpaid:
        return (t.leave_unpaid, Icons.event_busy, Colors.grey);
    }
  }

  void _showAddAbsenceDialog(BuildContext context) {
    _showAbsenceDialog(context);
  }

  void _showEditAbsenceDialog(BuildContext context, AbsenceEntry absence) {
    _showAbsenceDialog(context, absence: absence);
  }

  void _showAbsenceDialog(BuildContext context, {AbsenceEntry? absence}) {
    final t = AppLocalizations.of(context);
    final isEditing = absence != null;
    DateTime selectedDate = absence?.date ?? DateTime.now();
    AbsenceType selectedType = absence?.type ?? AbsenceType.vacationPaid;
    int selectedMinutes = absence?.minutes ?? 0;
    bool isFullDay = selectedMinutes == 0;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(isEditing ? t.absence_editAbsence : t.absence_addAbsence),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date picker
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(t.absence_date),
                  subtitle: Text(DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
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
                  title: Text(t.absence_type),
                  subtitle: Text(_getTypeLabel(context, selectedType)),
                  onTap: () {
                    _showTypeSelector(ctx, selectedType, (type) {
                      setState(() {
                        selectedType = type;
                      });
                    });
                  },
                ),
                const Divider(),

                // Duration selector
                CheckboxListTile(
                  title: Text(t.absence_fullDay),
                  value: isFullDay,
                  onChanged: (value) {
                    setState(() {
                      isFullDay = value ?? true;
                      if (isFullDay) {
                        selectedMinutes = 0;
                      } else {
                        selectedMinutes = 480;
                      }
                    });
                  },
                ),
                if (!isFullDay) ...[
                  const SizedBox(height: 8),
                  Text('${(selectedMinutes / 60.0).toStringAsFixed(1)} h'),
                  Slider(
                    value: selectedMinutes.toDouble().clamp(60, 480),
                    min: 60,
                    max: 480,
                    divisions: 7,
                    label: '${(selectedMinutes / 60.0).toStringAsFixed(1)} h',
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
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.common_cancel),
            ),
            ElevatedButton(
              onPressed: () => _saveAbsence(
                ctx,
                isEditing,
                absence?.id,
                selectedDate,
                selectedType,
                selectedMinutes,
              ),
              child: Text(isEditing ? t.common_save : t.common_add),
            ),
          ],
        ),
      ),
    );
  }

  void _showTypeSelector(BuildContext context, AbsenceType current, ValueChanged<AbsenceType> onSelected) {
    final t = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.beach_access, color: Colors.blue),
            title: Text(t.leave_paidVacation),
            onTap: () {
              onSelected(AbsenceType.vacationPaid);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services, color: Colors.red),
            title: Text(t.leave_sickLeave),
            onTap: () {
              onSelected(AbsenceType.sickPaid);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.child_care, color: Colors.orange),
            title: Text(t.leave_vab),
            onTap: () {
              onSelected(AbsenceType.vabPaid);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_busy, color: Colors.grey),
            title: Text(t.leave_unpaid),
            onTap: () {
              onSelected(AbsenceType.unpaid);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveAbsence(
    BuildContext context,
    bool isEditing,
    String? id,
    DateTime date,
    AbsenceType type,
    int minutes,
  ) async {
    final t = AppLocalizations.of(context);
    final absenceProvider = context.read<AbsenceProvider>();
    final entry = AbsenceEntry(
      id: id,
      date: DateTime(date.year, date.month, date.day),
      minutes: minutes,
      type: type,
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
          SnackBar(content: Text(t.absence_savedSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.absence_saveFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, AbsenceEntry absence) {
    final t = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.absence_deleteAbsence),
        content: Text(t.absence_deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => _deleteAbsence(ctx, absence),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(t.common_delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAbsence(BuildContext context, AbsenceEntry absence) async {
    final t = AppLocalizations.of(context);
    final absenceProvider = context.read<AbsenceProvider>();
    
    try {
      await absenceProvider.deleteAbsenceEntry(absence.id!, absence.date.year);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.absence_deletedSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.absence_deleteFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getTypeLabel(BuildContext context, AbsenceType type) {
    final t = AppLocalizations.of(context);
    switch (type) {
      case AbsenceType.vacationPaid:
        return t.leave_paidVacation;
      case AbsenceType.sickPaid:
        return t.leave_sickLeave;
      case AbsenceType.vabPaid:
        return t.leave_vab;
      case AbsenceType.unpaid:
        return t.leave_unpaid;
    }
  }
}
