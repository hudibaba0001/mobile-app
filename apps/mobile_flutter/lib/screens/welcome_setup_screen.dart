import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/app_router.dart';
import '../design/app_theme.dart';
import '../providers/contract_provider.dart';
import '../providers/settings_provider.dart';
import 'contract_settings_screen.dart';

enum WelcomeSetupMode { employee, freelancer }

class WelcomeSetupScreen extends StatefulWidget {
  const WelcomeSetupScreen({
    super.key,
    this.onCompleted,
  });

  final VoidCallback? onCompleted;

  @override
  State<WelcomeSetupScreen> createState() => _WelcomeSetupScreenState();
}

class _WelcomeSetupScreenState extends State<WelcomeSetupScreen> {
  late WelcomeSetupMode _mode;
  late bool _travelEnabled;
  late bool _paidLeaveEnabled;
  late DateTime _baselineDate;
  late final TextEditingController _baselineController;

  bool _isSaving = false;

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    final contract = context.read<ContractProvider>();
    final today = _dateOnly(DateTime.now());

    _mode = settings.isTimeBalanceEnabled
        ? WelcomeSetupMode.employee
        : WelcomeSetupMode.freelancer;
    _travelEnabled = settings.isTravelLoggingEnabled;
    _paidLeaveEnabled = settings.isPaidLeaveTrackingEnabled;
    _baselineDate = settings.baselineDate ?? contract.trackingStartDate;
    _baselineDate = _dateOnly(_baselineDate);
    if (_baselineDate.isAfter(today)) {
      _baselineDate = today;
    }

