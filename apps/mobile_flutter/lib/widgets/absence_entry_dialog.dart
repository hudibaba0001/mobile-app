import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../design/design.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/absence.dart';
import '../providers/absence_provider.dart';

Future<bool?> showAbsenceEntryDialog(
  BuildContext context, {
  required int year,
  AbsenceEntry? absence,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (dialogContext) => _AbsenceEntryDialog(
      year: year,
      absence: absence,
    ),
  );
}

class _AbsenceEntryDialog extends StatefulWidget {
  final int year;
  final AbsenceEntry? absence;

  const _AbsenceEntryDialog({
    required this.year,
    this.absence,
  });

  @override
  State<_AbsenceEntryDialog> createState() => _AbsenceEntryDialogState();
}

class _AbsenceEntryDialogState extends State<_AbsenceEntryDialog> {
  late DateTime _selectedDate;
  late AbsenceType _selectedType;
  late int _selectedMinutes;
  late bool _isFullDay;

  bool get _isEditing => widget.absence != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.absence?.date ?? DateTime.now();
    _selectedType = widget.absence?.type ?? AbsenceType.vacationPaid;
    _selectedMinutes = widget.absence?.minutes ?? 0;
    _isFullDay = _selectedMinutes == 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEditing ? t.absence_editAbsence : t.absence_addAbsence,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(t.absence_date),
              subtitle: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
              ),
              onTap: () => _pickDate(context),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.category),
              title: Text(t.absence_type),
              subtitle: Text(_getTypeLabel(context, _selectedType)),
              onTap: () => _showTypeSelector(context),
            ),
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.absence_fullDay),
              value: _isFullDay,
              onChanged: (value) {
                setState(() {
                  _isFullDay = value;
                  if (_isFullDay) {
                    _selectedMinutes = 0;
                  } else {
                    _selectedMinutes = 480;
                  }
                });
              },
            ),
            if (!_isFullDay) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${(_selectedMinutes / 60.0).toStringAsFixed(1)} h',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Slider(
                value: _selectedMinutes.toDouble().clamp(60, 480),
                min: 60,
                max: 480,
                divisions: 7,
                label: '${(_selectedMinutes / 60.0).toStringAsFixed(1)} h',
                onChanged: (value) {
                  setState(() {
                    _selectedMinutes = value.round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _selectedMinutes > 60
                        ? () {
                            setState(() {
                              _selectedMinutes =
                                  (_selectedMinutes - 60).clamp(60, 480);
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove),
                    label: const Text('-1h'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _selectedMinutes < 480
                        ? () {
                            setState(() {
                              _selectedMinutes =
                                  (_selectedMinutes + 60).clamp(60, 480);
                            });
                          }
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('+1h'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(t.common_cancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAbsence,
                    child: Text(_isEditing ? t.common_save : t.common_add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(widget.year, 1, 1),
      lastDate: DateTime(widget.year, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showTypeSelector(BuildContext context) {
    final t = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.beach_access,
                  color: AbsenceColors.paidVacation,
                ),
                title: Text(t.leave_paidVacation),
                onTap: () {
                  setState(() => _selectedType = AbsenceType.vacationPaid);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.medical_services,
                  color: AbsenceColors.sickLeave,
                ),
                title: Text(t.leave_sickLeave),
                onTap: () {
                  setState(() => _selectedType = AbsenceType.sickPaid);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.child_care,
                  color: AbsenceColors.vab,
                ),
                title: Text(t.leave_vab),
                onTap: () {
                  setState(() => _selectedType = AbsenceType.vabPaid);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.event_busy,
                  color: AbsenceColors.unpaid,
                ),
                title: Text(t.leave_unpaid),
                onTap: () {
                  setState(() => _selectedType = AbsenceType.unpaid);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
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
      case AbsenceType.unknown:
        return t.leave_unknownType;
    }
  }

  Future<void> _saveAbsence() async {
    final t = AppLocalizations.of(context);
    final absenceProvider = context.read<AbsenceProvider>();
    final entry = AbsenceEntry(
      id: widget.absence?.id,
      date: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ),
      minutes: _selectedMinutes,
      type: _selectedType,
    );

    try {
      if (_isEditing) {
        await absenceProvider.updateAbsenceEntry(entry);
      } else {
        await absenceProvider.addAbsenceEntry(entry);
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(
        SnackBar(content: Text(t.absence_savedSuccess)),
      );
    } catch (e) {
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.absence_saveFailed}: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }
}
