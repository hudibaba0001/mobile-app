import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location.dart';
import '../providers/location_provider.dart';
import '../utils/constants.dart';
import '../l10n/generated/app_localizations.dart';

class LocationSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String title;

  const LocationSearchScreen({
    super.key,
    this.initialQuery,
    this.title = '',
  });

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _searchQuery = _searchController.text;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title.isEmpty ? t.form_selectLocation : widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: SearchBar(
              controller: _searchController,
              hintText: t.location_searchLocations,
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<LocationProvider>(
        builder: (context, locationProvider, child) {
          if (_searchQuery.isEmpty) {
            return _buildDefaultView(locationProvider);
          }
          return _buildSearchResults(locationProvider);
        },
      ),
    );
  }

  Widget _buildDefaultView(LocationProvider locationProvider) {
    final t = AppLocalizations.of(context);
    final favorites = locationProvider.getFavoriteLocations();
    final recents = locationProvider.getRecentLocations();

    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        if (favorites.isNotEmpty) ...[
          _buildSectionHeader(t.location_favorites),
          _buildLocationList(favorites),
          const SizedBox(height: AppConstants.defaultPadding),
        ],
        if (recents.isNotEmpty) ...[
          _buildSectionHeader(t.location_recent),
          _buildLocationList(recents),
        ],
        if (favorites.isEmpty && recents.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  t.location_noLocationsYet,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  t.location_trySearchOrAdd,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults(LocationProvider locationProvider) {
    final t = AppLocalizations.of(context);
    final results = locationProvider.searchLocations(_searchQuery);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              t.location_noMatchesFound,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              t.location_tryDifferentSearch,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return _buildLocationList(results);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildLocationList(List<Location> locations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                location.isFavorite
                    ? Icons.star_rounded
                    : Icons.location_on_outlined,
                color: location.isFavorite
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            title: Text(location.name),
            subtitle: Text(
              location.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              // Increment usage count and pop with result
              context.read<LocationProvider>().incrementUsageCount(location.id);
              Navigator.of(context).pop(location);
            },
          ),
        );
      },
    );
  }
}
