import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../design/app_theme.dart';
import '../models/location.dart';
import '../providers/location_provider.dart';
import '../services/map_service.dart';
import '../l10n/generated/app_localizations.dart';

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
  List<String> _mapboxSuggestions = [];
  Timer? _debounceTimer;
  bool _isLoadingMapboxSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? '';
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    final query = _controller.text;
    widget.onLocationSelected(query);

    // Debounce Mapbox API calls to avoid too many requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadMapboxSuggestions(query);
    });

    _updateSuggestions(query);
    final trimmed = query.trim();
    final hasContent = _suggestions.isNotEmpty ||
        _addressSuggestions.isNotEmpty ||
        _mapboxSuggestions.isNotEmpty ||
        (widget.showSaveOption &&
            trimmed.isNotEmpty &&
            !_isExistingLocation(trimmed));

    if (hasContent) {
      _showSuggestions();
      // Refresh overlay contents when typing
      _overlayEntry?.markNeedsBuild();
    } else {
      widget.onLocationObjectSelected?.call(null);
      _removeOverlay();
    }
  }

  Future<void> _loadMapboxSuggestions(String query) async {
    if (query.trim().isEmpty || query.trim().length < 3) {
      setState(() {
        _mapboxSuggestions = [];
        _isLoadingMapboxSuggestions = false;
      });
      _overlayEntry?.markNeedsBuild();
      return;
    }

    setState(() {
      _isLoadingMapboxSuggestions = true;
    });

    try {
      final suggestions =
          await MapService.getAddressSuggestions(query, limit: 5);
      if (mounted) {
        setState(() {
          _mapboxSuggestions = suggestions;
          _isLoadingMapboxSuggestions = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mapboxSuggestions = [];
          _isLoadingMapboxSuggestions = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
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
    } else {
      // If already showing, just mark it to rebuild with latest suggestions
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
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
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Container(
              width: size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
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
    final t = AppLocalizations.of(context);
    final hasLocationSuggestions = _suggestions.isNotEmpty;
    final hasAddressSuggestions = _addressSuggestions.isNotEmpty;
    final hasMapboxSuggestions = _mapboxSuggestions.isNotEmpty;
    final currentText = _controller.text.trim();

    if (!hasLocationSuggestions &&
        !hasAddressSuggestions &&
        !hasMapboxSuggestions &&
        !_isLoadingMapboxSuggestions &&
        currentText.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        // Saved locations section
        if (hasLocationSuggestions) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Text(
              t.location_savedLocations,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ..._suggestions.map((location) => _buildLocationTile(location)),
          if (hasAddressSuggestions ||
              hasMapboxSuggestions ||
              (widget.showSaveOption && currentText.isNotEmpty))
            const Divider(height: 1),
        ],

        // Mapbox address suggestions section
        if (hasMapboxSuggestions) ...[
          if (hasLocationSuggestions || hasAddressSuggestions)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Text(
                t.location_addressSuggestions,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ..._mapboxSuggestions
              .map((address) => _buildMapboxAddressTile(address)),
          if (hasAddressSuggestions ||
              (widget.showSaveOption && currentText.isNotEmpty))
            const Divider(height: 1),
        ],

        // Loading indicator for Mapbox suggestions
        if (_isLoadingMapboxSuggestions)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  t.location_searchingAddresses,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

        // Address suggestions section (recent addresses)
        if (hasAddressSuggestions) ...[
          if (hasLocationSuggestions || hasMapboxSuggestions)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Text(
                t.location_recentAddresses,
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

  Widget _buildMapboxAddressTile(String address) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(
          Icons.map,
          size: 16,
          color: colorScheme.primary,
        ),
      ),
      title: Text(
        address,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.body(colorScheme.onSurface)
            .copyWith(fontWeight: FontWeight.w500),
      ),
      onTap: () => _selectAddress(address),
    );
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final locationProvider = context.watch<LocationProvider>();
    final recentLocations =
        locationProvider.getRecentlyAddedLocations(limit: 5);

    if (recentLocations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off,
              size: 32,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              t.location_noSavedYet,
              style: AppTypography.body(colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.location_startTypingToAdd,
              style: AppTypography.caption(colorScheme.onSurfaceVariant),
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
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Text(
            t.location_recentLocations,
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
    final colorScheme = Theme.of(context).colorScheme;
    final favoriteColor = AppColors.accent;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: location.isFavorite
            ? favoriteColor.withValues(alpha: 0.2)
            : colorScheme.primary.withValues(alpha: 0.1),
        child: Icon(
          location.isFavorite ? Icons.star : Icons.location_on,
          size: 16,
          color:
              location.isFavorite ? AppColors.accentDark : colorScheme.primary,
        ),
      ),
      title: Text(
        location.name,
        style: AppTypography.body(colorScheme.onSurface)
            .copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        location.address,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption(colorScheme.onSurfaceVariant),
      ),
      trailing: location.usageCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              ),
              child: Text(
                '${location.usageCount}',
                style: AppTypography.caption(colorScheme.primary).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      onTap: () => _selectLocation(location),
    );
  }

  Widget _buildAddressTile(String address) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
        child: Icon(
          Icons.history,
          size: 16,
          color: colorScheme.onSurfaceVariant,
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
    final t = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    const successColor = AppColors.success;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: successColor.withValues(alpha: 0.1),
        child: const Icon(
          Icons.add_location,
          size: 16,
          color: successColor,
        ),
      ),
      title: Text(
        t.location_saveAsNew(address),
        style: AppTypography.body(colorScheme.onSurface).copyWith(
          fontWeight: FontWeight.w500,
          color: successColor,
        ),
      ),
      onTap: () => _saveNewLocation(address),
    );
  }

  void _selectLocation(Location location) {
    setState(() {
      _controller.text = location.address;
    });

    widget.onLocationSelected(location.address);
    widget.onLocationObjectSelected?.call(location);

    // Increment usage count
    context.read<LocationProvider>().incrementUsageCount(location.id);

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
        final t = AppLocalizations.of(context);
        _selectLocation(newLocation);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.location_saved(name)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<String?> _showSaveLocationDialog(String address) async {
    final controller = TextEditingController();

    final t = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.location_saveTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.location_address(address)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: t.location_name,
                hintText: t.location_nameShortHint,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(t.common_save),
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
