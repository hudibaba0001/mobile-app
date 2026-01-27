import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/location.dart';
import 'utils/constants.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  LocationsScreenState createState() => LocationsScreenState();
}

class LocationsScreenState extends State<LocationsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  late Box<Location> _locationsBox;

  @override
  void initState() {
    super.initState();
    _locationsBox = Hive.box<Location>(AppConstants.locationsBox);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _addLocation() {
    if (_nameController.text.isNotEmpty && _addressController.text.isNotEmpty) {
      final newLocation = Location(
        id: DateTime.now().toIso8601String(),
        name: _nameController.text,
        address: _addressController.text,
        createdAt: DateTime.now(),
      );
      _locationsBox.add(newLocation);
      _nameController.clear();
      _addressController.clear();
      _showSnackBar('Location added!');
    } else {
      _showSnackBar('Please enter both name and address.');
    }
  }

  void _deleteLocation(int index) {
    _locationsBox.deleteAt(index);
    _showSnackBar('Location deleted!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Locations'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Location Name'),
            ),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addLocation,
              child: const Text('Add Location'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _locationsBox.listenable(),
                builder: (context, Box<Location> box, _) {
                  if (box.values.isEmpty) {
                    return const Center(child: Text('No locations added yet.'));
                  }
                  return ListView.builder(
                    itemCount: box.values.length,
                    itemBuilder: (context, index) {
                      final location = box.getAt(index)!;
                      return ListTile(
                        title: Text(location.name),
                        subtitle: Text(location.address),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteLocation(index),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
