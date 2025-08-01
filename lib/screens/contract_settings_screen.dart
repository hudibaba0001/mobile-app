import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/contract_provider.dart';
import '../config/app_router.dart';

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
  
  bool _isFormValid = false;
  String? _contractPercentError;
  String? _fullTimeHoursError;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current provider values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contractProvider = context.read<ContractProvider>();
      _contractPercentController.text = contractProvider.contractPercent.toString();
      _fullTimeHoursController.text = contractProvider.fullTimeHours.toString();
      _validateForm();
    });
    
    // Add listeners for real-time validation
    _contractPercentController.addListener(_validateForm);
    _fullTimeHoursController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _contractPercentController.dispose();
    _fullTimeHoursController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      // Validate contract percentage
      final contractPercentText = _contractPercentController.text.trim();
      if (contractPercentText.isEmpty) {
        _contractPercentError = 'Contract percentage is required';
      } else {
        final contractPercent = int.tryParse(contractPercentText);
        if (contractPercent == null) {
          _contractPercentError = 'Please enter a valid number';
        } else if (contractPercent < 0 || contractPercent > 100) {
          _contractPercentError = 'Percentage must be between 0 and 100';
        } else {
          _contractPercentError = null;
        }
      }

      // Validate full-time hours
      final fullTimeHoursText = _fullTimeHoursController.text.trim();
      if (fullTimeHoursText.isEmpty) {
        _fullTimeHoursError = 'Full-time hours is required';
      } else {
        final fullTimeHours = int.tryParse(fullTimeHoursText);
        if (fullTimeHours == null) {
          _fullTimeHoursError = 'Please enter a valid number';
        } else if (fullTimeHours <= 0) {
          _fullTimeHoursError = 'Hours must be greater than 0';
        } else if (fullTimeHours > 168) { // 24 hours * 7 days
          _fullTimeHoursError = 'Hours cannot exceed 168 per week';
        } else {
          _fullTimeHoursError = null;
        }
      }

      // Form is valid if both fields have no errors
      _isFormValid = _contractPercentError == null && _fullTimeHoursError == null;
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
    }
  }

  void _saveSettings() {
    if (_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contract settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      AppRouter.goBackOrHome(context);
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('This will reset your contract settings to 100% full-time with 40 hours per week. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final contractProvider = context.read<ContractProvider>();
              contractProvider.resetToDefaults();
              _contractPercentController.text = contractProvider.contractPercent.toString();
              _fullTimeHoursController.text = contractProvider.fullTimeHours.toString();
              _validateForm();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contract settings reset to defaults'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Contract Settings'),
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
              'Save',
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
                                'Contract Settings',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Configure your contract percentage and full-time hours for accurate work time tracking and overtime calculations.',
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
                    'Contract Percentage',
                    _contractPercentController,
                    'Enter percentage (0-100)',
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
                    'Full-time Hours per Week',
                    _fullTimeHoursController,
                    'Enter hours per week (e.g., 40)',
                    suffixText: 'hrs/week',
                    errorText: _fullTimeHoursError,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                  ),
                  
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
                                'Live Preview',
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
                            'Contract Type',
                            contractProvider.isFullTime ? 'Full-time' : 'Part-time',
                            Icons.badge,
                          ),
                          
                          _buildPreviewRow(
                            theme,
                            'Contract Percentage',
                            contractProvider.contractPercentString,
                            Icons.percent,
                          ),
                          
                          _buildPreviewRow(
                            theme,
                            'Full-time Hours',
                            contractProvider.fullTimeHoursString,
                            Icons.schedule,
                          ),
                          
                          _buildPreviewRow(
                            theme,
                            'Allowed Hours',
                            contractProvider.allowedHoursString,
                            Icons.check_circle,
                            isHighlighted: true,
                          ),
                          
                          _buildPreviewRow(
                            theme,
                            'Daily Hours',
                            '${contractProvider.allowedHoursPerDay.toStringAsFixed(1)} hours/day',
                            Icons.today,
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
                          label: const Text('Reset to Defaults'),
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
                          label: const Text('Save Settings'),
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
}