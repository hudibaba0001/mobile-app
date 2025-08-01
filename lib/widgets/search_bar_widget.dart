import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final Function(String)? onSearchChanged;
  final Function(String)? onSearchSubmitted;
  final bool showSuggestions;
  final bool showHistory;
  final SearchType searchType;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Search...',
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.showSuggestions = true,
    this.showHistory = true,
    this.searchType = SearchType.all,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  bool _isShowingOverlay = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
    
    // Initialize with current search query
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final searchProvider = context.read<SearchProvider>();
      _controller.text = searchProvider.query;
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && widget.showSuggestions) {
      _showSuggestions();
    } else {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _onTextChanged() {
    final query = _controller.text;
    final searchProvider = context.read<SearchProvider>();
    
    searchProvider.setQuery(query);
    searchProvider.setSearchType(widget.searchType);
    
    widget.onSearchChanged?.call(query);
    
    if (widget.showSuggestions && _focusNode.hasFocus) {
      _showSuggestions();
    }
  }

  void _showSuggestions() {
    if (_isShowingOverlay) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _isShowingOverlay = true;
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
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4,
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
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
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        final suggestions = searchProvider.suggestions;
        final recentSearches = widget.showHistory 
            ? searchProvider.getRecentSearches(limit: 5)
            : <String>[];
        
        final hasContent = suggestions.isNotEmpty || recentSearches.isNotEmpty;
        
        if (!hasContent) {
          return _buildEmptyState();
        }

        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            // Suggestions
            if (suggestions.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...suggestions.map((suggestion) => _buildSuggestionTile(
                suggestion,
                Icons.search,
                () => _selectSuggestion(suggestion),
              )),
              if (recentSearches.isNotEmpty) const Divider(height: 1),
            ],

            // Recent searches
            if (recentSearches.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Recent Searches',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        searchProvider.clearHistory();
                        _removeOverlay();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...recentSearches.map((search) => _buildSuggestionTile(
                search,
                Icons.history,
                () => _selectSuggestion(search),
                onRemove: () => searchProvider.removeFromHistory(search),
              )),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Start typing to search',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(
    String text,
    IconData icon,
    VoidCallback onTap, {
    VoidCallback? onRemove,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: Colors.grey[600]),
      title: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onRemove != null
          ? IconButton(
              icon: Icon(Icons.close, size: 16, color: Colors.grey[500]),
              onPressed: onRemove,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            )
          : null,
      onTap: onTap,
    );
  }

  void _selectSuggestion(String suggestion) {
    _controller.text = suggestion;
    _focusNode.unfocus();
    _removeOverlay();
    widget.onSearchSubmitted?.call(suggestion);
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.unfocus();
    _removeOverlay();
    context.read<SearchProvider>().clearQuery();
    widget.onSearchChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          return TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: searchProvider.isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onSubmitted: (value) {
              _removeOverlay();
              widget.onSearchSubmitted?.call(value);
            },
          );
        },
      ),
    );
  }
}