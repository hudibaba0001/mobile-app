import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_router.dart';
import '../design/app_theme.dart';
import '../providers/contract_provider.dart';
import '../providers/settings_provider.dart';
import '../services/profile_service.dart';
import '../services/supabase_auth_service.dart';

enum WelcomeSetupMode { employee, freelancer }

enum _WelcomeStep { mode, contract, baseline }

class WelcomeSetupScreen extends StatefulWidget {
  const WelcomeSetupScreen({
    super.key,
    this.onCompleted,
    ProfileService? profileService,
  }) : _profileService = profileService;

  final VoidCallback? onCompleted;
  final ProfileService? _profileService;

  @override
  State<WelcomeSetupScreen> createState() => _WelcomeSetupScreenState();
}

class _WelcomeSetupScreenState extends State<WelcomeSetupScreen> {
  late WelcomeSetupMode _mode;
  late bool _travelEnabled;
  late bool _paidLeaveEnabled;
  late final TextEditingController _baselineController;
  _WelcomeStep _step = _WelcomeStep.mode;
  bool _isSaving = false;

  ProfileService get _profileService =>
      widget._profileService ?? ProfileService();

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    final contract = context.read<ContractProvider>();

    _mode = settings.isTimeBalanceEnabled
        ? WelcomeSetupMode.employee
        : WelcomeSetupMode.freelancer;
    _travelEnabled = settings.isTravelLoggingEnabled;
    _paidLeaveEnabled = settings.isPaidLeaveTrackingEnabled;
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
    if (input.isEmpty) return 0;

    final compact = input.replaceAll(' ', '');
    final hourMinutePattern = RegExp(r'^([+-]?)(\d+)h(?:(\d{1,2})m)?$');
    final hourOnlyPattern = RegExp(r'^([+-]?)(\d+(?:[.,]\d+)?)h?$');
    final decimalPattern = RegExp(r'^([+-]?)(\d+)[.,](\d+)$');

    final hourMinuteMatch = hourMinutePattern.firstMatch(compact);
    if (hourMinuteMatch != null) {
      final signPart = hourMinuteMatch.group(1) ?? '';
      final hourPart = int.tryParse(hourMinuteMatch.group(2) ?? '');
      final minutePart = int.tryParse(hourMinuteMatch.group(3) ?? '0');
      if (hourPart == null || minutePart == null || minutePart >= 60) {
        return null;
      }
      final total = hourPart * 60 + minutePart;
      return signPart == '-' ? -total : total;
    }

    final decimalMatch = decimalPattern.firstMatch(compact);
    if (decimalMatch != null) {
      final signPart = decimalMatch.group(1) ?? '';
      final hoursPart = int.tryParse(decimalMatch.group(2) ?? '');
      final decimals = decimalMatch.group(3) ?? '';
      if (hoursPart == null) return null;
      final fractional = double.tryParse('0.$decimals');
      if (fractional == null) return null;
      final total = (hoursPart * 60) + (fractional * 60).round();
      return signPart == '-' ? -total : total;
    }

    final hourOnlyMatch = hourOnlyPattern.firstMatch(compact);
    if (hourOnlyMatch != null) {
      final signPart = hourOnlyMatch.group(1) ?? '';
      final numberText = hourOnlyMatch.group(2) ?? '';
      final hours = double.tryParse(numberText.replaceAll(',', '.'));
      if (hours == null) return null;
      final total = (hours * 60).round();
      return signPart == '-' ? -total : total;
    }

