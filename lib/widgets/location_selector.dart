import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location.dart';
import '../providers/location_provider.dart';

class LocationSelector extends StatefulWidget {
  final String? initialValue;
  final String labelText;
  final String hintText;
  final IconData? prefixIcon;
  final bool isRequired;
  final Function(String) onLocationSelected;
  final Function(Location?)? onLocationObjectSelected;
  final String? Function(String?)? validator;
  final bool showSaveOption;
  final bool showFavoritesFirst;

  const LocationSelector({
    super.key,
    this.initialValue,
    required this.labelText,
    required this.hintText,
    this.prefixIcon,
    this.isRequired = false,
    required this.onLocationSelected,
    this.onLocationObjectSelected,
    this.validator,
    this.showSaveOption = true,
    this.showFavoritesFirst = true,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<Location> _suggestions = [];
  List<String> _addressSuggestions = [];
  bool _isShowingOverlay = false;
  Location? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      // Ensure suggestions are up to date when gaining focus
      final query = _controller.text;
      _updateSuggestions(query);
      final trimmed = query.trim();
      final hasContent = _suggestions.isNotEmpty ||
          _addressSuggestions.isNotEmpty ||
          (widget.showSaveOption &&
              trimmed.isNotEmpty &&
              !_isExistingLocation(trimmed));

      if (hasContent) {
        _showSuggestions();
        _overlayEntry?.markNeedsBuild();
      } else {
        _removeOverlay();
      }
    } else {
      // Delay hiding to allow for tap on suggestions
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    final query = _controller.text;
    widget.onLocationSelected(query);

    _updateSuggestions(query);
    final trimmed = query.trim();
    final hasContent = _suggestions.isNotEmpty ||
        _addressSuggestions.isNotEmpty ||
        (widget.showSaveOption &&
            trimmed.isNotEmpty &&
            !_isExistingLocation(trimmed));

    if (hasContent) {
      _showSuggestions();
      // Refresh overlay contents when typing
      _overlayEntry?.markNeedsBuild();
    } else {
      _selectedLocation = null;
      widget.onLocationObjectSelected?.call(null);
      _removeOverlay();
    }
  }

  void _updateSuggestions(String query) {
    final locationProvider = context.read<LocationProvider>();

    // Get location suggestions
    _suggestions = locationProvider.locations.where((location) {
      final queryLower = query.toLowerCase();
      return location.name.toLowerCase().contains(queryLower) ||
          location.address.toLowerCase().contains(queryLower);
    }).toList();

    // Sort suggestions
    if (widget.showFavoritesFirst) {
      _suggestions.sort((a, b) {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return b.usageCount.compareTo(a.usageCount);
      });
    } else {
      _suggestions.sort((a, b) => b.usageCount.compareTo(a.usageCount));
    }

    // Limit suggestions
    _suggestions = _suggestions.take(8).toList();

    // Get address suggestions from location provider
    _addressSuggestions =
        locationProvider.getAddressSuggestions(query, limit: 3);
  }

  void _showSuggestions() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _isShowingOverlay = true;
    } else {
      // If already showing, just mark it to rebuild with latest suggestions
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isShowingOverlay = false;
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: Offset(0, size.height + 4),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Container(
              width: size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    final hasLocationSuggestions = _suggestions.isNotEmpty;
    final hasAddressSuggestions = _addressSuggestions.isNotEmpty;
    final currentText = _controller.text.trim();

    if (!hasLocationSuggestions &&
        !hasAddressSuggestions &&
        currentText.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        // Saved locations section
        if (hasLocationSuggestions) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'Saved Locations',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ..._suggestions.map((location) => _buildLocationTile(location)),
          if (hasAddressSuggestions ||
              (widget.showSaveOption && currentText.isNotEmpty))
            const Divider(height: 1),
        ],

        // Address suggestions section
        if (hasAddressSuggestions) ...[
          if (hasLocationSuggestions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                'Recent Addresses',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ..._addressSuggestions.map((address) => _buildAddressTile(address)),
          if (widget.showSaveOption && currentText.isNotEmpty)
            const Divider(height: 1),
        ],

        // Save new location option
        if (widget.showSaveOption &&
            currentText.isNotEmpty &&
            !_isExistingLocation(currentText))
          _buildSaveLocationTile(currentText),
      ],
    );
  }

  Widget _buildEmptyState() {
    final locationProvider = context.watch<LocationProvider>();
    final recentLocations =
        locationProvider.getRecentlyAddedLocations(limit: 5);

    if (recentLocations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No saved locations yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Start typing to add a new location',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            'Recent Locations',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...recentLocations.map((location) => _buildLocationTile(location)),
      ],
    );
  }

  Widget _buildLocationTile(Location location) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: location.isFavorite
            ? Colors.amber.withOpacity(0.2)
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(
          location.isFavorite ? Icons.star : Icons.location_on,
          size: 16,
          color: location.isFavorite
              ? Colors.amber[700]
              : Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        location.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        location.address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: location.usageCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${location.usageCount}',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      onTap: () => _selectLocation(location),
    );
  }

  Widget _buildAddressTile(String address) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.withOpacity(0.1),
        child: const Icon(
          Icons.history,
          size: 16,
          color: Colors.grey,
        ),
      ),
      title: Text(
        address,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _selectAddress(address),
    );
  }

  Widget _buildSaveLocationTile(String address) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.green.withOpacity(0.1),
        child: const Icon(
          Icons.add_location,
          size: 16,
          color: Colors.green,
        ),
      ),
      title: Text(
        'Save "$address" as new location',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.green,
        ),
      ),
      onTap: () => _saveNewLocation(address),
    );
  }

  void _selectLocation(Location location) {
    setState(() {
      _selectedLocation = location;
      _controller.text = location.address;
    });

    widget.onLocationSelected(location.address);
    widget.onLocationObjectSelected?.call(location);

    // Increment usage count
    context.read<LocationProvider>().toggleFavorite(location.id);

    _removeOverlay();
    _focusNode.unfocus();
  }

  void _selectAddress(String address) {
    setState(() {
      _controller.text = address;
    });

    widget.onLocationSelected(address);
    widget.onLocationObjectSelected?.call(null);

    _removeOverlay();
    _focusNode.unfocus();
  }

  void _saveNewLocation(String address) async {
    final locationProvider = context.read<LocationProvider>();

    // Show dialog to get location name
    final name = await _showSaveLocationDialog(address);
    if (name != null && name.isNotEmpty) {
      final newLocation = Location(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        address: address,
        createdAt: DateTime.now(),
      );

      await locationProvider.addLocation(newLocation);
      if (mounted) {
        _selectLocation(newLocation);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location "$name" saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<String?> _showSaveLocationDialog(String address) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: $address'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Location Name',
                hintText: 'e.g., Home, Office, Gym',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  bool _isExistingLocation(String address) {
    final locationProvider = context.read<LocationProvider>();
    return locationProvider.locations.any(
      (location) => location.address.toLowerCase() == address.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon:
              widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _selectedLocation = null;
                    widget.onLocationSelected('');
                    widget.onLocationObjectSelected?.call(null);
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        validator: widget.validator,
        onFieldSubmitted: (value) {
          _removeOverlay();
        },
      ),
    );
  }
}
