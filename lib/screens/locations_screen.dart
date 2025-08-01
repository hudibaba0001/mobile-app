import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../providers/search_provider.dart';
import '../providers/filter_provider.dart';
import '../models/location.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _showFab = true;
  bool _showAddForm = false;
  List<Location> _selectedLocations = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Load locations when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationProvider>(context, listen: false).refreshLocations();
    });

    // Hide FAB when scrolling down, show when scrolling up
    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        if (_showFab) setState(() => _showFab = false);
      } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
        if (!_showFab) setState(() => _showFab = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedLocations.length} selected')
            : const Text('Manage Locations'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _selectAll,
                  tooltip: 'Select All',
                ),
                IconButton(
                  icon: const Icon(Icons.star),
                  onPressed: _selectedLocations.isNotEmpty ? _toggleSelectedFavorites : null,
                  tooltip: 'Toggle Favorites',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedLocations.isNotEmpty ? _deleteSelectedLocations : null,
                  tooltip: 'Delete Selected',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddLocationDialog(context),
                  tooltip: 'Add Location',
                ),
                PopupMenuButton<String>(
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'select_mode',
                      child: ListTile(
                        leading: Icon(Icons.checklist),
                        title: Text('Select Multiple'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sort_name',
                      child: ListTile(
                        leading: Icon(Icons.sort_by_alpha),
                        title: Text('Sort by Name'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'sort_usage',
                      child: ListTile(
                        leading: Icon(Icons.trending_up),
                        title: Text('Sort by Usage'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: ListTile(
                        leading: Icon(Icons.refresh),
                        title: Text('Refresh'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Consumer3<LocationProvider, SearchProvider, FilterProvider>(
        builder: (context, locationProvider, searchProvider, filterProvider, _) {
          if (locationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Apply search and filters
          List<Location> locations = locationProvider.locations;
          
          // Apply search
          if (searchProvider.hasQuery) {
            locations = locations.where((location) {
              final query = searchProvider.query.toLowerCase();
              return location.name.toLowerCase().contains(query) ||
                     location.address.toLowerCase().contains(query);
            }).toList();
          }

          // Apply filters
          locations = filterProvider.applyToLocations(locations);

          return Column(
            children: [
              // Add Location Form (collapsible)
              if (_showAddForm) _buildAddLocationForm(locationProvider),
              
              // Search and Filter Bar
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search locations...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (query) {
                    Provider.of<SearchProvider>(context, listen: false).setQuery(query);
                  },
                ),
              ),

              // Statistics Summary
              _buildStatisticsSummary(locationProvider, locations),

              // Results summary
              if (searchProvider.hasQuery || filterProvider.hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
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
                        '${locations.length} ${locations.length == 1 ? 'location' : 'locations'} found',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Locations List
              Expanded(
                child: _buildLocationsList(locations, locationProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _showFab && !_isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: () => _showAddLocationDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Location'),
            )
          : null,
    );
  }

  Widget _buildAddLocationForm(LocationProvider locationProvider) {
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_location,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _showAddForm = false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g., Home, Office, Gym',
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (value) => Validators.validateLocationName(value),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Full address or description',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) => Validators.validateAddress(value),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addLocation(locationProvider),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Location'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  TextButton(
                    onPressed: () {
                      _nameController.clear();
                      _addressController.clear();
                      setState(() => _showAddForm = false);
                    },
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSummary(LocationProvider locationProvider, List<Location> filteredLocations) {
    final totalLocations = locationProvider.locations.length;
    final favoriteLocations = locationProvider.locations.where((loc) => loc.isFavorite).length;
    final totalUsage = locationProvider.locations.fold<int>(0, (sum, loc) => sum + loc.usageCount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Total',
              totalLocations.toString(),
              Icons.location_on,
              Colors.blue,
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: _buildStatCard(
              context,
              'Favorites',
              favoriteLocations.toString(),
              Icons.star,
              Colors.amber,
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: _buildStatCard(
              context,
              'Total Uses',
              totalUsage.toString(),
              Icons.trending_up,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.smallPadding),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationsList(List<Location> locations, LocationProvider locationProvider) {
    if (locations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await locationProvider.refreshLocations();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          final location = locations[index];
          final isSelected = _selectedLocations.contains(location);

          return GestureDetector(
            onLongPress: () => _toggleSelectionMode(location),
            child: Card(
              margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
              elevation: isSelected ? 4 : 1,
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: location.isFavorite 
                      ? Colors.amber 
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: location.isFavorite 
                      ? Colors.black 
                      : Theme.of(context).colorScheme.onPrimary,
                  child: Icon(
                    location.isFavorite ? Icons.star : Icons.location_on,
                  ),
                ),
                title: Text(
                  location.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (location.usageCount > 0) ...[
                          Icon(Icons.trending_up, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${location.usageCount} uses',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(location.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: _isSelectionMode
                    ? Checkbox(
                        value: isSelected,
                        onChanged: (selected) => _toggleLocationSelection(location),
                      )
                    : PopupMenuButton<String>(
                        onSelected: (value) => _handleLocationAction(value, location, locationProvider),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'favorite',
                            child: ListTile(
                              leading: Icon(
                                location.isFavorite ? Icons.star_border : Icons.star,
                                color: Colors.amber,
                              ),
                              title: Text(location.isFavorite ? 'Remove from favorites' : 'Add to favorites'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Delete', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                onTap: _isSelectionMode 
                    ? () => _toggleLocationSelection(location)
                    : () => _showLocationDetails(context, location),
                isThreeLine: true,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final searchProvider = Provider.of<SearchProvider>(context);
    final filterProvider = Provider.of<FilterProvider>(context);
    
    final hasActiveSearchOrFilter = searchProvider.hasQuery || filterProvider.hasActiveFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveSearchOrFilter ? Icons.search_off : Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              hasActiveSearchOrFilter 
                  ? 'No locations found'
                  : 'No locations saved yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              hasActiveSearchOrFilter
                  ? 'Try adjusting your search or filters'
                  : 'Add your first location to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.largePadding),
            if (hasActiveSearchOrFilter)
              ElevatedButton.icon(
                onPressed: () {
                  searchProvider.clearQuery();
                  filterProvider.clearAllFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Search & Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _showAddLocationDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add First Location'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    if (difference < 30) return '${(difference / 7).round()}w ago';
    if (difference < 365) return '${(difference / 30).round()}mo ago';
    return '${(difference / 365).round()}y ago';
  }

  void _handleMenuAction(String action) {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    switch (action) {
      case 'select_mode':
        _enterSelectionMode();
        break;
      case 'sort_name':
        // Sort by name functionality would be implemented here
        break;
      case 'sort_usage':
        // Sort by usage functionality would be implemented here
        break;
      case 'refresh':
        locationProvider.refreshLocations();
        break;
    }
  }

  void _handleLocationAction(String action, Location location, LocationProvider locationProvider) {
    switch (action) {
      case 'favorite':
        locationProvider.toggleFavorite(location.id);
        break;
      case 'edit':
        _showEditLocationDialog(context, location);
        break;
      case 'delete':
        _showDeleteConfirmation(context, location, locationProvider);
        break;
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedLocations.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedLocations.clear();
    });
  }

  void _toggleSelectionMode(Location location) {
    if (!_isSelectionMode) {
      _enterSelectionMode();
      _toggleLocationSelection(location);
    }
  }

  void _toggleLocationSelection(Location location) {
    setState(() {
      if (_selectedLocations.contains(location)) {
        _selectedLocations.remove(location);
      } else {
        _selectedLocations.add(location);
      }
    });
  }

  void _selectAll() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    setState(() {
      _selectedLocations = List.from(locationProvider.locations);
    });
  }

  void _toggleSelectedFavorites() {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    for (final location in _selectedLocations) {
      locationProvider.toggleFavorite(location.id);
    }
    _exitSelectionMode();
  }

  void _deleteSelectedLocations() {
    if (_selectedLocations.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Locations'),
        content: Text(
          'Are you sure you want to delete ${_selectedLocations.length} ${_selectedLocations.length == 1 ? 'location' : 'locations'}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final locationProvider = Provider.of<LocationProvider>(context, listen: false);
              
              int deletedCount = 0;
              for (final location in _selectedLocations) {
                final success = await locationProvider.deleteLocation(location.id);
                if (success) deletedCount++;
              }
              
              _exitSelectionMode();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$deletedCount ${deletedCount == 1 ? 'location' : 'locations'} deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_location,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    hintText: 'e.g., Home, Office, Gym',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) => Validators.validateLocationName(value),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'Full address or description',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                  validator: (value) => Validators.validateAddress(value),
                ),
                const SizedBox(height: AppConstants.largePadding),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _addLocation(Provider.of<LocationProvider>(context, listen: false), closeDialog: true),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Location'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    TextButton(
                      onPressed: () {
                        _nameController.clear();
                        _addressController.clear();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addLocation(LocationProvider locationProvider, {bool closeDialog = false}) async {
    if (_formKey.currentState!.validate()) {
      final location = Location(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
      );
      final success = await locationProvider.addLocation(location);

      if (success) {
        _nameController.clear();
        _addressController.clear();
        setState(() => _showAddForm = false);
        
        if (closeDialog && mounted) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationProvider.lastError?.message ?? 'Failed to add location'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditLocationDialog(BuildContext context, Location location) {
    final nameController = TextEditingController(text: location.name);
    final addressController = TextEditingController(text: location.address);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_location,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) => Validators.validateLocationName(value),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                  validator: (value) => Validators.validateAddress(value),
                ),
                const SizedBox(height: AppConstants.largePadding),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            final locationProvider = Provider.of<LocationProvider>(context, listen: false);
                            final updatedLocation = location.copyWith(
                              name: nameController.text.trim(),
                              address: addressController.text.trim(),
                            );
                            final success = await locationProvider.updateLocation(updatedLocation);

                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Location updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(locationProvider.lastError?.message ?? 'Failed to update location'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationDetails(BuildContext context, Location location) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: location.isFavorite 
                        ? Colors.amber 
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: location.isFavorite 
                        ? Colors.black 
                        : Theme.of(context).colorScheme.onPrimary,
                    child: Icon(
                      location.isFavorite ? Icons.star : Icons.location_on,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      location.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildDetailRow('Address', location.address),
              _buildDetailRow('Usage Count', '${location.usageCount} times'),
              _buildDetailRow('Created', _formatDate(location.createdAt)),
              _buildDetailRow('Favorite', location.isFavorite ? 'Yes' : 'No'),
              const SizedBox(height: AppConstants.largePadding),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditLocationDialog(context, location);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showDeleteConfirmation(context, location, Provider.of<LocationProvider>(context, listen: false));
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[900]),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Location location, LocationProvider locationProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Are you sure you want to delete "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await locationProvider.deleteLocation(location.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Location deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(locationProvider.lastError?.message ?? 'Failed to delete location'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}