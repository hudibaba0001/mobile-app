import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../widgets/location_selector.dart';
import '../services/supabase_auth_service.dart';
import '../services/map_service.dart';
import '../services/holiday_service.dart';
import 'package:flutter/foundation.dart';
import '../widgets/keyboard_aware_form_container.dart';
import '../l10n/generated/app_localizations.dart';

/// Unified entry form for both travel and work entries
/// Provides appropriate fields based on entry type
class UnifiedEntryForm extends StatefulWidget {
  final EntryType entryType;
  final Entry? existingEntry;
  final VoidCallback? onSaved;

  const UnifiedEntryForm({
    super.key,
    required this.entryType,
    this.existingEntry,
    this.onSaved,
  });

  @override
  State<UnifiedEntryForm> createState() => _UnifiedEntryFormState();
}

class _UnifiedEntryFormState extends State<UnifiedEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  // Common fields
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  int _durationMinutes = 0;

  // Travel-specific fields
  String? _departureLocation;
  String? _arrivalLocation;

  // Work-specific fields
  String? _workLocation;
  Shift? _shift;

  String? get _currentUserId =>
      context.read<SupabaseAuthService>().currentUser?.id;

  bool _isLoading = false;
  bool _isCalculatingTravelTime = false;
  String? _travelTimeError;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _selectedDate = entry.date;
      _durationMinutes = entry.minutes ?? 0;
      _notesController.text = entry.notes ?? '';

      if (entry.type == EntryType.travel) {
        _departureLocation = entry.departureLocation;
        _arrivalLocation = entry.arrivalLocation;
        // For travel entries, set start time to current time (not used for saving, just for display if needed)
        _startTime = TimeOfDay.now();
      } else if (entry.type == EntryType.work) {
        // Initialize work fields from first shift if present
        final Shift? firstShift = entry.shift;
        _workLocation = firstShift?.location ?? entry.workLocation;
        if (firstShift != null) {
          _selectedDate = DateTime(
            firstShift.start.year,
            firstShift.start.month,
            firstShift.start.day,
          );
          _startTime = TimeOfDay.fromDateTime(firstShift.start);
          _endTime = TimeOfDay.fromDateTime(firstShift.end);
        } else {
          _startTime = TimeOfDay.fromDateTime(entry.date);
        }
      } else {
        _startTime = TimeOfDay.fromDateTime(entry.date);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTravel = widget.entryType == EntryType.travel;

    return KeyboardAwareFormContainer(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isTravel ? Icons.directions_car : Icons.work,
                    color: isTravel
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isTravel
                        ? AppLocalizations.of(context)!.entry_logTravelEntry
                        : AppLocalizations.of(context)!.entry_logWorkEntry,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date and Time Section
              isTravel
                  ? _buildTravelDateAndTimesSection(theme)
                  : _buildWorkDateAndTimesSection(theme),

              // Holiday Notice (if date is a public holiday)
              _buildHolidayNotice(theme),
              const SizedBox(height: 20),

              // Location Section
              if (isTravel) _buildTravelLocationSection(theme),
              if (!isTravel) _buildWorkLocationSection(theme),
              const SizedBox(height: 20),

              // Duration Section: for Travel only (manual minutes when no end time)
              if (isTravel) _buildDurationSection(theme),
              const SizedBox(height: 20),

              // Work-specific fields
              if (!isTravel) _buildWorkSpecificFields(theme),

              // Notes Section
              _buildNotesSection(theme),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(theme),

              // End padding handled via container padding
            ],
          ),
        ),
      ),
    );
  }

  // Removed unused _buildDateTimeSection

  Widget _buildTravelDateAndTimesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.entry_date,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkDateAndTimesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.form_dateTime,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectStartTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.play_arrow,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _startTime.format(context),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectEndTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.stop,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _endTime != null
                            ? _endTime!.format(context)
                            : AppLocalizations.of(context)!.entry_endTime,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHolidayNotice(ThemeData theme) {
    final holidayService = context.watch<HolidayService>();
    final redDayInfo = holidayService.getRedDayInfo(_selectedDate);

    if (!redDayInfo.isRedDay) {
      return const SizedBox.shrink();
    }

    final isWorkEntry = widget.entryType == EntryType.work;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Show badges
              ...redDayInfo.badges.map((badge) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badge == 'Auto'
                            ? Colors.red.shade600
                            : Colors.purple.shade600,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (redDayInfo.isAutoHoliday)
                      Text(
                        redDayInfo.autoHolidayName ?? AppLocalizations.of(context)!.entry_publicHoliday,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade800,
                        ),
                      ),
                    if (redDayInfo.personalRedDay != null)
                      Text(
                        redDayInfo.personalRedDay!.kindDisplayText +
                            (redDayInfo.personalRedDay!.reason != null
                                ? ' - ${redDayInfo.personalRedDay!.reason}'
                                : ''),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.purple.shade700,
                        ),
                      ),
                    if (redDayInfo.isAutoHoliday &&
                        redDayInfo.personalRedDay == null)
                      Text(
                        AppLocalizations.of(context)!.entry_publicHolidaySweden,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              Tooltip(
                message: redDayInfo.tooltip,
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
          // Show work-specific notice
          if (isWorkEntry) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.work_outline,
                      size: 18, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.entry_redDayWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.form_travelRoute,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        LocationSelector(
          labelText: AppLocalizations.of(context)!.entry_from,
          hintText: AppLocalizations.of(context)!.entry_fromHint,
          initialValue: _departureLocation,
          onLocationSelected: (location) {
            setState(() {
              _departureLocation = location;
              _travelTimeError = null; // Clear error when location changes
            });
          },
          prefixIcon: Icons.my_location,
        ),
        const SizedBox(height: 12),
        LocationSelector(
          labelText: AppLocalizations.of(context)!.entry_to,
          hintText: AppLocalizations.of(context)!.entry_toHint,
          initialValue: _arrivalLocation,
          onLocationSelected: (location) {
            setState(() {
              _arrivalLocation = location;
              _travelTimeError = null; // Clear error when location changes
            });
          },
          prefixIcon: Icons.location_on,
        ),
        const SizedBox(height: 12),
        // Calculate Travel Time Button
        if (_departureLocation != null &&
            _departureLocation!.isNotEmpty &&
            _arrivalLocation != null &&
            _arrivalLocation!.isNotEmpty)
          OutlinedButton.icon(
            onPressed: _isCalculatingTravelTime ? null : _calculateTravelTime,
            icon: _isCalculatingTravelTime
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.directions_car),
            label: Text(_isCalculatingTravelTime
                ? AppLocalizations.of(context)!.entry_calculating
                : AppLocalizations.of(context)!.entry_calculateTravelTime),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        if (_travelTimeError != null) ...[
          const SizedBox(height: 8),
          Text(
            _travelTimeError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _calculateTravelTime() async {
    if (_departureLocation == null ||
        _departureLocation!.isEmpty ||
        _arrivalLocation == null ||
        _arrivalLocation!.isEmpty) {
      return;
    }

    setState(() {
      _isCalculatingTravelTime = true;
      _travelTimeError = null;
    });

    try {
      final result = await MapService.calculateTravelTime(
        origin: _departureLocation!,
        destination: _arrivalLocation!,
      );

      final durationMinutes = result['durationMinutes'] as int;
      final durationText = result['durationText'] as String;
      final distanceText = result['distanceText'] as String;

      setState(() {
        _durationMinutes = durationMinutes;
        // Calculate end time based on start time and duration
        final startDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _startTime.hour,
          _startTime.minute,
        );
        final endDateTime =
            startDateTime.add(Duration(minutes: durationMinutes));
        _endTime = TimeOfDay.fromDateTime(endDateTime);
        _isCalculatingTravelTime = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.entry_travelTimeCalculated(durationText, distanceText),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCalculatingTravelTime = false;
        _travelTimeError = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_calculatingTravelTime(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildWorkLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.form_workLocation,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        LocationSelector(
          labelText: AppLocalizations.of(context)!.entry_location,
          hintText: AppLocalizations.of(context)!.entry_locationHint,
          initialValue: _workLocation,
          onLocationSelected: (location) =>
              setState(() => _workLocation = location),
          prefixIcon: Icons.work,
        ),
      ],
    );
  }

  Widget _buildDurationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.entry_duration,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _durationMinutes > 0
                    ? (_durationMinutes ~/ 60).toString()
                    : '',
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.entry_hours,
                  border: const OutlineInputBorder(),
                  suffixText: 'h',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final hours = int.tryParse(value) ?? 0;
                  final minutes = _durationMinutes % 60;
                  setState(() => _durationMinutes = (hours * 60) + minutes);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: _durationMinutes > 0
                    ? (_durationMinutes % 60).toString()
                    : '',
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.entry_minutes,
                  border: const OutlineInputBorder(),
                  suffixText: 'm',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final hours = _durationMinutes ~/ 60;
                  final minutes = int.tryParse(value) ?? 0;
                  setState(() => _durationMinutes = (hours * 60) + minutes);
                },
              ),
            ),
          ],
        ),
        if (_durationMinutes > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              AppLocalizations.of(context)!.entry_total(_formatDuration(_durationMinutes)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWorkSpecificFields(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.form_workDetails,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _shift?.description,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.entry_shift,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.schedule),
          ),
          items: Shift.values.map((shiftType) {
            return DropdownMenuItem(
              value: shiftType,
              child: Text(_getShiftDisplayName(shiftType)),
            );
          }).toList(),
          onChanged: (shiftType) {
            if (shiftType != null) {
              // Create a basic shift for the selected type
              final now = DateTime.now();
              final shift = Shift(
                start: now,
                end: now.add(const Duration(hours: 8)),
                description: shiftType,
                location: _workLocation,
              );
              setState(() => _shift = shift);
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.entry_notes,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.entry_notesHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.note),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(t.common_cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _isLoading ? null : _saveEntry,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(t.entry_saveEntry),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _selectEndTime() async {
    final initial =
        _endTime ?? _startTime.replacing(minute: (_startTime.minute + 30) % 60);
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('en', 'US'),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          ),
        );
      },
    );
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  Future<void> _saveEntry() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields
    if (widget.entryType == EntryType.travel) {
      if (_departureLocation == null || _arrivalLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_selectBothLocations),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      if (_workLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_selectWorkLocation),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_selectEndTime),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // For Work: duration is derived from start/end; no manual minutes required

    setState(() => _isLoading = true);

    try {
      if (_currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_signInRequired),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final entryProvider = context.read<EntryProvider>();

      // For travel entries, use date only (no time). For work entries, include time.
      final entryDateTime = widget.entryType == EntryType.travel
          ? DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
            )
          : DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _startTime.hour,
              _startTime.minute,
            );

      // For travel entries, use calculated duration or manual duration input
      int? finalTravelMinutes;
      if (widget.entryType == EntryType.travel) {
        // Use calculated duration (from Mapbox API) or manual duration input
        finalTravelMinutes = _durationMinutes > 0 ? _durationMinutes : null;
      }

      // Check if this is holiday work (work entry on a red day - auto or personal)
      final holidayService = context.read<HolidayService>();
      final redDayInfo = holidayService.getRedDayInfo(_selectedDate);
      final isHolidayWork =
          widget.entryType == EntryType.work && redDayInfo.isRedDay;
      // Get holiday name (prefer auto holiday name, fallback to personal reason)
      final holidayName = redDayInfo.autoHolidayName ??
          redDayInfo.personalRedDay?.reason ??
          (redDayInfo.personalRedDay != null ? AppLocalizations.of(context)!.entry_personalRedDay : null);

      final entry = Entry(
        id: widget.existingEntry?.id, // Let Entry model generate UUID if null
        userId: _currentUserId!,
        type: widget.entryType,
        date: entryDateTime,
        from: widget.entryType == EntryType.travel ? _departureLocation : null,
        to: widget.entryType == EntryType.travel ? _arrivalLocation : null,
        travelMinutes: finalTravelMinutes,
        shifts: widget.entryType == EntryType.work
            ? [
                Shift(
                  start: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _startTime.hour,
                    _startTime.minute,
                  ),
                  end: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _endTime!.hour,
                    _endTime!.minute,
                  ),
                  description: _shift?.description,
                  location: _workLocation,
                ),
              ]
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        isHolidayWork: isHolidayWork,
        holidayName: isHolidayWork ? holidayName : null,
      );

      if (widget.existingEntry != null) {
        await entryProvider.updateEntry(entry);
      } else {
        await entryProvider.addEntry(entry);
      }

      if (kDebugMode) {
        print('✅ UnifiedEntryForm: Saved ${entry.type} entry');
        print('✅ UnifiedEntryForm: Entry ID: ${entry.id}');
        print('✅ UnifiedEntryForm: Duration: ${entry.totalDuration}');
        print('✅ UnifiedEntryForm: Work Duration: ${entry.workDuration}');
        print('✅ UnifiedEntryForm: Travel Duration: ${entry.travelDuration}');
        print('✅ UnifiedEntryForm: Shifts count: ${entry.shifts?.length ?? 0}');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.entryType == EntryType.travel ? 'Travel' : 'Work'} entry ${widget.existingEntry != null ? 'updated' : 'saved'} successfully! 🎉',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_savingEntry(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }

  String _getShiftDisplayName(String shiftType) {
    final t = AppLocalizations.of(context)!;
    switch (shiftType) {
      case 'morning':
        return t.shift_morning;
      case 'afternoon':
        return t.shift_afternoon;
      case 'evening':
        return t.shift_evening;
      case 'night':
        return t.shift_night;
      default:
        return t.shift_unknown;
    }
  }
}
