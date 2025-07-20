import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/travel_time_entry.dart';
import '../models/location.dart';
import '../providers/travel_provider.dart';
import '../providers/location_provider.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'location_selector.dart';

class QuickEntryForm extends StatefulWidget {
  final TravelTimeEntry? initialEntry;
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
      _dateController.text = DateFormat(AppConstants.dateFormat).format(entry.date);
      _departureController.text = entry.departure;
      _arrivalController.text = entry.arrival;
      _minutesController.text = entry.minutes.toString();
      _infoController.text = entry.info ?? '';
    } else {
      _dateController.text = DateFormat(AppConstants.dateFormat).format(_selectedDate);
    }
  }

  void _loadRecentRoutes() {
    final travelProvider = context.read<TravelProvider>();
    final recentEntries = travelProvider.getRecentEntries(limit: 5);
    
    final routes = <String>{};
    for (final entry in recentEntries) {
      routes.add('${entry.departure} → ${entry.arrival}');
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

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat(AppConstants.dateFormat).format(picked);
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
    final parts = route.split(' → ');
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
      final entry = TravelTimeEntry(
        id: widget.initialEntry?.id,
        date: _selectedDate,
        departure: _departureController.text.trim(),
        arrival: _arrivalController.text.trim(),
        minutes: int.parse(_minutesController.text),
        info: _infoController.text.trim().isEmpty ? null : _infoController.text.trim(),
        departureLocationId: _selectedDepartureLocation?.id,
        arrivalLocationId: _selectedArrivalLocation?.id,
        createdAt: widget.initialEntry?.createdAt,
      );

      final travelProvider = context.read<TravelProvider>();
      bool success;

      if (widget.initialEntry != null) {
        success = await travelProvider.updateEntry(entry);
      } else {
        success = await travelProvider.addEntry(entry);
      }

      if (success && mounted) {
        _clearForm();
        widget.onSuccess?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialEntry != null 
                ? 'Travel entry updated!' 
                : 'Travel entry added!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${widget.initialEntry != null ? 'update' : 'save'} entry'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
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

  void _clearForm() {
    _formKey.currentState?.reset();
    _dateController.text = DateFormat(AppConstants.dateFormat).format(DateTime.now());
    _departureController.clear();
    _arrivalController.clear();
    _minutesController.clear();
    _infoController.clear();
    _selectedDepartureLocation = null;
    _selectedArrivalLocation = null;
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(widget.isCompact ? 12 : AppConstants.defaultPadding),
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
                      widget.initialEntry != null ? 'Edit Entry' : 'Quick Entry',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (widget.onCancel != null)
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('Cancel'),
                      ),
                  ],
                ),
                
                // Recent routes chips
                if (_recentRoutes.isNotEmpty && widget.initialEntry == null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _recentRoutes.map((route) => ActionChip(
                      label: Text(
                        route,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _useRecentRoute(route),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    )).toList(),
                  ),
                ],
                
                const SizedBox(height: AppConstants.defaultPadding),
              ],

              // Date field
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _selectDate,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Please select a date' : null,
              ),

              SizedBox(height: widget.isCompact ? 8 : AppConstants.defaultPadding),

              // Location fields with swap button
              Row(
                children: [
                  Expanded(
                    child: LocationSelector(
                      initialValue: _departureController.text,
                      labelText: 'From',
                      hintText: 'Departure location',
                      prefixIcon: Icons.my_location,
                      onLocationSelected: (address) {
                        _departureController.text = address;
                      },
                      onLocationObjectSelected: (location) {
                        _selectedDepartureLocation = location;
                      },
                      validator: (value) => Validators.validateRequired(value, 'Departure location'),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconButton(
                      onPressed: _swapLocations,
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Swap locations',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: LocationSelector(
                      initialValue: _arrivalController.text,
                      labelText: 'To',
                      hintText: 'Arrival location',
                      prefixIcon: Icons.location_on,
                      onLocationSelected: (address) {
                        _arrivalController.text = address;
                      },
                      onLocationObjectSelected: (location) {
                        _selectedArrivalLocation = location;
                      },
                      validator: (value) => Validators.validateRequired(value, 'Arrival location'),
                    ),
                  ),
                ],
              ),

              SizedBox(height: widget.isCompact ? 8 : AppConstants.defaultPadding),

              // Minutes field
              TextFormField(
                controller: _minutesController,
                decoration: const InputDecoration(
                  labelText: 'Travel Time (minutes)',
                  hintText: 'e.g., 45',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.validateMinutes,
              ),

              SizedBox(height: widget.isCompact ? 8 : AppConstants.defaultPadding),

              // Info field
              TextFormField(
                controller: _infoController,
                decoration: const InputDecoration(
                  labelText: 'Additional Info (Optional)',
                  hintText: 'Notes, delays, etc.',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: widget.isCompact ? 1 : 2,
                validator: Validators.validateInfo,
              ),

              SizedBox(height: widget.isCompact ? 12 : AppConstants.largePadding),

              // Action buttons
              Row(
                children: [
                  if (!widget.isCompact) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _clearForm,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                          : Icon(widget.initialEntry != null ? Icons.save : Icons.add),
                      label: Text(
                        _isLoading 
                            ? 'Saving...' 
                            : widget.initialEntry != null 
                                ? 'Update Entry' 
                                : 'Add Entry',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(widget.isCompact ? 12 : AppConstants.defaultPadding),
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