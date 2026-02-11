import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/contract_provider.dart';
import '../config/app_router.dart';
import '../l10n/generated/app_localizations.dart';
import '../design/app_theme.dart';

/// Contract Settings screen with full ContractProvider integration
/// Features: Contract percentage input, full-time hours input, live preview, validation
class ContractSettingsScreen extends StatefulWidget {
  const ContractSettingsScreen({super.key});

  @override
  State<ContractSettingsScreen> createState() => _ContractSettingsScreenState();
}

class _ContractSettingsScreenState extends State<ContractSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contractPercentController = TextEditingController();
  final _fullTimeHoursController = TextEditingController();

  // Starting balance fields
  final _openingHoursController = TextEditingController();
  final _openingMinutesController = TextEditingController();
  DateTime _trackingStartDate = DateTime(DateTime.now().year, 1, 1);
  bool _isDeficit = false; // false = credit (+), true = deficit (-)

  // Employer mode
  String _employerMode = 'standard'; // 'standard', 'strict', 'flexible'

  bool _isFormValid = false;
  String? _contractPercentError;
  String? _fullTimeHoursError;
  String? _openingBalanceError;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current provider values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contractProvider = context.read<ContractProvider>();

      _contractPercentController.text =
          contractProvider.contractPercent.toString();
      _fullTimeHoursController.text = contractProvider.fullTimeHours.toString();

      // Initialize starting balance fields
      _trackingStartDate = contractProvider.trackingStartDate;
      final absMinutes = contractProvider.openingFlexMinutes.abs();
      final hours = absMinutes ~/ 60;
      final mins = absMinutes % 60;
      _openingHoursController.text = hours.toString();
      _openingMinutesController.text = mins.toString().padLeft(2, '0');
      _isDeficit = contractProvider.openingFlexMinutes < 0;

      // Initialize employer mode
      _employerMode = contractProvider.employerMode;

      _validateForm();
    });

    // Add listeners for real-time validation
    _contractPercentController.addListener(_validateForm);
    _fullTimeHoursController.addListener(_validateForm);
    _openingHoursController.addListener(_validateForm);
    _openingMinutesController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _contractPercentController.dispose();
    _fullTimeHoursController.dispose();
    _openingHoursController.dispose();
    _openingMinutesController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final t = AppLocalizations.of(context);
    setState(() {
      // Validate contract percentage
      final contractPercentText = _contractPercentController.text.trim();
      if (contractPercentText.isEmpty) {
        _contractPercentError = t.common_required(t.contract_percentage);
      } else {
        final contractPercent = int.tryParse(contractPercentText);
        if (contractPercent == null) {
          _contractPercentError = t.common_invalidNumber;
        } else if (contractPercent < 0 || contractPercent > 100) {
          _contractPercentError = t.contract_percentageError;
        } else {
          _contractPercentError = null;
        }
      }

      // Validate full-time hours
      final fullTimeHoursText = _fullTimeHoursController.text.trim();
      if (fullTimeHoursText.isEmpty) {
        _fullTimeHoursError = t.common_required(t.contract_fullTimeHours);
      } else {
        final fullTimeHours = int.tryParse(fullTimeHoursText);
        if (fullTimeHours == null) {
          _fullTimeHoursError = t.common_invalidNumber;
        } else if (fullTimeHours <= 0) {
          _fullTimeHoursError = t.contract_fullTimeHoursError;
        } else if (fullTimeHours > 168) {
          // 24 hours * 7 days
          _fullTimeHoursError = t.contract_maxHoursError;
        } else {
          _fullTimeHoursError = null;
        }
      }

      // Validate opening balance
      final hoursText = _openingHoursController.text.trim();
      final minutesText = _openingMinutesController.text.trim();

      if (hoursText.isEmpty && minutesText.isEmpty) {
        // Both empty is valid (defaults to 0)
        _openingBalanceError = null;
      } else {
        final hours = int.tryParse(hoursText.isEmpty ? '0' : hoursText);
        final minutes = int.tryParse(minutesText.isEmpty ? '0' : minutesText);

        if (hours == null || hours < 0) {
          _openingBalanceError = t.contract_invalidHours;
        } else if (minutes == null || minutes < 0 || minutes >= 60) {
          _openingBalanceError = t.contract_minutesError;
        } else {
          _openingBalanceError = null;
        }
      }

      // Form is valid if all fields have no errors
      _isFormValid = _contractPercentError == null &&
          _fullTimeHoursError == null &&
          _openingBalanceError == null;
    });
  }

  Future<void> _saveSettings() async {
    final t = AppLocalizations.of(context);
    if (_isFormValid) {
      final contractProvider = context.read<ContractProvider>();

      // Parse values
      final contractPercent = int.parse(_contractPercentController.text.trim());
      final fullTimeHours = int.parse(_fullTimeHoursController.text.trim());

      final hoursText = _openingHoursController.text.trim();
      final minutesText = _openingMinutesController.text.trim();
      final hours = int.tryParse(hoursText.isEmpty ? '0' : hoursText) ?? 0;
      final minutes =
          int.tryParse(minutesText.isEmpty ? '0' : minutesText) ?? 0;
      final totalMinutes = (hours * 60) + minutes;
      final signedMinutes = _isDeficit ? -totalMinutes : totalMinutes;

      // Update provider (saves to both local cache and Supabase)
      await contractProvider.updateContractSettings(
          contractPercent, fullTimeHours);
      await contractProvider.setTrackingStartDate(_trackingStartDate);
      await contractProvider.setOpeningFlexMinutes(signedMinutes);
      await contractProvider.setEmployerMode(_employerMode);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.contract_savedSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      AppRouter.goBackOrHome(context);
    }
  }

  void _resetToDefaults() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.contract_resetToDefaults),
        content: Text(t.contract_resetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common_cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              final contractProvider = context.read<ContractProvider>();
              contractProvider.resetToDefaults();
              _contractPercentController.text =
                  contractProvider.contractPercent.toString();
              _fullTimeHoursController.text =
                  contractProvider.fullTimeHours.toString();

              // Reset starting balance fields
              setState(() {
                _trackingStartDate = contractProvider.trackingStartDate;
                _openingHoursController.text = '0';
                _openingMinutesController.text = '00';
                _isDeficit = false;
                _employerMode = 'standard';
              });

              _validateForm();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.contract_resetSuccess),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            child: Text(t.common_reset),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(t.contract_title),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.goBackOrHome(context),
        ),
        actions: [
          TextButton(
            onPressed: _isFormValid ? _saveSettings : null,
            child: Text(
              t.common_save,
              style: TextStyle(
                color: _isFormValid
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          // Local calculations for Live Preview
          final percent = int.tryParse(_contractPercentController.text) ?? 100;
          final fHours = int.tryParse(_fullTimeHoursController.text) ?? 40;

          final allowedHours = (fHours * percent / 100).round();
          final allowedPerDay = allowedHours / 5.0;

          // Opening balance formatting
          final hoursText = _openingHoursController.text.trim();
          final minutesText = _openingMinutesController.text.trim();
          final opHours =
              int.tryParse(hoursText.isEmpty ? '0' : hoursText) ?? 0;
          final opMins =
              int.tryParse(minutesText.isEmpty ? '0' : minutesText) ?? 0;

          String openingFormatted;
          final sign = _isDeficit ? '−' : '+';
          if (opMins == 0) {
            openingFormatted = '$sign${opHours}h';
          } else {
            openingFormatted = '$sign${opHours}h ${opMins}m';
          }
          final hasOpening = opHours != 0 || opMins != 0;

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.work_outline,
                                color: colorScheme.primary,
                                size: AppIconSize.lg,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                t.contract_headerTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            t.contract_headerDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Contract Percentage Field
                  _buildTextField(
                    theme,
                    t.contract_percentage,
                    _contractPercentController,
                    t.contract_percentageHint,
                    suffixText: '%',
                    errorText: _contractPercentError,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Full-time Hours Field
                  _buildTextField(
                    theme,
                    t.contract_fullTimeHours,
                    _fullTimeHoursController,
                    t.contract_fullTimeHoursHint,
                    suffixText: t.contract_hrsWeek,
                    errorText: _fullTimeHoursError,
                    keyboardType: TextInputType.number,
                    inputFormatters: [],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Employer Mode Dropdown
                  Text(
                    'Employer Mode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      color: colorScheme.surface,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _employerMode,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: [
                          DropdownMenuItem(
                            value: 'standard',
                            child: Text(
                              t.contract_modeStandard,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'strict',
                            child: Text(
                              t.contract_modeStrict,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'flexible',
                            child: Text(
                              t.contract_modeFlexible,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _employerMode = newValue;
                            });
                            _validateForm();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _employerMode == 'strict'
                        ? t.contract_modeStrictDesc
                        : _employerMode == 'flexible'
                            ? t.contract_modeFlexibleDesc
                            : t.contract_modeStandardDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Starting Balance Section
                  // Pass null for Provider as we use local state here, or rework _buildStartingBalanceSection to not need Provider
                  // Actually, _buildStartingBalanceSection uses local controllers mostly but might default to provider.
                  // Let's just pass context.read since we are not updating it live.
                  _buildStartingBalanceSection(
                      theme, colorScheme, context.read<ContractProvider>(), t),

                  const SizedBox(height: AppSpacing.xxl),

                  // Live Preview Card
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.preview,
                                color: colorScheme.secondary,
                                size: AppIconSize.md,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                t.contract_livePreview,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _buildPreviewRow(
                            theme,
                            t.contract_contractType,
                            percent == 100
                                ? t.contract_fullTime
                                : t.contract_partTime,
                            Icons.badge,
                          ),
                          _buildPreviewRow(
                            theme,
                            t.contract_percentage,
                            '$percent%',
                            Icons.percent,
                          ),
                          _buildPreviewRow(
                            theme,
                            t.contract_fullTimeHours,
                            '$fHours hours/week',
                            Icons.schedule,
                          ),
                          _buildPreviewRow(
                            theme,
                            t.contract_allowedHours,
                            '$allowedHours hours/week',
                            Icons.check_circle,
                            isHighlighted: true,
                          ),
                          _buildPreviewRow(
                            theme,
                            t.contract_dailyHours,
                            t.contract_hoursPerDayValue(
                                allowedPerDay.toStringAsFixed(1)),
                            Icons.today,
                          ),
                          const Divider(height: AppSpacing.xl),
                          _buildPreviewRow(
                            theme,
                            t.contract_startTrackingFrom,
                            DateFormat('MMM d, yyyy')
                                .format(_trackingStartDate),
                            Icons.calendar_today,
                          ),
                          _buildPreviewRow(
                            theme,
                            t.contract_openingBalance,
                            openingFormatted,
                            Icons.account_balance_wallet,
                            isHighlighted: hasOpening,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Action Buttons
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _resetToDefaults,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(
                          t.common_reset,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppSpacing.xxxl),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isFormValid ? _saveSettings : null,
                          icon: const Icon(Icons.save),
                          label: Text(t.contract_saveSettings),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(0, AppSpacing.xxxl),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    ThemeData theme,
    String label,
    TextEditingController controller,
    String hint, {
    String? suffixText,
    String? errorText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.all(AppSpacing.lg),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppIconSize.sm,
            color: isHighlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: isHighlighted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartingBalanceSection(
    ThemeData theme,
    ColorScheme colorScheme,
    ContractProvider contractProvider,
    AppLocalizations t,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: colorScheme.tertiary,
                  size: AppIconSize.md,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    t.contract_startingBalance,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.contract_startingBalanceDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Start Tracking From Date
            Text(
              t.contract_startTrackingFrom,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () => _selectStartDate(context),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  color: colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                      size: AppIconSize.sm,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_trackingStartDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit,
                      color: colorScheme.onSurfaceVariant,
                      size: AppIconSize.xs,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Opening Time Balance
            Text(
              t.contract_openingBalance,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Credit/Deficit Toggle - full width row
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    color: colorScheme.surface,
                  ),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(AppRadius.md - 1),
                    isSelected: [!_isDeficit, _isDeficit],
                    onPressed: (index) {
                      setState(() {
                        _isDeficit = index == 1;
                      });
                      _validateForm();
                    },
                    constraints: const BoxConstraints(
                      minWidth: 52,
                      minHeight: 52,
                    ),
                    selectedColor: colorScheme.onPrimary,
                    fillColor: _isDeficit ? AppColors.error : AppColors.success,
                    color: colorScheme.onSurface,
                    children: [
                      Text(
                        '+',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '−',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.lg),

                // Hours input
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _openingHoursController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: 'h',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Minutes input
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _openingMinutesController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      hintText: '00',
                      suffixText: 'm',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                    ),
                  ),
                ),
              ],
            ),

            if (_openingBalanceError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _openingBalanceError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Helper text
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: AppIconSize.xs,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _isDeficit
                          ? t.contract_deficitExplanation
                          : t.contract_creditExplanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

  Future<void> _selectStartDate(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _trackingStartDate,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365)),
      helpText: t.contract_startTrackingFrom,
    );

    if (picked != null && picked != _trackingStartDate && mounted) {
      setState(() {
        _trackingStartDate = picked;
      });
      _validateForm();
    }
  }
}
