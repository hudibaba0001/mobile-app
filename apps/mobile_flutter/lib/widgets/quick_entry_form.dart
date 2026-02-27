import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../design/app_theme.dart';
import '../models/entry.dart';
import '../models/location.dart';
import '../providers/entry_provider.dart';
import '../providers/network_status_provider.dart';
import '../services/supabase_auth_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../l10n/generated/app_localizations.dart';
import '../utils/error_message_mapper.dart';

import 'multi_segment_form.dart';

class QuickEntryForm extends StatefulWidget {
  final Entry? initialEntry;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final bool showTitle;
  final bool isCompact;

  const QuickEntryForm({
    super.key,
    this.initialEntry,
    this.onSuccess,
    this.onCancel,
    this.showTitle = true,
    this.isCompact = false,
  });

  @override
  State<QuickEntryForm> createState() => _QuickEntryFormState();
}

class _QuickEntryFormState extends State<QuickEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _minutesController = TextEditingController();
  final _infoController = TextEditingController();

  Location? _selectedDepartureLocation;
  Location? _selectedArrivalLocation;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  List<String> _recentRoutes = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadRecentRoutes();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _minutesController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.initialEntry != null) {
      final entry = widget.initialEntry!;
      _selectedDate = entry.date;
      _dateController.text =
          DateFormat(AppConstants.dateFormat).format(entry.date);
      _departureController.text = entry.from ?? '';
      _arrivalController.text = entry.to ?? '';
      _minutesController.text = entry.travelMinutes?.toString() ?? '';
      _infoController.text = entry.notes ?? '';
    } else {
      _dateController.text =
          DateFormat(AppConstants.dateFormat).format(_selectedDate);
    }
  }

  Future<void> _loadRecentRoutes() async {
    final entryProvider = context.read<EntryProvider>();
    final recentEntries = entryProvider.getRecentEntries(limit: 5);

    final routes = <String>{};
    for (final entry in recentEntries) {
      if (entry.from != null && entry.to != null) {
        routes.add('${entry.from} â†’ ${entry.to}');
      }
    }

    setState(() {
      _recentRoutes = routes.toList();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            DateFormat(AppConstants.dateFormat).format(picked);
      });
    }
  }

  void _swapLocations() {
    final tempDeparture = _departureController.text;
    final tempDepartureLocation = _selectedDepartureLocation;

    setState(() {
      _departureController.text = _arrivalController.text;
      _selectedDepartureLocation = _selectedArrivalLocation;

      _arrivalController.text = tempDeparture;
      _selectedArrivalLocation = tempDepartureLocation;
    });
  }

  void _useRecentRoute(String route) {
    final parts = route.split(' â†’ ');
    if (parts.length == 2) {
      setState(() {
        _departureController.text = parts[0];
        _arrivalController.text = parts[1];
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<SupabaseAuthService>();
      final uid = auth.currentUser?.id;
      if (uid == null) {
        if (mounted) {
          final t = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.quickEntry_signInRequired)),
          );
        }
        return;
      }

      final entry = Entry(
        id: widget.initialEntry?.id,
        userId: uid,
        type: EntryType.travel,
        date: _selectedDate,
        from: _departureController.text.trim(),
        to: _arrivalController.text.trim(),
        travelMinutes: int.tryParse(_minutesController.text) ?? 0,
        notes: _infoController.text.trim().isEmpty
            ? null
            : _infoController.text.trim(),
        createdAt: widget.initialEntry?.createdAt,
      );

      final entryProvider = context.read<EntryProvider>();

      if (widget.initialEntry != null) {
        await entryProvider.updateEntry(entry);
      } else {
        await entryProvider.addEntry(entry);
      }
      if (!mounted) return;

      _clearForm();
      widget.onSuccess?.call();
      final t = AppLocalizations.of(context);
      final isOffline =
          context.read<NetworkStatusProvider?>()?.isOffline ?? false;
      final queuedOffline = isOffline || entryProvider.hasPendingSync;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(queuedOffline
              ? _savedOfflineMessage(t)
              : widget.initialEntry != null
                  ? 'Travel entry updated!'
                  : 'Travel entry added!'),
          backgroundColor:
              queuedOffline ? Theme.of(context).colorScheme.tertiaryContainer : AppColors.success,
        ),
      );
    } catch (error) {
      if (mounted) {
        final t = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(t.quickEntry_error(ErrorMessageMapper.userMessage(error, t))),
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

  void _clearForm() {
    _formKey.currentState?.reset();
    _dateController.text =
        DateFormat(AppConstants.dateFormat).format(DateTime.now());
    _departureController.clear();
    _arrivalController.clear();
    _minutesController.clear();
    _infoController.clear();
    _selectedDepartureLocation = null;
    _selectedArrivalLocation = null;
    _selectedDate = DateTime.now();
  }

  String _savedOfflineMessage(AppLocalizations t) {
    if (t.localeName.toLowerCase().startsWith('sv')) {
      return 'Sparad offline - synkas nar du ar ansluten.';
    }
    return 'Saved offline - will sync when connected.';
  }

  void _showMultiSegmentForm() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 500,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SizedBox(
            width: double.maxFinite,
            child: MultiSegmentForm(
              initialDate: _selectedDate,
              onSuccess: () {
                Navigator.of(context).pop(); // Close multi-segment dialog
                widget.onSuccess?.call(); // Call parent success callback
              },
              onCancel: () {
                Navigator.of(context).pop(); // Close multi-segment dialog
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(
            widget.isCompact ? AppSpacing.md : AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and recent routes
              if (widget.showTitle) ...[
                Row(
                  children: [
                    Text(
                      widget.initialEntry != null
                          ? AppLocalizations.of(context).quickEntry_editEntry
                          : AppLocalizations.of(context).quickEntry_quickEntry,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),

                    // Multi-segment button (only for new entries)
                    if (widget.initialEntry == null) ...[
                      TextButton.icon(
                        onPressed: _showMultiSegmentForm,
                        icon: const Icon(Icons.route, size: 16),
                        label: Text(AppLocalizations.of(context)
                            .quickEntry_multiSegment),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],

                    if (widget.onCancel != null) ...[
                      IconButton(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close),
                        tooltip: AppLocalizations.of(context).common_close,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.neutral500.withValues(alpha: 0.1),
                        ),
                      ),
                    ] else ...[
                      // Show close button even if no onCancel callback
                      IconButton(
                        onPressed: () {
                          // Try to pop the current route if in a dialog/modal
                          if (Navigator.canPop(context)) {
                            Navigator.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.close),
                        tooltip: AppLocalizations.of(context).common_close,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              AppColors.neutral500.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ],
                ),

                // Recent routes chips
                if (_recentRoutes.isNotEmpty &&
                    widget.initialEntry == null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    children: _recentRoutes
                        .map((route) => ActionChip(
                              label: Text(
                                route,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 12),
                              ),
                              onPressed: () => _useRecentRoute(route),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                            ))
                        .toList(),
                  ),
                ],

                const SizedBox(height: AppConstants.defaultPadding),
              ],

              // Date field
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).entry_date,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true
                    ? AppLocalizations.of(context).form_pleaseSelectDate
                    : null,
              ),

              SizedBox(
                  height: widget.isCompact ? 8 : AppConstants.defaultPadding),

              // Location fields with swap button (vertical layout)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // From location
                  TextFormField(
                    controller: _departureController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).entry_from,
                      hintText:
                          AppLocalizations.of(context).form_departureLocation,
                      prefixIcon: const Icon(Icons.my_location),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => Validators.validateRequired(value,
                        AppLocalizations.of(context).form_departureLocation),
                  ),

                  // Swap button (centered between fields)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: IconButton(
                            onPressed: _swapLocations,
                            icon: const Icon(Icons.swap_vert),
                            tooltip: AppLocalizations.of(context)
                                .common_swapLocations,
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),

                  // To location
                  TextFormField(
                    controller: _arrivalController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).entry_to,
                      hintText:
                          AppLocalizations.of(context).form_arrivalLocation,
                      prefixIcon: const Icon(Icons.location_on),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) => Validators.validateRequired(value,
                        AppLocalizations.of(context).form_arrivalLocation),
                  ),
                ],
              ),

              SizedBox(
                  height: widget.isCompact ? 8 : AppConstants.defaultPadding),

              // Minutes field
              TextFormField(
                controller: _minutesController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).quickEntry_travelTimeMinutes,
                  hintText:
                      AppLocalizations.of(context).quickEntry_travelTimeHint,
                  prefixIcon: const Icon(Icons.access_time),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.validateMinutes,
              ),

              SizedBox(
                  height: widget.isCompact ? 8 : AppConstants.defaultPadding),

              // Info field
              TextFormField(
                controller: _infoController,
                decoration: InputDecoration(
                  labelText:
                      AppLocalizations.of(context).quickEntry_additionalInfo,
                  hintText: AppLocalizations.of(context)
                      .quickEntry_additionalInfoHint,
                  prefixIcon: const Icon(Icons.note),
                  border: const OutlineInputBorder(),
                ),
                maxLines: widget.isCompact ? 1 : 2,
                validator: Validators.validateInfo,
              ),

              SizedBox(
                  height: widget.isCompact ? 12 : AppConstants.largePadding),

              // Action buttons
              Row(
                children: [
                  if (!widget.isCompact) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _clearForm,
                        icon: const Icon(Icons.clear),
                        label:
                            Text(AppLocalizations.of(context).quickEntry_clear),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    flex: widget.isCompact ? 1 : 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitForm,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(widget.initialEntry != null
                              ? Icons.save
                              : Icons.add),
                      label: Text(
                        _isLoading
                            ? AppLocalizations.of(context).quickEntry_saving
                            : widget.initialEntry != null
                                ? AppLocalizations.of(context)
                                    .quickEntry_updateEntry
                                : AppLocalizations.of(context)
                                    .quickEntry_addEntry,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(widget.isCompact
                            ? 12
                            : AppConstants.defaultPadding),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
