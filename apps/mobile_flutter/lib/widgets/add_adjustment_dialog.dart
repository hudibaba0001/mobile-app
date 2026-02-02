import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/balance_adjustment.dart';
import '../providers/balance_adjustment_provider.dart';
import '../l10n/generated/app_localizations.dart';

/// Dialog for adding or editing a balance adjustment
class AddAdjustmentDialog extends StatefulWidget {
  final BalanceAdjustment? existingAdjustment;

  const AddAdjustmentDialog({
    super.key,
    this.existingAdjustment,
  });

  @override
  State<AddAdjustmentDialog> createState() => _AddAdjustmentDialogState();
}

class _AddAdjustmentDialogState extends State<AddAdjustmentDialog> {
  late DateTime _selectedDate;
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isCredit = true; // true = +, false = -
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.existingAdjustment != null;

  @override
  void initState() {
    super.initState();
    
    if (widget.existingAdjustment != null) {
      final adj = widget.existingAdjustment!;
      _selectedDate = adj.effectiveDate;
      _isCredit = adj.deltaMinutes >= 0;
      final absMinutes = adj.deltaMinutes.abs();
      _hoursController.text = (absMinutes ~/ 60).toString();
      _minutesController.text = (absMinutes % 60).toString().padLeft(2, '0');
      _noteController.text = adj.note ?? '';
    } else {
      _selectedDate = DateTime.now();
      _hoursController.text = '0';
      _minutesController.text = '00';
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Adjustment effective date',
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    // Validate
    final hoursText = _hoursController.text.trim();
    final minutesText = _minutesController.text.trim();
    
    final hours = int.tryParse(hoursText.isEmpty ? '0' : hoursText) ?? 0;
    final minutes = int.tryParse(minutesText.isEmpty ? '0' : minutesText) ?? 0;
    
    if (hours == 0 && minutes == 0) {
      setState(() => _error = t.adjustment_enterAmount);
      return;
    }
    
    if (minutes < 0 || minutes >= 60) {
      setState(() => _error = t.contract_minutesError);
      return;
    }
    
    final totalMinutes = (hours * 60) + minutes;
    final deltaMinutes = _isCredit ? totalMinutes : -totalMinutes;
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    
    setState(() {
      _isSaving = true;
      _error = null;
    });
    
    try {
      final provider = context.read<BalanceAdjustmentProvider>();
      
      if (_isEditing) {
        await provider.updateAdjustment(
          id: widget.existingAdjustment!.id!,
          effectiveDate: _selectedDate,
          deltaMinutes: deltaMinutes,
          note: note,
        );
      } else {
        await provider.addAdjustment(
          effectiveDate: _selectedDate,
          deltaMinutes: deltaMinutes,
          note: note,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _error = t.adjustment_failedToSave(e.toString());
        _isSaving = false;
      });
    }
  }

  Future<void> _delete() async {
    final t = AppLocalizations.of(context);
    if (!_isEditing || widget.existingAdjustment?.id == null) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.adjustment_deleteTitle),
        content: Text(t.adjustment_deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.common_delete),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      setState(() => _isSaving = true);
      
      try {
        final provider = context.read<BalanceAdjustmentProvider>();
        await provider.deleteAdjustment(
          widget.existingAdjustment!.id!,
          _selectedDate.year,
        );
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        setState(() {
          _error = t.adjustment_failedToDelete(e.toString());
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMMM d, yyyy');

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.tune,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(_isEditing ? t.adjustment_editAdjustment : t.adjustment_addAdjustment)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            Text(
              t.adjustment_effectiveDate,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(dateFormat.format(_selectedDate)),
                    const Spacer(),
                    Icon(Icons.edit, size: 18, color: colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Amount input
            Text(
              t.adjustment_amount,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // +/- Toggle
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ToggleButtons(
                    borderRadius: BorderRadius.circular(12),
                    isSelected: [_isCredit, !_isCredit],
                    onPressed: (index) {
                      setState(() {
                        _isCredit = index == 0;
                      });
                    },
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    selectedColor: colorScheme.onPrimary,
                    fillColor: _isCredit ? Colors.green : Colors.red,
                    color: colorScheme.onSurface,
                    children: [
                      Text('+', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text('−', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Hours
                Expanded(
                  child: TextField(
                    controller: _hoursController,
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
                
                // Minutes
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _minutesController,
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
            
            const SizedBox(height: 20),
            
            // Note
            Text(
              t.form_notesOptional,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: t.adjustment_noteHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_isEditing)
          TextButton(
            onPressed: _isSaving ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(t.common_delete),
          ),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(t.common_cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? t.adjustment_update : t.common_add),
        ),
      ],
    );
  }
}
