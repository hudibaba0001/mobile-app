// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/entry.dart';
import '../providers/entry_provider.dart';
import '../widgets/location_selector.dart';
import '../services/supabase_auth_service.dart';
import '../services/map_service.dart';
import '../services/holiday_service.dart';
import '../widgets/keyboard_aware_form_container.dart';
import '../l10n/generated/app_localizations.dart';
import '../design/app_theme.dart';
import '../design/design.dart';

/// Unified entry form for both travel and work entries
/// Provides appropriate fields based on entry type
class UnifiedEntryForm extends StatefulWidget {
  final EntryType entryType;
  final Entry? existingEntry;
  final VoidCallback? onSaved;
  final DateTime? initialDate; // Optional initial date for create mode

  const UnifiedEntryForm({
    super.key,
    required this.entryType,
    this.existingEntry,
    this.onSaved,
    this.initialDate,
  });

  @override
  State<UnifiedEntryForm> createState() => _UnifiedEntryFormState();
}

class _UnifiedEntryFormState extends State<UnifiedEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _durationHoursController = TextEditingController();
  final _durationMinutesController = TextEditingController();

  // Common fields
  DateTime _selectedDate = DateTime.now();
  int _durationMinutes = 0;

  // Travel-specific fields (legacy single travel - kept for backward compatibility)
  String? _departureLocation;
  String? _arrivalLocation;

  // Travel legs (new multi-leg support)
  List<TravelLeg> _travelLegs = [];
  final Map<int, bool> _isCalculatingLeg = {}; // Track which leg is calculating
  final Map<int, String?> _legErrors = {}; // Track errors per leg
  final Map<int, TextEditingController> _legMinutesControllers = {};
  final Map<int, TextEditingController> _legHoursControllers = {};
  final Map<int, TextEditingController> _legNotesControllers = {};

  // Work-specific fields
  String? _workLocation;
  List<Shift> _shifts = [];
  bool _useLocationForAllShifts = true; // Default ON
  final Map<int, TextEditingController> _shiftNotesControllers = {};
  final Map<int, TextEditingController> _shiftBreakControllers = {};

  String? get _currentUserId =>
      context.read<SupabaseAuthService>().currentUser?.id;

  bool get _isEditMode => widget.existingEntry != null;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _selectedDate = entry.date;
      _notesController.text = entry.notes ?? '';
    } else if (widget.initialDate != null) {
      // Use provided initial date for create mode
      _selectedDate = widget.initialDate!;
    } else {
      // Default to today
      _selectedDate = DateTime.now();
    }

    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;

      if (entry.type == EntryType.travel) {
        // Prefer travelLegs if available, otherwise use legacy single travel
        if (entry.travelLegs != null && entry.travelLegs!.isNotEmpty) {
          // In edit mode, only show first leg (atomic entry = 1 leg)
          if (_isEditMode) {
            _travelLegs = [entry.travelLegs!.first];
          } else {
            _travelLegs = List<TravelLeg>.from(entry.travelLegs!);
          }
          // Initialize controllers for each leg
          for (var i = 0; i < _travelLegs.length; i++) {
            final leg = _travelLegs[i];
            _legHoursControllers[i] = TextEditingController(
              text: leg.minutes > 0 ? (leg.minutes ~/ 60).toString() : '',
            );
            _legMinutesControllers[i] = TextEditingController(
              text: leg.minutes > 0 ? (leg.minutes % 60).toString() : '',
            );
          }
          // In edit mode, the entry's notes belong to this leg
          if (entry.notes != null && entry.notes!.isNotEmpty) {
            _legNotesControllers[0] = TextEditingController(text: entry.notes);
          }
        } else {
          // Legacy single travel - convert to travelLegs
          _departureLocation = entry.from;
          _arrivalLocation = entry.to;
          _durationMinutes = entry.travelMinutes ?? 0;
          _updateDurationControllers();

          if (_departureLocation != null &&
              _arrivalLocation != null &&
              _durationMinutes > 0) {
            _travelLegs = [
              TravelLeg(
                fromText: _departureLocation!,
                toText: _arrivalLocation!,
                minutes: _durationMinutes,
                source: 'manual',
              ),
            ];
            _legHoursControllers[0] = TextEditingController(
              text: _durationMinutes > 0
                  ? (_durationMinutes ~/ 60).toString()
                  : '',
            );
            _legMinutesControllers[0] = TextEditingController(
              text: _durationMinutes > 0
                  ? (_durationMinutes % 60).toString()
                  : '',
            );
            if (entry.notes != null && entry.notes!.isNotEmpty) {
              _legNotesControllers[0] =
                  TextEditingController(text: entry.notes);
            }
          }
        }
      } else if (entry.type == EntryType.work) {
        // Initialize work fields from existing shifts if present
        if (entry.shifts != null && entry.shifts!.isNotEmpty) {
          _shifts = List<Shift>.from(entry.shifts!);
          final firstShift = _shifts.first;
          _workLocation = firstShift.location ?? entry.workLocation;

          // Check if all shifts have the same location (determines toggle state)
          final allSameLocation =
              _shifts.every((s) => s.location == _workLocation);
          _useLocationForAllShifts = allSameLocation && _workLocation != null;

          // Initialize shift notes controllers
          for (var i = 0; i < _shifts.length; i++) {
            _shiftNotesControllers[i] =
                TextEditingController(text: _shifts[i].notes ?? '');
            _shiftBreakControllers[i] = TextEditingController(
              text: _shifts[i].unpaidBreakMinutes.toString(),
            );
          }

          _selectedDate = DateTime(
            firstShift.start.year,
            firstShift.start.month,
            firstShift.start.day,
          );
        }
      }
    } else {
      // Add one default shift for new work entries
      if (widget.entryType == EntryType.work) {
        _addShift();
        // Initialize notes controller for the default shift
        _shiftNotesControllers[0] = TextEditingController();
        _shiftBreakControllers[0] = TextEditingController(text: '0');
      } else if (widget.entryType == EntryType.travel) {
        // Add one default travel leg for new travel entries
        _addTravelLeg();
      }
    }
  }

  void _updateDurationControllers() {
    _durationHoursController.text =
        _durationMinutes > 0 ? (_durationMinutes ~/ 60).toString() : '';
    _durationMinutesController.text =
        _durationMinutes > 0 ? (_durationMinutes % 60).toString() : '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _durationHoursController.dispose();
    _durationMinutesController.dispose();
    for (final controller in _shiftNotesControllers.values) {
      controller.dispose();
    }
    _shiftNotesControllers.clear();
    for (final controller in _shiftBreakControllers.values) {
      controller.dispose();
    }
    _shiftBreakControllers.clear();
    for (final controller in _legMinutesControllers.values) {
      controller.dispose();
    }
    _legMinutesControllers.clear();
    for (final controller in _legHoursControllers.values) {
      controller.dispose();
    }
    _legHoursControllers.clear();
    for (final controller in _legNotesControllers.values) {
      controller.dispose();
    }
    _legNotesControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTravel = widget.entryType == EntryType.travel;

    return KeyboardAwareFormContainer(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    isTravel
                        ? AppLocalizations.of(context).entry_logTravelEntry
                        : AppLocalizations.of(context).entry_logWorkEntry,
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
              const SizedBox(height: AppSpacing.lg),

              // Date and Time Section
              isTravel
                  ? _buildTravelDateAndTimesSection(theme)
                  : _buildWorkDateAndTimesSection(theme),

              // Holiday Notice (if date is a public holiday)
              _buildHolidayNotice(theme),
              const SizedBox(height: AppSpacing.md),

              // Location Section: for Travel (multiple legs)
              if (isTravel) _buildTravelLegsSection(theme),
              if (!isTravel) _buildWorkLocationSection(theme),
              const SizedBox(height: AppSpacing.md),

              // Work-specific fields
              ...(!isTravel ? _buildWorkSpecificFields(theme) : []),

              // (Travel uses per-leg notes inside each card; work uses per-shift notes)

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
          AppLocalizations.of(context).entry_date,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        DateFormat.yMMMd().format(_selectedDate),
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
          AppLocalizations.of(context).form_dateTime,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        DateFormat.yMMMd().format(_selectedDate),
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
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.errorContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Show badges
              ...redDayInfo.badges.map((badge) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm - 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badge == 'Auto'
                            ? AppColors.error
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(AppRadius.sm / 2),
                      ),
                      child: Text(
                        badge,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.neutral50,
                        ),
                      ),
                    ),
                  )),
              const SizedBox(width: AppSpacing.sm - 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (redDayInfo.isAutoHoliday)
                      Text(
                        redDayInfo.autoHolidayName ??
                            AppLocalizations.of(context).entry_publicHoliday,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    if (redDayInfo.personalRedDay != null)
                      Text(
                        redDayInfo.personalRedDay!.kindDisplayText +
                            (redDayInfo.personalRedDay!.reason != null
                                ? ' - ${redDayInfo.personalRedDay!.reason}'
                                : ''),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    if (redDayInfo.isAutoHoliday &&
                        redDayInfo.personalRedDay == null)
                      Text(
                        AppLocalizations.of(context).entry_publicHolidaySweden,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
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
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          // Show work-specific notice
          if (isWorkEntry) ...[
            const SizedBox(height: AppSpacing.md - 2),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md - 2),
              decoration: BoxDecoration(
                color: AppColors.accentContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                border: Border.all(color: AppColors.accentLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.work_outline,
                      size: 18, color: AppColors.accentDark),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).entry_redDayWarning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.accentDark,
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

  Widget _buildTravelLegsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).form_travelRoute,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Travel legs
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: Column(
            children: _travelLegs.asMap().entries.map((entry) {
              final index = entry.key;
              final leg = entry.value;
              return _buildTravelLegCard(theme, index, leg);
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Add Another Travel button
        OutlinedButton.icon(
          onPressed: _addTravelLeg,
          icon: const Icon(Icons.add),
          label: Text(_travelLegs.isEmpty
              ? AppLocalizations.of(context).travel_addLeg
              : AppLocalizations.of(context).travel_addAnotherLeg),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        if (_isEditMode && _travelLegs.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).entry_travelLegUpdateNotice,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTravelLegCard(ThemeData theme, int index, TravelLeg leg) {
    final t = AppLocalizations.of(context);
    final isCalculating = _isCalculatingLeg[index] ?? false;
    final error = _legErrors[index];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leg header
            Row(
              children: [
                Text(
                  t.travel_legLabel(index + 1),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Remove button only in create mode and if more than one leg
                if (!_isEditMode && _travelLegs.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _removeTravelLeg(index),
                    tooltip: t.travel_removeLeg,
                  ),
                // Source badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: leg.source == 'auto'
                        ? FlexsaldoColors.positiveLight
                        : AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: leg.source == 'auto'
                          ? FlexsaldoColors.positiveLight
                          : AppColors.primaryContainer,
                    ),
                  ),
                  child: Text(
                    leg.source == 'auto'
                        ? t.travel_sourceAuto
                        : t.travel_sourceManual,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: leg.source == 'auto'
                          ? FlexsaldoColors.positiveDark
                          : AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Remove button only in create mode and if more than one leg
                if (!_isEditMode && _travelLegs.length > 1) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _removeTravelLeg(index),
                    tooltip: t.common_delete,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // From location
            LocationSelector(
              labelText: AppLocalizations.of(context).entry_from,
              hintText: AppLocalizations.of(context).entry_fromHint,
              initialValue: leg.fromText,
              onLocationSelected: (location) {
                setState(() {
                  _travelLegs[index] = leg.copyWith(fromText: location);
                  _legErrors.remove(index); // Clear error
                });
              },
              onLocationObjectSelected: (locationObj) {
                // Capture placeId if available (for better caching)
                if (locationObj != null) {
                  setState(() {
                    _travelLegs[index] = leg.copyWith(
                      fromText: locationObj.address,
                      fromPlaceId: locationObj.id, // Use location ID as placeId
                    );
                  });
                }
              },
              prefixIcon: Icons.my_location,
            ),
            const SizedBox(height: AppSpacing.md),

            // To location
            LocationSelector(
              labelText: AppLocalizations.of(context).entry_to,
              hintText: AppLocalizations.of(context).entry_toHint,
              initialValue: leg.toText,
              onLocationSelected: (location) {
                setState(() {
                  _travelLegs[index] = leg.copyWith(toText: location);
                  _legErrors.remove(index); // Clear error
                });
              },
              onLocationObjectSelected: (locationObj) {
                // Capture placeId if available (for better caching)
                if (locationObj != null) {
                  setState(() {
                    _travelLegs[index] = leg.copyWith(
                      toText: locationObj.address,
                      toPlaceId: locationObj.id, // Use location ID as placeId
                    );
                  });
                }
              },
              prefixIcon: Icons.location_on,
            ),
            const SizedBox(height: AppSpacing.md),

            // Duration input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _legHoursControllers[index] ??=
                        TextEditingController(
                      text:
                          leg.minutes > 0 ? (leg.minutes ~/ 60).toString() : '',
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).entry_hours,
                      border: const OutlineInputBorder(),
                      suffixText: 'h',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final hours = int.tryParse(value) ?? 0;
                      final minutes = int.tryParse(
                              _legMinutesControllers[index]?.text ?? '') ??
                          0;
                      final totalMinutes = (hours * 60) + minutes;
                      setState(() {
                        _travelLegs[index] =
                            leg.copyWith(minutes: totalMinutes);
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _legMinutesControllers[index] ??=
                        TextEditingController(
                      text:
                          leg.minutes > 0 ? (leg.minutes % 60).toString() : '',
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).entry_minutes,
                      border: const OutlineInputBorder(),
                      suffixText: 'm',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final hours = int.tryParse(
                              _legHoursControllers[index]?.text ?? '') ??
                          0;
                      final minutes = int.tryParse(value) ?? 0;
                      final totalMinutes = (hours * 60) + minutes;
                      setState(() {
                        _travelLegs[index] =
                            leg.copyWith(minutes: totalMinutes);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Calculate button
            if (leg.fromText.isNotEmpty && leg.toText.isNotEmpty)
              OutlinedButton.icon(
                onPressed:
                    isCalculating ? null : () => _calculateTravelLeg(index),
                icon: isCalculating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.directions_car),
                label: Text(isCalculating
                    ? AppLocalizations.of(context).entry_calculating
                    : AppLocalizations.of(context).entry_calculateTravelTime),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),

            // Error message
            if (error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            // Per-leg notes
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _legNotesControllers[index] ??=
                  TextEditingController(),
              decoration: InputDecoration(
                hintText: t.entry_notesHint,
                labelText: t.entry_notes,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note_outlined),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  void _addTravelLeg() {
    HapticFeedback.lightImpact();
    setState(() {
      final previousLeg = _travelLegs.isNotEmpty ? _travelLegs.last : null;
      final newIndex = _travelLegs.length;

      // Auto-copy previous leg's "to" to new leg's "from"
      _travelLegs.add(TravelLeg(
        fromText: previousLeg?.toText ?? '',
        fromPlaceId:
            previousLeg?.toPlaceId, // Also copy placeId for better caching
        toText: '',
        minutes: 0,
        source: 'manual',
      ));

      // Initialize controllers
      _legHoursControllers[newIndex] = TextEditingController();
      _legMinutesControllers[newIndex] = TextEditingController();
    });
  }

  void _removeTravelLeg(int index) {
    setState(() {
      // Clean up controllers
      _legHoursControllers[index]?.dispose();
      _legMinutesControllers[index]?.dispose();
      _legNotesControllers[index]?.dispose();
      _legHoursControllers.remove(index);
      _legMinutesControllers.remove(index);
      _legNotesControllers.remove(index);
      _isCalculatingLeg.remove(index);
      _legErrors.remove(index);

      // Reindex controllers
      final newHoursControllers = <int, TextEditingController>{};
      final newMinutesControllers = <int, TextEditingController>{};
      final newNotesControllers = <int, TextEditingController>{};
      for (var i = 0; i < _travelLegs.length; i++) {
        if (i < index) {
          if (_legHoursControllers.containsKey(i)) {
            newHoursControllers[i] = _legHoursControllers[i]!;
            newMinutesControllers[i] = _legMinutesControllers[i]!;
          }
          if (_legNotesControllers.containsKey(i)) {
            newNotesControllers[i] = _legNotesControllers[i]!;
          }
        } else if (i > index) {
          if (_legHoursControllers.containsKey(i)) {
            newHoursControllers[i - 1] = _legHoursControllers[i]!;
            newMinutesControllers[i - 1] = _legMinutesControllers[i]!;
          }
          if (_legNotesControllers.containsKey(i)) {
            newNotesControllers[i - 1] = _legNotesControllers[i]!;
          }
        }
      }
      _legHoursControllers.clear();
      _legMinutesControllers.clear();
      _legNotesControllers.clear();
      _legHoursControllers.addAll(newHoursControllers);
      _legMinutesControllers.addAll(newMinutesControllers);
      _legNotesControllers.addAll(newNotesControllers);

      _travelLegs.removeAt(index);
    });
  }

  Future<void> _calculateTravelLeg(int index) async {
    final leg = _travelLegs[index];
    if (leg.fromText.isEmpty || leg.toText.isEmpty) {
      return;
    }

    setState(() {
      _isCalculatingLeg[index] = true;
      _legErrors[index] = null;
    });

    try {
      // Only call Directions API on explicit Calculate button press
      final result = await MapService.calculateTravelTime(
        origin: leg.fromText,
        destination: leg.toText,
        originPlaceId: leg.fromPlaceId,
        destinationPlaceId: leg.toPlaceId,
        useCache: true, // Check cache first
      );

      final durationMinutes = result['durationMinutes'] as int;
      final distanceKm = result['distanceKm'] as double?;
      final durationText = result['durationText'] as String;
      final distanceText = result['distanceText'] as String;

      if (!mounted) return;
      setState(() {
        _travelLegs[index] = leg.copyWith(
          minutes: durationMinutes,
          distanceKm: distanceKm,
          source: 'auto',
          calculatedAt: DateTime.now(),
        );
        // Update controllers
        _legHoursControllers[index]?.text =
            durationMinutes > 0 ? (durationMinutes ~/ 60).toString() : '';
        _legMinutesControllers[index]?.text =
            durationMinutes > 0 ? (durationMinutes % 60).toString() : '';
        _isCalculatingLeg[index] = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                  .entry_travelTimeCalculated(durationText, distanceText),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCalculatingLeg[index] = false;
        _legErrors[index] = e.toString().replaceAll('Exception: ', '');
      });

      if (mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_calculatingTravelTime(e.toString())),
            backgroundColor: AppColors.error,
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
          AppLocalizations.of(context).form_workLocation,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LocationSelector(
          labelText: AppLocalizations.of(context).entry_location,
          hintText: AppLocalizations.of(context).entry_locationHint,
          initialValue: _workLocation,
          onLocationSelected: (location) {
            setState(() {
              _workLocation = location;
              // If toggle is ON, clear shift-specific locations so they use the new default
              if (_useLocationForAllShifts) {
                _shifts = _shifts
                    .map((shift) => shift.copyWith(location: null))
                    .toList();
              }
            });
          },
          prefixIcon: Icons.work,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Toggle for "Use location for all shifts"
        Row(
          children: [
            Checkbox(
              value: _useLocationForAllShifts,
              onChanged: (value) {
                setState(() {
                  _useLocationForAllShifts = value ?? true;
                  if (_useLocationForAllShifts) {
                    // Clear shift-specific locations so they all use the default
                    _shifts = _shifts
                        .map((shift) => shift.copyWith(location: null))
                        .toList();
                  }
                });
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _useLocationForAllShifts = !_useLocationForAllShifts;
                    if (_useLocationForAllShifts) {
                      // Clear shift-specific locations so they all use the default
                      _shifts = _shifts
                          .map((shift) => shift.copyWith(location: null))
                          .toList();
                    }
                  });
                },
                child: Text(
                  AppLocalizations.of(context).form_useLocationForAllShifts,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addShift() {
    HapticFeedback.lightImpact();
    setState(() {
      // Use selected date instead of DateTime.now() to ensure shifts are on the correct date
      final baseDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );
      final now = DateTime.now();
      final startTime = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        now.hour,
        now.minute,
      );
      final newIndex = _shifts.length;
      _shifts.add(Shift(
        start: startTime,
        end: startTime.add(const Duration(hours: 8)),
        location: _useLocationForAllShifts ? _workLocation : null,
      ));
      // Initialize notes controller for new shift
      _shiftNotesControllers[newIndex] = TextEditingController();
      _shiftBreakControllers[newIndex] = TextEditingController(text: '0');
    });
  }

  void _removeShift(int index) {
    setState(() {
      // Clean up notes controller for removed shift
      _shiftNotesControllers[index]?.dispose();
      _shiftNotesControllers.remove(index);

      // Reindex remaining controllers (shift indices down by 1 for shifts after removed one)
      final newControllers = <int, TextEditingController>{};
      for (var i = 0; i < _shifts.length; i++) {
        if (i < index) {
          // Keep controllers before removed index as-is
          if (_shiftNotesControllers.containsKey(i)) {
            newControllers[i] = _shiftNotesControllers[i]!;
          }
        } else if (i > index) {
          // Shift controllers after removed index down by 1
          if (_shiftNotesControllers.containsKey(i)) {
            newControllers[i - 1] = _shiftNotesControllers[i]!;
          }
        }
      }
      _shiftNotesControllers.clear();
      _shiftNotesControllers.addAll(newControllers);

      // Reindex remaining break controllers
      final newBreakControllers = <int, TextEditingController>{};
      for (var i = 0; i < _shifts.length; i++) {
        if (i < index) {
          if (_shiftBreakControllers.containsKey(i)) {
            newBreakControllers[i] = _shiftBreakControllers[i]!;
          }
        } else if (i > index) {
          if (_shiftBreakControllers.containsKey(i)) {
            newBreakControllers[i - 1] = _shiftBreakControllers[i]!;
          }
        }
      }
      _shiftBreakControllers.clear();
      _shiftBreakControllers.addAll(newBreakControllers);

      _shifts.removeAt(index);
    });
  }

  List<Widget> _buildWorkSpecificFields(ThemeData theme) {
    final t = AppLocalizations.of(context);
    return [
      Text(
        t.form_workDetails,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        t.edit_quickDuration,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _buildQuickDurationChip(theme, 2),
          _buildQuickDurationChip(theme, 4),
          _buildQuickDurationChip(theme, 6),
          _buildQuickDurationChip(theme, 8),
          _buildCopyYesterdayChip(theme),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Column(
          children: _shifts.asMap().entries.map((entry) {
            int index = entry.key;
            Shift shift = entry.value;
            return _buildShiftRow(theme, index, shift);
          }).toList(),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      // Add Another Shift button (only in create mode)
      if (!_isEditMode) ...[
        OutlinedButton.icon(
          onPressed: _addShift,
          icon: const Icon(Icons.add),
          label: Text(_shifts.isEmpty
              ? AppLocalizations.of(context).entry_addShift
              : AppLocalizations.of(context).home_addAnotherShift),
        ),
      ] else ...[
        // Edit mode info text
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline,
                  size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).editMode_singleEntryInfo_work,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
    ];
  }

  Widget _buildQuickDurationChip(ThemeData theme, int hours) {
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _applyQuickDuration(hours);
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.xxxl,
            minHeight: AppSpacing.xxxl,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm + 2,
            ),
            child: Center(
              child: Text(
                '+${hours}h',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyYesterdayChip(ThemeData theme) {
    final t = AppLocalizations.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _copyYesterdayShiftTimes();
        },
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.xxxl,
            minHeight: AppSpacing.xxxl,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.content_copy_rounded,
                    size: AppIconSize.xs,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    t.edit_copyYesterday,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _applyQuickDuration(int hours) {
    if (_shifts.isEmpty) {
      _addShift();
    }

    final start = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      8,
      0,
    );

    setState(() {
      final shift = _shifts.first;
      _shifts[0] = shift.copyWith(
        start: start,
        end: start.add(Duration(hours: hours)),
      );
    });
  }

  void _copyYesterdayShiftTimes() {
    final t = AppLocalizations.of(context);
    final entryProvider = context.read<EntryProvider>();
    final yesterday = _selectedDate.subtract(const Duration(days: 1));

    final yesterdayEntry = entryProvider.entries
        .where((entry) =>
            entry.type == EntryType.work &&
            entry.date.year == yesterday.year &&
            entry.date.month == yesterday.month &&
            entry.date.day == yesterday.day &&
            entry.shifts != null &&
            entry.shifts!.isNotEmpty)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (yesterdayEntry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.edit_noWorkEntryYesterday)),
      );
      return;
    }

    if (_shifts.isEmpty) {
      _addShift();
    }

    final sourceShift = yesterdayEntry.first.shifts!.first;
    final startTime = TimeOfDay.fromDateTime(sourceShift.start);
    final endTime = TimeOfDay.fromDateTime(sourceShift.end);

    setState(() {
      final targetShift = _shifts.first;
      _shifts[0] = targetShift.copyWith(
        start: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          startTime.hour,
          startTime.minute,
        ),
        end: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          endTime.hour,
          endTime.minute,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.edit_copiedYesterdayShiftTimes)),
    );
  }

  Widget _buildShiftRow(ThemeData theme, int index, Shift shift) {
    final t = AppLocalizations.of(context);
    final spanMinutes = shift.duration.inMinutes;
    final breakMinutes = shift.unpaidBreakMinutes;
    final workedMinutes = shift.workedMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shift header
            Row(
              children: [
                Text(
                  t.form_shiftLabel(index + 1),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Remove button only in create mode and if more than one shift
                if (!_isEditMode && index > 0)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _removeShift(index),
                    tooltip: t.common_delete,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Time selection row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectShiftStartTime(index),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.play_arrow,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            TimeOfDay.fromDateTime(shift.start).format(context),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectShiftEndTime(index),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outline),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.stop,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            TimeOfDay.fromDateTime(shift.end).format(context),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Break control
            Text(
              t.form_unpaidBreakMinutes,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [0, 15, 30, 45, 60].map((minutes) {
                final isSelected = shift.unpaidBreakMinutes == minutes;
                return FilterChip(
                  label: Text(
                    '$minutes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? theme.colorScheme.onSecondaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _shifts[index] = _shifts[index].copyWith(
                          unpaidBreakMinutes: minutes,
                        );
                        _shiftBreakControllers[index]?.text =
                            minutes.toString();
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _shiftBreakControllers[index] ??=
                  TextEditingController(
                      text: shift.unpaidBreakMinutes.toString()),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: t.form_minutes,
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value.trim()) ?? 0;
                if (parsed == shift.unpaidBreakMinutes) return;
                setState(() {
                  _shifts[index] = _shifts[index].copyWith(
                    unpaidBreakMinutes: parsed,
                  );
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Computed values display
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.sm - 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildComputedValue(
                    theme,
                    t.form_span,
                    _formatDuration(spanMinutes),
                  ),
                  _buildComputedValue(
                    theme,
                    t.form_break,
                    _formatDuration(breakMinutes),
                  ),
                  _buildComputedValue(
                    theme,
                    t.form_worked,
                    _formatDuration(workedMinutes),
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (!_useLocationForAllShifts) ...[
              // Shift location
              LocationSelector(
                labelText: AppLocalizations.of(context).form_shiftLocation,
                hintText: AppLocalizations.of(context).form_shiftLocationHint,
                initialValue: shift.location,
                onLocationSelected: (location) {
                  setState(() {
                    // Only set shift.location if it's different from default (to allow null = use default)
                    if (location != _workLocation) {
                      _shifts[index] =
                          _shifts[index].copyWith(location: location);
                    } else {
                      // If user selects the same as default, clear shift-specific location
                      _shifts[index] = _shifts[index].copyWith(location: null);
                    }
                  });
                },
                prefixIcon: Icons.location_on,
                isRequired: false,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Shift notes (collapsed by default)
            _buildShiftNotesField(theme, index, shift),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftNotesField(ThemeData theme, int index, Shift shift) {
    final controller = _shiftNotesControllers[index] ??=
        TextEditingController(text: shift.notes ?? '');
    final hasNotes = controller.text.isNotEmpty;

    return ExpansionTile(
      initiallyExpanded: hasNotes,
      title: Row(
        children: [
          Icon(
            Icons.note_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).form_shiftNotes,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!hasNotes) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context).common_optional,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).form_shiftNotesHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.note),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              setState(() {
                _shifts[index] = _shifts[index].copyWith(
                    notes: value.trim().isEmpty ? null : value.trim());
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComputedValue(ThemeData theme, String label, String value,
      {bool isHighlighted = false}) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isHighlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final t = AppLocalizations.of(context);

    if (_isEditMode) {
      // Edit mode: Show "Add new entry" button + Save button
      return Column(
        children: [
          // Add new entry button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openCreateEntryForDate(),
              icon: const Icon(Icons.add),
              label: Text(t.editMode_addNewEntryForDate),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _saveEntry,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
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

    // Create mode: Show Cancel + Save buttons
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            child: Text(t.common_cancel),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: _isLoading ? null : _saveEntry,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
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

  /// Open create entry form for the same date (and optionally prefill from current entry)
  void _openCreateEntryForDate() {
    if (!_isEditMode) return;

    // Close current edit form
    Navigator.of(context).pop();

    // Get the date from the entry being edited
    final editDate = widget.existingEntry!.date;

    // Show create form in a bottom sheet with same date
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UnifiedEntryForm(
        entryType: widget.entryType,
        existingEntry: null, // Create mode
        initialDate: editDate, // Prefill with same date
        onSaved: widget.onSaved,
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null && mounted) {
      setState(() {
        _selectedDate = date;
        // Update all shift dates to match the new selected date, preserving times
        _shifts = _shifts.map((shift) {
          final startTime = TimeOfDay.fromDateTime(shift.start);
          final endTime = TimeOfDay.fromDateTime(shift.end);
          return shift.copyWith(
            start: DateTime(
              date.year,
              date.month,
              date.day,
              startTime.hour,
              startTime.minute,
            ),
            end: DateTime(
              date.year,
              date.month,
              date.day,
              endTime.hour,
              endTime.minute,
            ),
          );
        }).toList();
      });
    }
  }

  Future<void> _selectShiftStartTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_shifts[index].start),
    );
    if (time != null && mounted) {
      setState(() {
        final shift = _shifts[index];
        // Use selected date to ensure shift is on the correct date
        _shifts[index] = shift.copyWith(
          start: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            time.hour,
            time.minute,
          ),
        );
        // Validate that end time is after start time
        if (_shifts[index].end.isBefore(_shifts[index].start) ||
            _shifts[index].end.isAtSameMomentAs(_shifts[index].start)) {
          // Auto-adjust end time to be 1 hour after start if invalid
          _shifts[index] = _shifts[index].copyWith(
            end: _shifts[index].start.add(const Duration(hours: 1)),
          );
        }
      });
    }
  }

  Future<void> _selectShiftEndTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_shifts[index].end),
    );
    if (time != null && mounted) {
      setState(() {
        final shift = _shifts[index];
        final endDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          time.hour,
          time.minute,
        );
        // Validate that end time is after start time
        if (endDateTime.isBefore(shift.start) ||
            endDateTime.isAtSameMomentAs(shift.start)) {
          if (!mounted) return;
          final t = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.error_endTimeBeforeStart),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        _shifts[index] = shift.copyWith(end: endDateTime);
      });
    }
  }

  Future<void> _saveEntry() async {
    final t = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    // Validate required fields
    if (widget.entryType == EntryType.travel) {
      if (_travelLegs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_addAtLeastOneTravelLeg),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      // Validate each leg
      for (var i = 0; i < _travelLegs.length; i++) {
        final leg = _travelLegs[i];
        if (leg.fromText.isEmpty || leg.toText.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.error_selectTravelLocations(i + 1)),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        if (leg.minutes <= 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.error_invalidTravelDuration(i + 1)),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }
    } else {
      if (_shifts.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_addAtLeastOneShift),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      // Validate all shifts have valid times and break minutes
      for (var i = 0; i < _shifts.length; i++) {
        final shift = _shifts[i];
        if (shift.end.isBefore(shift.start) ||
            shift.end.isAtSameMomentAs(shift.start)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.error_invalidShiftTime(i + 1)),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        // Validate break minutes
        final spanMinutes = shift.duration.inMinutes;
        if (shift.unpaidBreakMinutes < 0) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.error_negativeBreakMinutes(i + 1)),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        if (shift.unpaidBreakMinutes > spanMinutes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.error_breakExceedsSpan(
                  i + 1, shift.unpaidBreakMinutes, spanMinutes)),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      if (_currentUserId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_signInRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final entryProvider = context.read<EntryProvider>();

      final entryDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      final dayNotes = widget.entryType == EntryType.work
          ? null
          : (_notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim());

      if (widget.entryType == EntryType.work) {
        // WORK MODE: Save one Entry per shift (atomic entries)
        // Prepare all shift drafts with proper dates and locations
        final shiftDrafts = _shifts.asMap().entries.map((entry) {
          final shiftIndex = entry.key;
          final shift = entry.value;
          final notesController = _shiftNotesControllers[shiftIndex];
          final shiftNotes = notesController?.text.trim();

          // Effective location: shift-specific if set, otherwise use default
          final effectiveLocation = shift.location ?? _workLocation;

          final finalShift = shift.copyWith(
            // Use effective location (shift-specific or default)
            location: effectiveLocation,
            notes: shiftNotes?.isEmpty ?? true ? null : shiftNotes,
            // Ensure shift dates match selected date
            start: DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              shift.start.hour,
              shift.start.minute,
            ),
            end: DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              shift.end.hour,
              shift.end.minute,
            ),
          );

          // Debug logging to verify break/notes persistence
          debugPrint('UnifiedEntryForm: Shift ${shiftIndex + 1} before save - '
              'break=${finalShift.unpaidBreakMinutes}, notes=${finalShift.notes}, '
              'location=${finalShift.location}');

          return finalShift;
        }).toList();

        if (widget.existingEntry != null) {
          // EDITING: Update existing entry with first shift, create new entries for additional shifts
          if (shiftDrafts.isNotEmpty) {
            final firstShift = shiftDrafts.first;
            final updatedEntry = Entry(
              id: widget.existingEntry!.id,
              userId: _currentUserId!,
              type: EntryType.work,
              date: entryDateTime,
              shifts: [firstShift],
              notes: dayNotes,
              createdAt: widget.existingEntry!.createdAt,
              updatedAt: DateTime.now(),
            );
            await entryProvider.updateEntry(updatedEntry);
          }

          if (shiftDrafts.length > 1) {
            for (var i = 1; i < shiftDrafts.length; i++) {
              final newEntry = Entry.makeWorkAtomicFromShift(
                userId: _currentUserId!,
                date: entryDateTime,
                shift: shiftDrafts[i],
                dayNotes: dayNotes,
              );
              await entryProvider.addEntry(newEntry);
            }
          }
        } else {
          // CREATING NEW: Create one entry per shift using helper method
          final workEntries = shiftDrafts.map((shiftDraft) {
            return Entry.makeWorkAtomicFromShift(
              userId: _currentUserId!,
              date: entryDateTime,
              shift: shiftDraft,
              dayNotes: dayNotes,
            );
          }).toList();

          // Save all entries in batch
          await entryProvider.addEntries(workEntries);
        }
      } else {
        // TRAVEL MODE: Save one Entry per leg (atomic entries)
        // Each leg has its own notes from _legNotesControllers
        String? legNotes(int index) {
          final text = _legNotesControllers[index]?.text.trim();
          return (text == null || text.isEmpty) ? null : text;
        }

        if (widget.existingEntry != null) {
          // EDITING: Update existing entry with first leg, create new entries for additional legs
          if (_travelLegs.isNotEmpty) {
            final firstLeg = _travelLegs.first;
            final updatedEntry = Entry(
              id: widget.existingEntry!.id,
              userId: _currentUserId!,
              type: EntryType.travel,
              date: entryDateTime,
              from: firstLeg.fromText,
              to: firstLeg.toText,
              travelMinutes: firstLeg.minutes,
              notes: legNotes(0),
              segmentOrder: 1,
              totalSegments: _travelLegs.length,
              createdAt: widget.existingEntry!.createdAt,
              updatedAt: DateTime.now(),
            );
            await entryProvider.updateEntry(updatedEntry);

            // Additional legs become new entries
            if (_travelLegs.length > 1) {
              for (var i = 1; i < _travelLegs.length; i++) {
                final leg = _travelLegs[i];
                final newEntry = Entry.makeTravelAtomicFromLeg(
                  userId: _currentUserId!,
                  date: entryDateTime,
                  from: leg.fromText,
                  to: leg.toText,
                  minutes: leg.minutes,
                  dayNotes: legNotes(i),
                  fromPlaceId: leg.fromPlaceId,
                  toPlaceId: leg.toPlaceId,
                  source: leg.source,
                  distanceKm: leg.distanceKm,
                  calculatedAt: leg.calculatedAt,
                  segmentOrder: i + 1,
                  totalSegments: _travelLegs.length,
                );
                await entryProvider.addEntry(newEntry);
              }
            }
          }
        } else {
          // CREATING NEW: Create one entry per leg using helper method
          final travelEntries = _travelLegs.asMap().entries.map((entry) {
            final index = entry.key;
            final leg = entry.value;
            return Entry.makeTravelAtomicFromLeg(
              userId: _currentUserId!,
              date: entryDateTime,
              from: leg.fromText,
              to: leg.toText,
              minutes: leg.minutes,
              dayNotes: legNotes(index),
              fromPlaceId: leg.fromPlaceId,
              toPlaceId: leg.toPlaceId,
              source: leg.source,
              distanceKm: leg.distanceKm,
              calculatedAt: leg.calculatedAt,
              segmentOrder: index + 1,
              totalSegments: _travelLegs.length,
            );
          }).toList();

          // Save all entries in batch
          await entryProvider.addEntries(travelEntries);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();

        // Determine how many entries were saved
        final entryCount = widget.entryType == EntryType.work
            ? _shifts.length
            : _travelLegs.length;

        // Show success message (batch addEntries shows single message)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              entryCount > 1
                  ? '$entryCount ${widget.entryType == EntryType.travel ? t.entry_travel : t.entry_work} ${t.common_saved.toLowerCase()}'
                  : t.simpleEntry_entrySaved(
                      widget.entryType == EntryType.travel
                          ? t.entry_travel
                          : t.entry_work,
                      widget.existingEntry != null
                          ? t.common_updated
                          : t.common_saved,
                    ),
            ),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.error_savingEntry(e.toString())),
            backgroundColor: AppColors.error,
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
}
