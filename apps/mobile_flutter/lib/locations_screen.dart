import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'design/app_theme.dart';
import 'models/location.dart';
import 'utils/constants.dart';
import 'l10n/generated/app_localizations.dart';

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
    final t = AppLocalizations.of(context);
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
      _showSnackBar(t.location_addedSuccessfully);
    } else {
      _showSnackBar(t.location_enterNameAndAddress);
    }
  }

  void _deleteLocation(int index) {
    final t = AppLocalizations.of(context);
    _locationsBox.deleteAt(index);
    _showSnackBar(t.location_deletedSuccessfully);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.location_manageLocations),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: t.location_name),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: t.location_fullAddress),
            ),
            const SizedBox(height: AppSpacing.md - 2),
            ElevatedButton(
              onPressed: _addLocation,
              child: Text(t.location_addLocation),
            ),
            const SizedBox(height: AppSpacing.lg + AppSpacing.xs),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _locationsBox.listenable(),
                builder: (context, Box<Location> box, _) {
                  if (box.values.isEmpty) {
                    return Center(child: Text(t.location_noSavedYet));
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
