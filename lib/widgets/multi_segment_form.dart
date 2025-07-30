import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/travel_segment.dart';
import '../models/entry.dart'; // Updated to use unified Entry model
import '../providers/entry_provider.dart'; // Updated to use EntryProvider
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'travel_segment_card.dart';

class MultiSegmentForm extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final DateTime? initialDate;
  final String? editingJourneyId;
  final List<Entry>? existingSegments; // Updated to use Entry model

  const MultiSegmentForm({
    super.key,
    this.onSuccess,
    this.onCancel,
    this.initialDate,
    this.editingJourneyId,
    this.existingSegments,
  });

  @override
  State<MultiSegmentForm> createState() => _MultiSegmentFormState();
}

class _MultiSegmentFormState extends State<MultiSegmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  
  List<TravelSegment> _segments = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  // Controllers for the current segment being added
  final _departureController = TextEditingController();
  final _arrivalController = TextEditingController();
  final _minutesController = TextEditingController();
  final _infoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    
    if (widget.existingSegments != null && widget.existingSegments!.isNotEmpty) {
      _loadExistingSegments();
    } else {
      _addInitialSegment();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _departureController.dispose();
    _arrivalController.dispose();
    _minutesController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  void _addInitialSegment() {
    // Add an empty segment to start with
    _clearCurrentSegmentForm();
  }

  void _loadExistingSegments() {
    // Convert existing Entry segments to TravelSegment objects
    _segments = widget.existingSegments!.map((entry) => TravelSegment(
      id: entry.id,
      departure: entry.from ?? '', // Entry uses 'from' instead of 'departure'
      arrival: entry.to ?? '', // Entry uses 'to' instead of 'arrival'
      minutes: entry.travelMinutes ?? 0, // Entry uses 'travelMinutes' instead of 'minutes'
      info: entry.notes, // Entry uses 'notes' instead of 'info'
    )).toList();
    
    // Set the date from the first segment
    if (widget.existingSegments!.isNotEmpty) {
      _selectedDate = widget.existingSegments!.first.date;
    }
    
    _clearCurrentSegmentForm();
  }

  void _clearCurrentSegmentForm() {
    _departureController.clear();
    _arrivalController.clear();
    _minutesController.clear();
    _infoController.clear();
    
    // If there are existing segments, pre-fill departure with last arrival
    if (_segments.isNotEmpty) {
      _departureController.text = _segments.last.arrival;
    }
  }

  void _addSegment() {
    if (!_validateCurrentSegment()) return;

    final newSegment = TravelSegment(
      id: const Uuid().v4(),
      departure: _departureController.text.trim(),
      arrival: _arrivalController.text.trim(),
      minutes: int.parse(_minutesController.text),
      info: _infoController.text.trim().isEmpty ? null : _infoController.text.trim(),
    );

    setState(() {
      _segments.add(newSegment);
      _clearCurrentSegmentForm();
    });

    // Scroll to show the new segment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  bool _validateCurrentSegment() {
    if (_departureController.text.trim().isEmpty) {
      _showError('Please enter departure location');
      return false;
    }
    if (_arrivalController.text.trim().isEmpty) {
      _showError('Please enter arrival location');
      return false;
    }
    if (_minutesController.text.trim().isEmpty) {
      _showError('Please enter travel time');
      return false;
    }
    
    final minutes = int.tryParse(_minutesController.text);
    if (minutes == null || minutes <= 0) {
      _showError('Please enter a valid travel time');
      return false;
    }

    return true;
  }

  void _removeSegment(int index) {
    setState(() {
      _segments.removeAt(index);
      
      // If we removed a middle segment, we might need to update the form
      // to maintain the chain
      if (_segments.isNotEmpty && _departureController.text.isEmpty) {
        _departureController.text = _segments.last.arrival;
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submitJourney() async {
    // Add the current segment if it's valid
    if (_hasCurrentSegmentData() && _validateCurrentSegment()) {
      _addSegment();
    }

    if (_segments.isEmpty) {
      _showError('Please add at least one travel segment');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entryProvider = context.read<EntryProvider>(); // Updated to use EntryProvider
      final journeyId = widget.editingJourneyId ?? const Uuid().v4();
      final isEditing = widget.editingJourneyId != null;
      
      // Create travel entries for each segment using unified Entry model
      final entries = <Entry>[];
      for (int i = 0; i < _segments.length; i++) {
        final segment = _segments[i];
        final entry = Entry(
          userId: 'current_user', // TODO: Get from auth service
          type: EntryType.travel, // Always travel for this form
          date: _selectedDate,
          from: segment.departure, // Entry uses 'from' instead of 'departure'
          to: segment.arrival, // Entry uses 'to' instead of 'arrival'
          travelMinutes: segment.minutes, // Entry uses 'travelMinutes' instead of 'minutes'
          notes: segment.info, // Entry uses 'notes' instead of 'info'
          journeyId: journeyId,
          segmentOrder: i + 1,
          totalSegments: _segments.length,
        );
        entries.add(entry);
      }

      bool success;
      if (isEditing) {
        // Update existing journey
        success = await entryProvider.updateJourney(journeyId, entries);
      } else {
        // Add new journey - EntryProvider handles this more efficiently
        bool allSuccess = true;
        for (final entry in entries) {
          final entrySuccess = await entryProvider.addEntry(entry);
          if (!entrySuccess) {
            allSuccess = false;
            break;
          }
        }
        success = allSuccess;
      }

      if (success && mounted) {
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing 
                ? 'Multi-segment journey updated successfully!'
                : 'Multi-segment journey with ${_segments.length} segments added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        _showError(isEditing 
            ? 'Failed to update the journey'
            : 'Failed to save some segments of the journey');
      }
    } catch (error) {
      if (mounted) {
        _showError('Error saving journey: $error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _hasCurrentSegmentData() {
    return _departureController.text.trim().isNotEmpty ||
           _arrivalController.text.trim().isNotEmpty ||
           _minutesController.text.trim().isNotEmpty;
  }

  int get _totalMinutes {
    int total = 0;
    for (final segment in _segments) {
      total += segment.minutes;
    }
    // Add current segment if it has valid minutes
    final currentMinutes = int.tryParse(_minutesController.text);
    if (currentMinutes != null && currentMinutes > 0) {
      total += currentMinutes;
    }
    return total;
  }

  String get _formattedTotalDuration {
    final minutes = _totalMinutes;
    if (minutes == 0) return '0m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.route,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.editingJourneyId != null ? 'Edit Multi-Segment Journey' : 'Multi-Segment Journey',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onCancel != null)
                    IconButton(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close),
                      tooltip: 'Close',
                    ),
                ],
              ),
              
              // Journey summary
              if (_segments.isNotEmpty || _totalMinutes > 0) ...[
                const SizedBox(height: AppConstants.smallPadding),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_segments.length} segments • Total: $_formattedTotalDuration',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Existing segments
              if (_segments.isNotEmpty) ...[
                Text(
                  'Journey Segments',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _segments.length,
                    itemBuilder: (context, index) {
                      final segment = _segments[index];
                      return TravelSegmentCard(
                        segment: segment,
                        segmentNumber: index + 1,
                        isFirst: index == 0,
                        isLast: index == _segments.length - 1,
                        onRemove: () => _removeSegment(index),
                        showRemoveButton: _segments.length > 1,
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: AppConstants.defaultPadding),
              ],
              
              // Add new segment form
              Text(
                _segments.isEmpty ? 'First Segment' : 'Add Next Segment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              
              // From field
              TextFormField(
                controller: _departureController,
                decoration: const InputDecoration(
                  labelText: 'From',
                  hintText: 'Departure location',
                  prefixIcon: Icon(Icons.my_location),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(value, 'Departure location'),
              ),
              
              const SizedBox(height: AppConstants.smallPadding),
              
              // To field
              TextFormField(
                controller: _arrivalController,
                decoration: const InputDecoration(
                  labelText: 'To',
                  hintText: 'Arrival location',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => Validators.validateRequired(value, 'Arrival location'),
              ),
              
              const SizedBox(height: AppConstants.smallPadding),
              
              // Minutes field
              TextFormField(
                controller: _minutesController,
                decoration: const InputDecoration(
                  labelText: 'Travel Time (minutes)',
                  hintText: 'e.g., 20',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.validateMinutes,
              ),
              
              const SizedBox(height: AppConstants.smallPadding),
              
              // Info field
              TextFormField(
                controller: _infoController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Additional information',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 1,
              ),
              
              const SizedBox(height: AppConstants.defaultPadding),
              
              // Action buttons
              Row(
                children: [
                  // Add segment button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addSegment,
                      icon: const Icon(Icons.add),
                      label: Text(_segments.isEmpty ? 'Add First Segment' : 'Add Next Segment'),
                    ),
                  ),
                  
                  const SizedBox(width: AppConstants.smallPadding),
                  
                  // Save journey button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitJourney,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Saving...' : 'Save Journey'),
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