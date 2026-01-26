import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/contract_provider.dart';
import '../config/app_router.dart';
import '../l10n/generated/app_localizations.dart';

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
      _contractPercentController.text = contractProvider.contractPercent.toString();
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
        } else if (fullTimeHours > 168) { // 24 hours * 7 days
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

    // Update provider values if valid
    if (_isFormValid) {
      final contractProvider = context.read<ContractProvider>();
      final contractPercent = int.parse(_contractPercentController.text.trim());
      final fullTimeHours = int.parse(_fullTimeHoursController.text.trim());
      
      // Only update if values have changed to avoid unnecessary notifications
      if (contractProvider.contractPercent != contractPercent) {
        contractProvider.setContractPercent(contractPercent);
      }
      if (contractProvider.fullTimeHours != fullTimeHours) {
        contractProvider.setFullTimeHours(fullTimeHours);
      }
      
      // Update starting balance fields
      if (contractProvider.trackingStartDate != _trackingStartDate) {
        contractProvider.setTrackingStartDate(_trackingStartDate);
      }
      
      final hoursText = _openingHoursController.text.trim();
      final minutesText = _openingMinutesController.text.trim();
      final hours = int.tryParse(hoursText.isEmpty ? '0' : hoursText) ?? 0;
      final minutes = int.tryParse(minutesText.isEmpty ? '0' : minutesText) ?? 0;
      final totalMinutes = (hours * 60) + minutes;
      final signedMinutes = _isDeficit ? -totalMinutes : totalMinutes;
      
      if (contractProvider.openingFlexMinutes != signedMinutes) {
        contractProvider.setOpeningFlexMinutes(signedMinutes);
      }
      
      // Update employer mode
      if (contractProvider.employerMode != _employerMode) {
        contractProvider.setEmployerMode(_employerMode);
      }
    }
  }

  void _saveSettings() {
    final t = AppLocalizations.of(context);
    if (_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.contract_savedSuccess),
          backgroundColor: Colors.green,
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
              _contractPercentController.text = contractProvider.contractPercent.toString();
              _fullTimeHoursController.text = contractProvider.fullTimeHours.toString();
              
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
                  backgroundColor: Colors.blue,
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
                color: _isFormValid ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ContractProvider>(
        builder: (context, contractProvider, child) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.work_outline,
                                color: colorScheme.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                t.contract_headerTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t.contract_headerDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
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
                  
                  const SizedBox(height: 24),
                  
                  // Full-time Hours Field
                  _buildTextField(
                    theme,
                    t.contract_fullTimeHours,
                    _fullTimeHoursController,
                    t.contract_fullTimeHoursHint,
                    suffixText: t.contract_hrsWeek,
                    errorText: _fullTimeHoursError,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  // Employer Mode Dropdown
                  Text(
                    'Employer Mode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.surface,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  const SizedBox(height: 8),
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
                  
                  const SizedBox(height: 32),
                  
                  // Starting Balance Section
                  _buildStartingBalanceSection(theme, colorScheme, contractProvider, t),
                  
                  const SizedBox(height: 32),
                  
                  // Live Preview Card
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.preview,
                                color: colorScheme.secondary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t.contract_livePreview,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          _buildPreviewRow(
                            theme,
                            t.contract_contractType,
                            contractProvider.isFullTime ? t.contract_fullTime : t.contract_partTime,
                            Icons.badge,
                          ),
                          
                          _buildPreviewRow(
                            theme,
                            t.contract_percentage,
                            contractProvider.contractPercentString,
                            Icons.percent,
                          ),
                          
                          _buildPreviewRow(
                            theme,
                            t.contract_fullTimeHours,
                            contractProvider.fullTimeHoursString,
                            Icons.schedule,
                          ),
                          
                          _buildPreviewRow(
                            theme,
                            t.contract_allowedHours,
                            contractProvider.allowedHoursString,
                            Icons.check_circle,
                            isHighlighted: true,
                          ),
                          
                          _buildPreviewRow(
                            theme,
                            t.contract_dailyHours,
                            t.contract_hoursPerDayValue(contractProvider.allowedHoursPerDay.toStringAsFixed(1)),
                            Icons.today,
                          ),
                          
                          const Divider(height: 24),
                          
                          _buildPreviewRow(
                            theme,
                            t.contract_startTrackingFrom,
                            DateFormat('MMM d, yyyy').format(_trackingStartDate),
                            Icons.calendar_today,
                          ),
                          
                          _buildPreviewRow(
                            theme,
                            t.contract_openingBalance,
                            contractProvider.openingFlexFormatted,
                            Icons.account_balance_wallet,
                            isHighlighted: contractProvider.hasOpeningBalance,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetToDefaults,
                          icon: const Icon(Icons.refresh),
                          label: Text(t.contract_resetToDefaults),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isFormValid ? _saveSettings : null,
                          icon: const Icon(Icons.save),
                          label: Text(t.contract_saveSettings),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffixText,
            errorText: errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
              ),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isHighlighted 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
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
      color: colorScheme.tertiaryContainer.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: colorScheme.tertiary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  t.contract_startingBalance,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              t.contract_startingBalanceDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            
            // Start Tracking From Date
            Text(
              t.contract_startTrackingFrom,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectStartDate(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_trackingStartDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit,
                      color: colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Opening Time Balance
            Text(
              t.contract_openingBalance,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Credit/Deficit Toggle
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.surface,
                  ),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(12),
                    isSelected: [!_isDeficit, _isDeficit],
                    onPressed: (index) {
                      setState(() {
                        _isDeficit = index == 1;
                      });
                      _validateForm();
                    },
                    constraints: const BoxConstraints(
                      minWidth: 60,
                      minHeight: 48,
                    ),
                    selectedColor: colorScheme.onPrimary,
                    fillColor: _isDeficit ? Colors.red : Colors.green,
                    color: colorScheme.onSurface,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '+',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '−',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Hours input
                Expanded(
                  child: TextFormField(
                    controller: _openingHoursController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: 'h',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Minutes input
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _openingMinutesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      hintText: '00',
                      suffixText: 'm',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_openingBalanceError != null) ...[
              const SizedBox(height: 8),
              Text(
                _openingBalanceError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Helper text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
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
    
    if (picked != null && picked != _trackingStartDate) {
      setState(() {
        _trackingStartDate = picked;
      });
      _validateForm();
    }
  }
}
