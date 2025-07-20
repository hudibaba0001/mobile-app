import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../models/location.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../config/app_router.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late Box<Location> _locationsBox;
  List<Location> _filteredLocations = [];
  List<Location> _allLocations = [];

  @override
  void initState() {
    super.initState();
    _locationsBox = Hive.box<Location>(AppConstants.locationsBox);
    _loadLocations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadLocations() {
    _allLocations = _locationsBox.values.toList()
      ..sort((a, b) {
        // Sort by favorites first, then by usage count, then by name
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        final usageComparison = b.usageCount.compareTo(a.usageCount);
        if (usageComparison != 0) return usageComparison;
        return a.name.compareTo(b.name);
      });
    _filteredLocations = List.from(_allLocations);
  }

  void _filterLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = List.from(_allLocations);
      } else {
        _filteredLocations = _allLocations.where((location) {
          final searchLower = query.toLowerCase();
          return location.name.toLowerCase().contains(searchLower) ||
                 location.address.toLowerCase().contains(searchLower);
        }).toList();
      }
    });
  }

  void _addLocation() {
    if (_nameController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both name and address'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate using our validators
    final nameError = Validators.validateLocationName(_nameController.text.trim());
    final addressError = Validators.validateAddress(_addressController.text.trim());

    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nameError), backgroundColor: Colors.red),
      );
      return;
    }

    if (addressError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(addressError), backgroundColor: Colors.red),
      );
      return;
    }

    final newLocation = Location(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
    );

    _locationsBox.add(newLocation);
    _nameController.clear();
    _addressController.clear();
    _loadLocations();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location added successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteLocation(Location location) {
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
            onPressed: () {
              // Find and delete the location
              for (int i = 0; i < _locationsBox.length; i++) {
                final boxLocation = _locationsBox.getAt(i);
                if (boxLocation?.id == location.id) {
                  _locationsBox.deleteAt(i);
                  break;
                }
              }
              Navigator.of(context).pop();
              _loadLocations();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(Location location) {
    final updatedLocation = location.toggleFavorite();
    
    // Find and update the location
    for (int i = 0; i < _locationsBox.length; i++) {
      final boxLocation = _locationsBox.getAt(i);
      if (boxLocation?.id == location.id) {
        _locationsBox.putAt(i, updatedLocation);
        break;
      }
    }
    
    _loadLocations();
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(updatedLocation.isFavorite 
            ? 'Added to favorites' 
            : 'Removed from favorites'),
        backgroundColor: updatedLocation.isFavorite ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouter.home),
        ),
      ),
      body: Column(
        children: [
          // Add Location Form
          Card(
            margin: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Location Name',
                      hintText: 'e.g., Home, Office, Gym',
                      prefixIcon: Icon(Icons.label),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Full address or description',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addLocation,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Location'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search locations',
                hintText: 'Search by name or address...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterLocations,
            ),
          ),

          const SizedBox(height: AppConstants.defaultPadding),

          // Locations List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _locationsBox.listenable(),
              builder: (context, Box<Location> box, _) {
                _loadLocations();
                _filterLocations(_searchController.text);

                if (_filteredLocations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isEmpty ? Icons.location_off : Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No locations saved yet'
                              : 'No locations match your search',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Add your first location above!'
                              : 'Try a different search term',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                  itemCount: _filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = _filteredLocations[index];
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
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
                            Text(location.address),
                            if (location.usageCount > 0)
                              Text(
                                'Used ${location.usageCount} time${location.usageCount == 1 ? '' : 's'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'favorite':
                                _toggleFavorite(location);
                                break;
                              case 'delete':
                                _deleteLocation(location);
                                break;
                            }
                          },
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
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete, color: Colors.red),
                                title: Text('Delete', style: TextStyle(color: Colors.red)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: location.usageCount > 0,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}