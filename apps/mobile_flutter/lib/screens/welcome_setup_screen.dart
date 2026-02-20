import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../config/app_router.dart';
import '../design/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/contract_provider.dart';
import '../providers/settings_provider.dart';
import '../services/profile_service.dart';
import '../services/supabase_auth_service.dart';
import '../widgets/onboarding/onboarding_scaffold.dart';

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
  late final TextEditingController _contractPercentController;
  late final TextEditingController _fullTimeHoursController;
  String? _contractPercentError;
  String? _fullTimeHoursError;
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
    _contractPercentController = TextEditingController(
      text: contract.contractPercent.toString(),
    );
    _fullTimeHoursController = TextEditingController(
      text: contract.fullTimeHours.toString(),
    );
    _contractPercentController.addListener(_validateContractDraft);
    _fullTimeHoursController.addListener(_validateContractDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _validateContractDraft();
      }
    });
  }

  @override
  void dispose() {
    _baselineController.dispose();
    _contractPercentController.dispose();
    _fullTimeHoursController.dispose();
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

  void _validateContractDraft() {
    final t = AppLocalizations.of(context);
    final percentText = _contractPercentController.text.trim();
    final hoursText = _fullTimeHoursController.text.trim();

    String? percentError;
    if (percentText.isEmpty) {
      percentError = t.common_required(t.contract_percentage);
    } else {
      final percent = int.tryParse(percentText);
      if (percent == null) {
        percentError = t.common_invalidNumber;
      } else if (percent < 0 || percent > 100) {
        percentError = t.contract_percentageError;
      }
    }

    String? hoursError;
    if (hoursText.isEmpty) {
      hoursError = t.common_required(t.contract_fullTimeHours);
    } else {
      final hours = int.tryParse(hoursText);
      if (hours == null) {
        hoursError = t.common_invalidNumber;
      } else if (hours <= 0) {
        hoursError = t.contract_fullTimeHoursError;
      }
    }

    if (percentError != _contractPercentError ||
        hoursError != _fullTimeHoursError) {
      setState(() {
        _contractPercentError = percentError;
        _fullTimeHoursError = hoursError;
      });
    }
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

  Future<bool> _applyContractDefaults() async {
    final settings = context.read<SettingsProvider>();
    final contract = context.read<ContractProvider>();
    final percentText = _contractPercentController.text.trim();
    final hoursText = _fullTimeHoursController.text.trim();
    final percent = int.tryParse(percentText);
    final hours = int.tryParse(hoursText);

    if (percent == null ||
        hours == null ||
        percent < 0 ||
        percent > 100 ||
        hours <= 0) {
      _validateContractDraft();
      return false;
    }
    await settings.setTimeBalanceEnabled(true);
    await settings.setTravelLoggingEnabled(_travelEnabled);
    await settings.setPaidLeaveTrackingEnabled(_paidLeaveEnabled);
    await contract.updateContractSettings(percent, hours);
    return true;
  }

  Future<void> _finishEmployeePath() async {
    final settings = context.read<SettingsProvider>();
    final contract = context.read<ContractProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    final today = _dateOnly(DateTime.now());

    final baselineMinutes = _parseBaselineMinutes(_baselineController.text);
    if (baselineMinutes == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.onboarding_baselineError),
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
      contractPercent: contract.contractPercent,
      fullTimeHours: contract.fullTimeHours,
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
        final applied = await _applyContractDefaults();
        if (!applied) return;
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

  String _titleForStep(AppLocalizations t) {
    switch (_step) {
      case _WelcomeStep.mode:
        return t.onboarding_step1Title;
      case _WelcomeStep.contract:
        return t.onboarding_step2Title;
      case _WelcomeStep.baseline:
        return t.onboarding_step3Title;
    }
  }

  Widget _buildModeStep(ThemeData theme, AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.onboarding_modeQuestion,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<WelcomeSetupMode>(
          segments: [
            ButtonSegment(
              value: WelcomeSetupMode.employee,
              icon: const Icon(Icons.balance_rounded, size: AppIconSize.sm),
              label: Text(t.onboarding_modeBalance),
            ),
            ButtonSegment(
              value: WelcomeSetupMode.freelancer,
              icon: const Icon(Icons.timer_outlined, size: AppIconSize.sm),
              label: Text(t.onboarding_modeLogOnly),
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
          title: Text(t.onboarding_toggleTravel),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _paidLeaveEnabled,
          onChanged: (value) {
            setState(() => _paidLeaveEnabled = value);
          },
          title: Text(t.onboarding_togglePaidLeave),
        ),
      ],
    );
  }

  Widget _buildContractStep(ThemeData theme, AppLocalizations t) {
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
            t.onboarding_contractTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.onboarding_contractBody,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _contractPercentController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: t.contract_percentage,
              hintText: t.contract_percentageHint,
              errorText: _contractPercentError,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _fullTimeHoursController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: t.contract_fullTimeHours,
              hintText: t.contract_fullTimeHoursHint,
              errorText: _fullTimeHoursError,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            t.onboarding_contractWorkdays(5),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineStep(ThemeData theme, AppLocalizations t) {
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
            t.onboarding_baselineTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.onboarding_baselineHelp,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.onboarding_baselineNote,
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
            decoration: InputDecoration(
              labelText: t.onboarding_baselineLabel,
              hintText: t.onboarding_baselinePlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final stepIndex = switch (_step) {
      _WelcomeStep.mode => 1,
      _WelcomeStep.contract => 2,
      _WelcomeStep.baseline => 3,
    };
    final subtitle =
        _step == _WelcomeStep.mode ? t.onboarding_modeSubtitle : null;
    final primaryLabel = _isSaving
        ? t.common_loading
        : (_step == _WelcomeStep.baseline ? t.common_done : t.common_continue);

    return OnboardingScaffold(
      title: _titleForStep(t),
      subtitle: subtitle,
      step: stepIndex,
      totalSteps: 3,
      primaryLabel: primaryLabel,
      onPrimary: _isSaving ? null : _handleContinue,
      secondaryLabel: _step == _WelcomeStep.mode ? null : t.common_back,
      onSecondary: _isSaving ? null : _handleBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step == _WelcomeStep.mode) _buildModeStep(theme, t),
          if (_step == _WelcomeStep.contract) _buildContractStep(theme, t),
          if (_step == _WelcomeStep.baseline) _buildBaselineStep(theme, t),
        ],
      ),
    );
  }
}