    return null;
  }

  Future<void> _persistSetupCompletion({
    required DateTime trackingStartDate,
    required int openingFlexMinutes,
    int? contractPercent,
    int? fullTimeHours,
    bool? timeBalanceEnabled,
  }) async {
    final auth = context.read<SupabaseAuthService>();
    final userId = auth.currentUserId;
    if (userId == null) return;

    await _profileService.updateProfileFields({
      'tracking_start_date': trackingStartDate,
      'opening_flex_minutes': openingFlexMinutes,
      'setup_completed_at': DateTime.now().toUtc(),
      if (contractPercent != null) 'contract_percent': contractPercent,
      if (fullTimeHours != null) 'full_time_hours': fullTimeHours,
      if (timeBalanceEnabled != null)
        'time_balance_enabled': timeBalanceEnabled,
    });
    await _profileService.setLocalSetupCompleted(
      userId: userId,
      completed: true,
    );
  }

  Future<void> _finishFreelancerPath() async {
    final settings = context.read<SettingsProvider>();
    final contract = context.read<ContractProvider>();
    final today = _dateOnly(DateTime.now());

    await settings.setTimeBalanceEnabled(false);
    await settings.setTravelLoggingEnabled(_travelEnabled);
    await settings.setPaidLeaveTrackingEnabled(_paidLeaveEnabled);
    await settings.setBaselineDate(today);

    await contract.setTrackingStartDate(today);
    await contract.setOpeningFlexMinutes(0);

    await _persistSetupCompletion(
      trackingStartDate: today,
      openingFlexMinutes: 0,
      timeBalanceEnabled: false,
    );
    await settings.setSetupCompleted(true);
  }

  Future<void> _applyContractDefaults() async {
    final settings = context.read<SettingsProvider>();
    final contract = context.read<ContractProvider>();
    await settings.setTimeBalanceEnabled(true);
    await settings.setTravelLoggingEnabled(_travelEnabled);
    await settings.setPaidLeaveTrackingEnabled(_paidLeaveEnabled);
    await contract.updateContractSettings(100, 40);
  }

  Future<void> _finishEmployeePath() async {
    final settings = context.read<SettingsProvider>();
    final contract = context.read<ContractProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final today = _dateOnly(DateTime.now());

    final baselineMinutes = _parseBaselineMinutes(_baselineController.text);
    if (baselineMinutes == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Ange saldo som t.ex. +29h, -5h eller +29h 30m.'),
        ),
      );
      return;
    }

    await contract.setTrackingStartDate(today);
    await contract.setOpeningFlexMinutes(baselineMinutes);
    await settings.setBaselineDate(today);

    await _persistSetupCompletion(
      trackingStartDate: today,
      openingFlexMinutes: baselineMinutes,
      contractPercent: 100,
      fullTimeHours: 40,
      timeBalanceEnabled: true,
    );
    await settings.setSetupCompleted(true);
  }

  Future<void> _handleContinue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      if (_step == _WelcomeStep.mode) {
        if (_mode == WelcomeSetupMode.freelancer) {
          await _finishFreelancerPath();
          if (!mounted) return;
          _completeFlow();
          return;
        }
        setState(() => _step = _WelcomeStep.contract);
        return;
      }

      if (_step == _WelcomeStep.contract) {
        await _applyContractDefaults();
        if (!mounted) return;
        setState(() => _step = _WelcomeStep.baseline);
        return;
      }

      await _finishEmployeePath();
      if (!mounted) return;
      _completeFlow();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _completeFlow() {
    if (widget.onCompleted != null) {
      widget.onCompleted!.call();
      return;
    }
    context.goNamed(AppRouter.homeName);
  }

  void _handleBack() {
    if (_step == _WelcomeStep.contract) {
      setState(() => _step = _WelcomeStep.mode);
      return;
    }
    if (_step == _WelcomeStep.baseline) {
      setState(() => _step = _WelcomeStep.contract);
    }
  }

  String _titleForStep() {
    switch (_step) {
      case _WelcomeStep.mode:
        return 'Välkommen';
      case _WelcomeStep.contract:
        return 'Steg 2 av 3: Kontrakt';
      case _WelcomeStep.baseline:
        return 'Steg 3 av 3: Baslinje';
    }
  }

  Widget _buildModeStep(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hur vill du använda KvikTime?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<WelcomeSetupMode>(
          segments: const [
            ButtonSegment(
              value: WelcomeSetupMode.employee,
              icon: Icon(Icons.balance_rounded, size: AppIconSize.sm),
              label: Text('Tidssaldo (rekommenderas)'),
            ),
            ButtonSegment(
              value: WelcomeSetupMode.freelancer,
              icon: Icon(Icons.timer_outlined, size: AppIconSize.sm),
              label: Text('Bara logga tid'),
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
        const SizedBox(height: AppSpacing.lg),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _travelEnabled,
          onChanged: (value) {
            setState(() => _travelEnabled = value);
          },
          title: const Text('Logga restid'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _paidLeaveEnabled,
          onChanged: (value) {
            setState(() => _paidLeaveEnabled = value);
          },
          title: const Text('Spåra betald frånvaro'),
        ),
      ],
    );
  }

  Widget _buildContractStep(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Snabbinställning av kontrakt',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vi sätter säkra standardvärden för att komma igång snabbt.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Veckotid: 40h', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Arbetsdagar: 5', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Kontrakt: 100%', style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildBaselineStep(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vad är ditt plus/minus just nu?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Fråga lönekontor/chef: Vad är mitt plus/minus idag?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ange inte total arbetad tid.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _baselineController,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9hHmM+\-.,\s]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Saldo-baslinje',
              hintText: '+29h eller -5h',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      _titleForStep(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_step == _WelcomeStep.mode)
                      Text(
                        'Ställ in grunderna en gång och följ förändringen framåt.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    if (_step == _WelcomeStep.mode) _buildModeStep(theme),
                    if (_step == _WelcomeStep.contract)
                      _buildContractStep(theme),
                    if (_step == _WelcomeStep.baseline)
                      _buildBaselineStep(theme),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  if (_step != _WelcomeStep.mode)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : _handleBack,
                        child: const Text('Tillbaka'),
                      ),
                    ),
                  if (_step != _WelcomeStep.mode)
                    const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _handleContinue,
                      child: _isSaving
                          ? const SizedBox(
                              width: AppIconSize.sm,
                              height: AppIconSize.sm,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _step == _WelcomeStep.baseline
                                  ? 'Klar'
                                  : 'Fortsätt',
                            ),
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
