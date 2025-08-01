import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Edit Entry screen for both travel and work entries.
/// Features: Entry type switching, form validation, Material 3 theming.
class EditEntryScreen extends StatefulWidget {
  final String entryId;
  final String? entryType;

  const EditEntryScreen({
    super.key,
    required this.entryId,
    this.entryType,
  });

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Entry type
  late EntryType _currentEntryType;
  
  // Travel form data - now supports multiple travel entries
  final List<_TravelEntry> _travelEntries = [];
  final _travelNotesController = TextEditingController();
  
  // Work form data
  final List<_Shift> _shifts = [];
  final _workNotesController = TextEditingController();
  
  bool _isFormValid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentEntryType = _parseEntryType(widget.entryType);
    _loadEntryData();
    _addFormListeners();
  }

  @override
  void dispose() {
    _travelNotesController.dispose();
    _workNotesController.dispose();
    for (final travelEntry in _travelEntries) {
      travelEntry.dispose();
    }
    for (final shift in _shifts) {
      shift.dispose();
    }
    super.dispose();
  }

  EntryType _parseEntryType(String? type) {
    switch (type?.toLowerCase()) {
      case 'work':
        return EntryType.work;
      case 'travel':
      default:
        return EntryType.travel;
    }
  }

  void _loadEntryData() {
    // TODO: Load actual entry data from Provider
    // For now, load demo data
    if (_currentEntryType == EntryType.travel) {
      // Add sample travel entries to demonstrate multiple entries per day
      _addTravelEntry();
      if (_travelEntries.isNotEmpty) {
        _travelEntries[0].fromController.text = 'Home';
        _travelEntries[0].toController.text = 'Office';
        _travelEntries[0].durationHoursController.text = '0';
        _travelEntries[0].durationMinutesController.text = '25';
      }
      
      // Add a second travel entry to show multiple trips
      _addTravelEntry();
      if (_travelEntries.length > 1) {
        _travelEntries[1].fromController.text = 'Office';
        _travelEntries[1].toController.text = 'Client Meeting';
        _travelEntries[1].durationHoursController.text = '0';
        _travelEntries[1].durationMinutesController.text = '15';
      }
      
      _travelNotesController.text = 'Multiple trips throughout the day';
    } else {
      _addShift();
      if (_shifts.isNotEmpty) {
        _shifts[0].startTimeController.text = '09:00';
        _shifts[0].endTimeController.text = '17:00';
      }
      _workNotesController.text = 'Regular work day at the office';
    }
    _validateForm();
  }

  void _addFormListeners() {
    _travelNotesController.addListener(_validateForm);
    _workNotesController.addListener(_validateForm);
  }

  void _validateForm() {
    setState(() {
      if (_currentEntryType == EntryType.travel) {
        _isFormValid = _travelEntries.isNotEmpty && _travelEntries.every((entry) => entry.isValid);
      } else {
        _isFormValid = _shifts.isNotEmpty && _shifts.every((shift) => shift.isValid);
      }
    });
  }

  void _addTravelEntry() {
    setState(() {
      final travelEntry = _TravelEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        onChanged: _validateForm,
      );
      _travelEntries.add(travelEntry);
      _validateForm();
    });
  }

  void _removeTravelEntry(_TravelEntry travelEntry) {
    setState(() {
      travelEntry.dispose();
      _travelEntries.remove(travelEntry);
      _validateForm();
    });
  }

  void _addShift() {
    setState(() {
      final shift = _Shift(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        onChanged: _validateForm,
      );
      _shifts.add(shift);
      _validateForm();
    });
  }

  void _removeShift(_Shift shift) {
    setState(() {
      shift.dispose();
      _shifts.remove(shift);
      _validateForm();
    });
  }

  void _switchEntryType(EntryType newType) {
    setState(() {
      _currentEntryType = newType;
      _validateForm();
    });
  }

  Future<void> _saveEntry() async {
    if (!_isFormValid || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Save via EntryProvider
      await Future.delayed(const Duration(seconds: 1)); // Simulate save
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entry saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Use AppRouter for safer navigation
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _cancelEdit() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Edit Entry'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancelEdit,
        ),
      ),
      body: Column(
        children: [
          // Entry Type Toggle
          _buildEntryTypeToggle(theme),
          
          // Form Content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _currentEntryType == EntryType.travel
                    ? _buildTravelForm(theme)
                    : _buildWorkForm(theme),
              ),
            ),
          ),
          
          // Bottom Save Bar
          _buildSaveBar(theme),
        ],
      ),
    );
  }

  Widget _buildEntryTypeToggle(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                theme,
                'Travel',
                Icons.directions_car,
                EntryType.travel,
                _currentEntryType == EntryType.travel,
              ),
            ),
            Expanded(
              child: _buildToggleButton(
                theme,
                'Work',
                Icons.work,
                EntryType.work,
                _currentEntryType == EntryType.work,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    ThemeData theme,
    String label,
    IconData icon,
    EntryType type,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _switchEntryType(type),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Travel Entries
        ..._travelEntries.map((travelEntry) => _buildTravelEntryRow(theme, travelEntry)),
        
        // Add Travel Entry Button
        Container(
          width: double.infinity,
          height: 48,
          margin: const EdgeInsets.only(bottom: 24),
          child: OutlinedButton.icon(
            onPressed: _addTravelEntry,
            icon: const Icon(Icons.add),
            label: const Text('Add Travel Entry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
                style: BorderStyle.solid,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        _buildTextField(
          theme,
          'Notes',
          _travelNotesController,
          'Add any additional notes for all travel entries...',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildWorkForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shifts
        ..._shifts.map((shift) => _buildShiftRow(theme, shift)),
        
        // Add Shift Button
        Container(
          width: double.infinity,
          height: 48,
          margin: const EdgeInsets.only(bottom: 24),
          child: OutlinedButton.icon(
            onPressed: _addShift,
            icon: const Icon(Icons.add),
            label: const Text('Add Shift'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
                style: BorderStyle.solid,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        _buildTextField(
          theme,
          'Notes',
          _workNotesController,
          'Add any additional notes...',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildTextField(
    ThemeData theme,
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    String? Function(String?)? validator,
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
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
            filled: true,
            fillColor: theme.colorScheme.surface,
            contentPadding: EdgeInsets.all(maxLines > 1 ? 16 : 16),
          ),
        ),
      ],
    );
  }



  Widget _buildTravelEntryRow(ThemeData theme, _TravelEntry travelEntry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.04),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header with trip number and delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Trip ${_travelEntries.indexOf(travelEntry) + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (_travelEntries.length > 1)
                IconButton(
                  onPressed: () => _removeTravelEntry(travelEntry),
                  icon: const Icon(Icons.delete),
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                    minimumSize: const Size(32, 32),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // From and To fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: travelEntry.fromController,
                      decoration: InputDecoration(
                        hintText: 'Departure location',
                        prefixIcon: const Icon(Icons.my_location, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                margin: const EdgeInsets.only(top: 20),
                child: Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: travelEntry.toController,
                      decoration: InputDecoration(
                        hintText: 'Destination location',
                        prefixIcon: const Icon(Icons.location_on, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Duration fields
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hours',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: travelEntry.durationHoursController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minutes',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: travelEntry.durationMinutesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          travelEntry.formattedDuration,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftRow(ThemeData theme, _Shift shift) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.04),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shift ${_shifts.indexOf(shift) + 1}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              if (_shifts.length > 1)
                IconButton(
                  onPressed: () => _removeShift(shift),
                  icon: const Icon(Icons.delete),
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                    minimumSize: const Size(32, 32),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Time',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: shift.startTimeController,
                      readOnly: true,
                      onTap: () => _selectTime(context, shift.startTimeController),
                      decoration: InputDecoration(
                        hintText: 'Select time',
                        suffixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'to',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Time',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: shift.endTimeController,
                      readOnly: true,
                      onTap: () => _selectTime(context, shift.endTimeController),
                      decoration: InputDecoration(
                        hintText: 'Select time',
                        suffixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : _cancelEdit,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isFormValid && !_isSaving ? _saveEntry : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      controller.text = picked.format(context);
      _validateForm();
    }
  }
}

enum EntryType { travel, work }

class _TravelEntry {
  final String id;
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController durationHoursController;
  final TextEditingController durationMinutesController;
  final VoidCallback onChanged;

  _TravelEntry({
    required this.id,
    required this.onChanged,
  }) : fromController = TextEditingController(),
       toController = TextEditingController(),
       durationHoursController = TextEditingController(),
       durationMinutesController = TextEditingController() {
    fromController.addListener(onChanged);
    toController.addListener(onChanged);
    durationHoursController.addListener(onChanged);
    durationMinutesController.addListener(onChanged);
  }

  bool get isValid {
    final from = fromController.text.trim();
    final to = toController.text.trim();
    final hours = int.tryParse(durationHoursController.text) ?? 0;
    final minutes = int.tryParse(durationMinutesController.text) ?? 0;
    
    return from.isNotEmpty && to.isNotEmpty && (hours > 0 || minutes > 0);
  }

  String get formattedDuration {
    final hours = int.tryParse(durationHoursController.text) ?? 0;
    final minutes = int.tryParse(durationMinutesController.text) ?? 0;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }

  int get totalMinutes {
    final hours = int.tryParse(durationHoursController.text) ?? 0;
    final minutes = int.tryParse(durationMinutesController.text) ?? 0;
    return (hours * 60) + minutes;
  }

  void dispose() {
    fromController.dispose();
    toController.dispose();
    durationHoursController.dispose();
    durationMinutesController.dispose();
  }
}

class _Shift {
  final String id;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final VoidCallback onChanged;

  _Shift({
    required this.id,
    required this.onChanged,
  }) : startTimeController = TextEditingController(),
       endTimeController = TextEditingController() {
    startTimeController.addListener(onChanged);
    endTimeController.addListener(onChanged);
  }

  bool get isValid {
    return startTimeController.text.isNotEmpty && endTimeController.text.isNotEmpty;
  }

  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
  }
}