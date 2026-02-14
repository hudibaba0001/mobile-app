import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../design/design.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/absence.dart';
import '../providers/absence_provider.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/absence_entry_dialog.dart';

/// Screen for managing absence entries (vacation, sick leave, VAB, etc.)
class AbsenceManagementScreen extends StatefulWidget {
  const AbsenceManagementScreen({super.key});

  @override
  State<AbsenceManagementScreen> createState() =>
      _AbsenceManagementScreenState();
}

class _AbsenceManagementScreenState extends State<AbsenceManagementScreen> {
  int _selectedYear = DateTime.now().year;

  List<int> _availableYears() {
    final currentYear = DateTime.now().year;
    final createdAtRaw =
        context.read<SupabaseAuthService>().currentUser?.createdAt;
    final signupYear = DateTime.tryParse(createdAtRaw ?? '')?.year;
    final firstYear = (signupYear != null && signupYear <= currentYear)
        ? signupYear
        : currentYear;

    return List<int>.generate(
      currentYear - firstYear + 1,
      (index) => firstYear + index,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAbsences();
    });
  }

  Future<void> _loadAbsences() async {
    final years = _availableYears();
    final fallbackYear = years.isNotEmpty ? years.last : DateTime.now().year;
    final targetYear =
        years.contains(_selectedYear) ? _selectedYear : fallbackYear;

    if (targetYear != _selectedYear && mounted) {
      setState(() {
        _selectedYear = targetYear;
      });
    }

    final absenceProvider = context.read<AbsenceProvider>();
    await absenceProvider.loadAbsences(year: targetYear);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final years = _availableYears();

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
            itemBuilder: (context) => years
                .map(
                  (year) => PopupMenuItem(
                    value: year,
                    child: Text('$year'),
                  ),
                )
                .toList(),
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
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    t.absence_errorLoading,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    absenceProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    t.absence_noAbsences(_selectedYear),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.absence_addHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    onPressed: () => _showAddAbsenceDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(t.absence_addAbsence),
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
            padding: AppSpacing.pagePadding,
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
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAbsenceDialog(context),
        tooltip: t.absence_addAbsence,
        child: const Icon(Icons.add),
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

    final (typeLabel, typeIcon, typeColor) =
        _getTypeInfo(context, absence.type);

    final hours = absence.minutes == 0
        ? t.absence_fullDay
        : '${(absence.minutes / 60.0).toStringAsFixed(1)} h';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withValues(alpha: 0.1),
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

  (String, IconData, Color) _getTypeInfo(
      BuildContext context, AbsenceType type) {
    final t = AppLocalizations.of(context);
    switch (type) {
      case AbsenceType.vacationPaid:
        return (
          t.leave_paidVacation,
          Icons.beach_access,
          AbsenceColors.paidVacation,
        );
      case AbsenceType.sickPaid:
        return (
          t.leave_sickLeave,
          Icons.medical_services,
          AbsenceColors.sickLeave,
        );
      case AbsenceType.vabPaid:
        return (t.leave_vab, Icons.child_care, AbsenceColors.vab);
      case AbsenceType.unpaid:
        return (t.leave_unpaid, Icons.event_busy, AbsenceColors.unpaid);
    }
  }

  Future<void> _showAddAbsenceDialog(BuildContext context) async {
    await showAbsenceEntryDialog(context, year: _selectedYear);
  }

  Future<void> _showEditAbsenceDialog(
      BuildContext context, AbsenceEntry absence) async {
    await showAbsenceEntryDialog(
      context,
      year: _selectedYear,
      absence: absence,
    );
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
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(t.common_delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAbsence(
      BuildContext context, AbsenceEntry absence) async {
    final t = AppLocalizations.of(context);
    final absenceProvider = context.read<AbsenceProvider>();

    final absenceId = absence.id;
    if (absenceId == null) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.absence_deleteFailed)),
        );
      }
      return;
    }

    try {
      await absenceProvider.deleteAbsenceEntry(absenceId, absence.date.year);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.absence_deletedSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.absence_deleteFailed}: $e'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    }
  }
}