    _baselineController = TextEditingController(
      text: _formatBaselineInput(contract.openingFlexMinutes),
    );
  }

  @override
  void dispose() {
    _baselineController.dispose();
    super.dispose();
  }

  String _formatBaselineInput(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final absMinutes = minutes.abs();
    final hours = absMinutes ~/ 60;
    final mins = absMinutes % 60;
    if (mins == 0) {
      return '$sign${hours}h';
    }
    return '$sign${hours}h ${mins}m';
  }

  int? _parseBaselineMinutes(String raw) {
    final input = raw.trim().toLowerCase();
    if (input.isEmpty) {
      return 0;
    }

    final compact = input.replaceAll(' ', '');
    final hourMinutePattern = RegExp(r'^([+-]?)(\d+)h(?:(\d{1,2})m)?$');
    final hourOnlyPattern = RegExp(r'^([+-]?)(\d+(?:[.,]\d+)?)h?$');
    final decimalPattern = RegExp(r'^([+-]?)(\d+)[.,](\d+)$');

    final matchHourMinute = hourMinutePattern.firstMatch(compact);
    if (matchHourMinute != null) {
      final signPart = matchHourMinute.group(1) ?? '';
      final hourPart = int.tryParse(matchHourMinute.group(2) ?? '');
      final minutePart = int.tryParse(matchHourMinute.group(3) ?? '0');
      if (hourPart == null || minutePart == null || minutePart >= 60) {
        return null;
      }
      final total = hourPart * 60 + minutePart;
      return signPart == '-' ? -total : total;
    }

    final matchDecimal = decimalPattern.firstMatch(compact);
    if (matchDecimal != null) {
      final signPart = matchDecimal.group(1) ?? '';
      final hoursPart = int.tryParse(matchDecimal.group(2) ?? '');
      final decimals = matchDecimal.group(3) ?? '';
      if (hoursPart == null) return null;
      final fractional = double.tryParse('0.$decimals');
      if (fractional == null) return null;
      final total = (hoursPart * 60 + (fractional * 60).round());
      return signPart == '-' ? -total : total;
    }

    final matchHourOnly = hourOnlyPattern.firstMatch(compact);
    if (matchHourOnly != null) {
      final signPart = matchHourOnly.group(1) ?? '';
      final numberText = matchHourOnly.group(2) ?? '';
      final hours = double.tryParse(numberText.replaceAll(',', '.'));
      if (hours == null) return null;
      final total = (hours * 60).round();
      return signPart == '-' ? -total : total;
    }

    return null;
  }

  Future<void> _pickBaselineDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _baselineDate,
      firstDate: DateTime(now.year - 10, 1, 1),
      lastDate: _dateOnly(now),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _baselineDate = _dateOnly(picked);
    });
  }

  Future<void> _saveAndFinish({
    required bool skipped,
  }) async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    final settings = context.read<SettingsProvider>();
    final contract = context.read<ContractProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final isEmployee = !skipped && _mode == WelcomeSetupMode.employee;

    try {
      if (skipped) {
        await settings.setTimeBalanceEnabled(false);
        await settings.setTravelLoggingEnabled(true);
        await settings.setPaidLeaveTrackingEnabled(true);
        await settings.setSetupCompleted(true);
      } else {
        await settings.setTimeBalanceEnabled(isEmployee);
        await settings.setTravelLoggingEnabled(_travelEnabled);
        await settings.setPaidLeaveTrackingEnabled(_paidLeaveEnabled);

        if (isEmployee) {
          final hasContract = contract.contractPercent > 0 &&
              contract.contractPercent <= 100 &&
              contract.fullTimeHours > 0;
          if (!hasContract) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                    'Please configure contract settings before continuing.'),
              ),
            );
            return;
          }

          final baselineMinutes = _parseBaselineMinutes(_baselineController.text);
          if (baselineMinutes == null) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Enter baseline like +29h, -5h, or +29h 30m.'),
              ),
            );
            return;
          }

          await contract.setTrackingStartDate(_baselineDate);
          await contract.setOpeningFlexMinutes(baselineMinutes);
          await settings.setBaselineDate(_baselineDate);
        }

        await settings.setSetupCompleted(true);
      }

      if (!mounted) return;

      if (widget.onCompleted != null) {
        widget.onCompleted!.call();
      } else {
        context.goNamed(AppRouter.homeName);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _openContractSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ContractSettingsScreen(),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmployeeMode = _mode == WelcomeSetupMode.employee;
    final baselineDateText = DateFormat('yyyy-MM-dd').format(_baselineDate);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome setup',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Set your baseline once, then track your changes forward.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'How will you use KvikTime?',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<WelcomeSetupMode>(
                      segments: const [
                        ButtonSegment(
                          value: WelcomeSetupMode.employee,
                          icon: Icon(Icons.badge_outlined, size: AppIconSize.sm),
                          label: Text('Employee'),
                        ),
                        ButtonSegment(
                          value: WelcomeSetupMode.freelancer,
                          icon: Icon(Icons.work_outline, size: AppIconSize.sm),
                          label: Text('Freelancer'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _mode = selection.first;
                        });
                      },
                      showSelectedIcon: false,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _travelEnabled,
                      onChanged: (value) {
                        setState(() {
                          _travelEnabled = value;
                        });
                      },
                      title: const Text('Travel time logging'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _paidLeaveEnabled,
                      onChanged: (value) {
                        setState(() {
                          _paidLeaveEnabled = value;
                        });
                      },
                      title: const Text('Paid leave tracking'),
                    ),
                    if (isEmployeeMode) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Balance baseline (from employer)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Text(
                                  'As of: $baselineDateText',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                IconButton(
                                  onPressed: _pickBaselineDate,
                                  icon: const Icon(Icons.edit_calendar_rounded),
                                  tooltip: 'Change baseline date',
                                ),
                              ],
                            ),
                            TextField(
                              controller: _baselineController,
                              keyboardType: const TextInputType.numberWithOptions(
                                signed: true,
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9hHmM+\-.,\s]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Balance baseline',
                                hintText: '+29h or -5h',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Ask payroll/manager: What is my plus/minus balance today?',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              "Don't enter total hours worked.",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton.icon(
                              onPressed: _openContractSettings,
                              icon: const Icon(Icons.settings_outlined),
                              label: const Text('Contract settings'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => _saveAndFinish(skipped: true),
                      child: const Text('Skip for now'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _isSaving ? null : () => _saveAndFinish(skipped: false),
                      child: _isSaving
                          ? const SizedBox(
                              height: AppIconSize.sm,
                              width: AppIconSize.sm,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
