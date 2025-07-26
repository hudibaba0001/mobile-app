import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/filter_provider.dart';
import '../utils/constants.dart';
import 'search_bar_widget.dart';
import 'filter_chips.dart';
import 'filter_dialog.dart';

class SearchFilterBar extends StatefulWidget {
  final Function(String query)? onSearch;
  final Function()? onFiltersChanged;
  final String searchHint;
  final bool showFilterChips;
  final bool expandable;
  
  const SearchFilterBar({
    Key? key,
    this.onSearch,
    this.onFiltersChanged,
    this.searchHint = 'Search travel entries...',
    this.showFilterChips = true,
    this.expandable = true,
  }) : super(key: key);

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SearchProvider, FilterProvider>(
      builder: (context, searchProvider, filterProvider, _) {
        final hasActiveFilters = filterProvider.hasActiveFilters;
        final hasSearchQuery = searchProvider.hasQuery;
        
        return Card(
          margin: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main search bar with filter button
                Row(
                  children: [
                    Expanded(
                      child: SearchBarWidget(
                        hintText: widget.searchHint,
                        onSearchChanged: (query) {
                          if (widget.onSearch != null) {
                            widget.onSearch!(query);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    
                    // Filter button
                    Stack(
                      children: [
                        IconButton(
                          onPressed: _showFilterDialog,
                          icon: Icon(
                            Icons.filter_list,
                            color: hasActiveFilters 
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          tooltip: 'Advanced Filters',
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Expand/collapse button for filter chips
                    if (widget.expandable && widget.showFilterChips)
                      IconButton(
                        onPressed: _toggleExpanded,
                        icon: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(Icons.expand_more),
                        ),
                        tooltip: _isExpanded ? 'Hide Filters' : 'Show Filters',
                      ),
                  ],
                ),
                
                // Active search/filter summary
                if (hasSearchQuery || hasActiveFilters) ...[
                  const SizedBox(height: AppConstants.smallPadding),
                  _buildActiveSummary(searchProvider, filterProvider),
                ],
                
                // Filter chips section
                if (widget.showFilterChips) ...[
                  if (widget.expandable) ...[
                    SizeTransition(
                      sizeFactor: _expandAnimation,
                      child: Column(
                        children: [
                          const SizedBox(height: AppConstants.defaultPadding),
                          FilterChips(
                            onFiltersChanged: widget.onFiltersChanged,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: AppConstants.defaultPadding),
                    FilterChips(
                      onFiltersChanged: widget.onFiltersChanged,
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveSummary(SearchProvider searchProvider, FilterProvider filterProvider) {
    final List<String> activeSummary = [];
    
    if (searchProvider.hasQuery) {
      activeSummary.add('Search: "${searchProvider.query}"');
    }
    
    if (filterProvider.hasDateRange) {
      activeSummary.add('Date: ${filterProvider.getDateRangeText()}');
    }
    
    if (filterProvider.hasDurationRange) {
      activeSummary.add('Duration: ${filterProvider.getDurationRangeText()}');
    }
    
    if (filterProvider.selectedLocations.isNotEmpty) {
      final locationCount = filterProvider.selectedLocations.length;
      activeSummary.add('Locations: $locationCount selected');
    }
    
    if (activeSummary.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.smallPadding,
        vertical: 4,
      ),
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
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              activeSummary.join(' • '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _clearAllSearchAndFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Clear All',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const FilterDialog(),
    );
    
    if (result == true && widget.onFiltersChanged != null) {
      widget.onFiltersChanged!();
    }
  }

  void _clearAllSearchAndFilters() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    final filterProvider = Provider.of<FilterProvider>(context, listen: false);
    
    searchProvider.clearQuery();
    filterProvider.clearAllFilters();
    
    if (widget.onSearch != null) {
      widget.onSearch!('');
    }
    if (widget.onFiltersChanged != null) {
      widget.onFiltersChanged!();
    }
  }
}